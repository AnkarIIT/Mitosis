import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/database/drift_database.dart' as db;
import 'package:neet_mitos/core/database/question_repository.dart';

/// Covers the OTP brute-force surface.
///
/// `twoFactorAttempts` / `twoFactorLockedUntil` / `twoFactorLastSentAt` were
/// declared as columns but never read or written by any query, so 2FA code
/// verification was an unlimited oracle. Password-reset codes were worse: they
/// had no throttling columns at all. A 6-digit code is 10^6 candidates and the
/// hash lives in a local SQLite file, so both paths need a bounded guess budget,
/// a lockout, and a resend cooldown.
void main() {
  late AppDatabase database;
  late int userId;

  Future<int> createUser({String email = 'otp@test.dev'}) async {
    userId = await database
        .into(database.users)
        .insert(
          db.UsersCompanion.insert(
            username: 'otp_user',
            email: drift.Value(email),
            // r'...' so Dart does not read the $ as interpolation.
            passwordHash: const drift.Value(r'pbkdf2-sha256$1$aaaa$bbbb'),
          ),
        );
    return userId;
  }

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('2FA code guess budget', () {
    test('accepts the correct code', () async {
      await createUser();
      await database.setTwoFactorCode(
        userId,
        '123456',
        DateTime.now().add(const Duration(minutes: 15)),
      );

      final outcome = await database.verifyTwoFactorCode(userId, '123456');
      expect(outcome, db.OtpAttemptOutcome.verified);
    });

    test(
      'reports a wrong code without locking on the first few misses',
      () async {
        await createUser();
        await database.setTwoFactorCode(
          userId,
          '123456',
          DateTime.now().add(const Duration(minutes: 15)),
        );

        for (var i = 0; i < 4; i++) {
          final outcome = await database.verifyTwoFactorCode(userId, '000000');
          expect(outcome, db.OtpAttemptOutcome.wrongCode);
          expect(await database.isTwoFactorLockedOut(userId), isFalse);
        }
      },
    );

    test('locks out once the guess budget is exhausted', () async {
      await createUser();
      await database.setTwoFactorCode(
        userId,
        '123456',
        DateTime.now().add(const Duration(minutes: 15)),
      );

      // Exhaust the budget with wrong guesses.
      for (var i = 0; i < 5; i++) {
        await database.verifyTwoFactorCode(userId, '000000');
      }
      expect(await database.isTwoFactorLockedOut(userId), isTrue);

      // The correct code is now rejected while locked out — this is the whole
      // point: without the lock, 10^6 guesses would find it.
      final outcome = await database.verifyTwoFactorCode(userId, '123456');
      expect(outcome, db.OtpAttemptOutcome.lockedOut);
    });

    test('a fresh code resets the guess budget', () async {
      await createUser();
      await database.setTwoFactorCode(
        userId,
        '111111',
        DateTime.now().add(const Duration(minutes: 15)),
      );
      // Burn three attempts.
      for (var i = 0; i < 3; i++) {
        await database.verifyTwoFactorCode(userId, '999999');
      }

      // Issuing a new code must restore the full budget, otherwise a user who
      // fat-fingers a few codes would be permanently locked out.
      await database.setTwoFactorCode(
        userId,
        '222222',
        DateTime.now().add(const Duration(minutes: 15)),
      );

      for (var i = 0; i < 4; i++) {
        expect(
          await database.verifyTwoFactorCode(userId, '999999'),
          db.OtpAttemptOutcome.wrongCode,
        );
      }
      expect(await database.isTwoFactorLockedOut(userId), isFalse);
      expect(
        await database.verifyTwoFactorCode(userId, '222222'),
        db.OtpAttemptOutcome.verified,
      );
    });

    test('an expired code is not verifiable', () async {
      await createUser();
      await database.setTwoFactorCode(
        userId,
        '123456',
        DateTime.now().subtract(const Duration(minutes: 1)),
      );

      expect(
        await database.verifyTwoFactorCode(userId, '123456'),
        db.OtpAttemptOutcome.noActiveCode,
      );
    });

    test('no active code yields noActiveCode', () async {
      await createUser();
      expect(
        await database.verifyTwoFactorCode(userId, '123456'),
        db.OtpAttemptOutcome.noActiveCode,
      );
    });

    test('clearing the code also clears the throttle state', () async {
      await createUser();
      await database.setTwoFactorCode(
        userId,
        '123456',
        DateTime.now().add(const Duration(minutes: 15)),
      );
      for (var i = 0; i < 5; i++) {
        await database.verifyTwoFactorCode(userId, '000000');
      }
      expect(await database.isTwoFactorLockedOut(userId), isTrue);

      await database.clearTwoFactorCode(userId);

      expect(await database.isTwoFactorLockedOut(userId), isFalse);
    });
  });

  group('2FA resend cooldown', () {
    test('is throttled immediately after a send', () async {
      await createUser();
      expect(await database.isTwoFactorResendThrottled(userId), isFalse);

      await database.markTwoFactorSent(userId);

      expect(
        await database.isTwoFactorResendThrottled(
          userId,
          cooldown: const Duration(seconds: 60),
        ),
        isTrue,
      );
    });

    test('allows a resend once the cooldown has elapsed', () async {
      await createUser();
      await database.markTwoFactorSent(
        userId,
        at: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(
        await database.isTwoFactorResendThrottled(
          userId,
          cooldown: const Duration(seconds: 60),
        ),
        isFalse,
      );
    });
  });

  group('Password-reset code guess budget', () {
    test('accepts the correct code', () async {
      await createUser();
      await database.updateUserPasswordReset(
        userId,
        '654321',
        DateTime.now().add(const Duration(minutes: 15)),
      );

      expect(
        await database.verifyPasswordResetCode(userId, '654321'),
        db.OtpAttemptOutcome.verified,
      );
    });

    test('locks out after the budget is exhausted', () async {
      await createUser();
      await database.updateUserPasswordReset(
        userId,
        '654321',
        DateTime.now().add(const Duration(minutes: 15)),
      );

      for (var i = 0; i < 5; i++) {
        await database.verifyPasswordResetCode(userId, '000000');
      }
      expect(await database.isPasswordResetLockedOut(userId), isTrue);
      expect(
        await database.verifyPasswordResetCode(userId, '654321'),
        db.OtpAttemptOutcome.lockedOut,
      );
    });

    test('the 2FA budget does not leak into password resets', () async {
      // Separate budgets: burning the 2FA guesses must not lock reset codes.
      await createUser();
      await database.setTwoFactorCode(
        userId,
        '111111',
        DateTime.now().add(const Duration(minutes: 15)),
      );
      await database.updateUserPasswordReset(
        userId,
        '222222',
        DateTime.now().add(const Duration(minutes: 15)),
      );

      for (var i = 0; i < 5; i++) {
        await database.verifyTwoFactorCode(userId, '000000');
      }
      expect(await database.isTwoFactorLockedOut(userId), isTrue);

      expect(await database.isPasswordResetLockedOut(userId), isFalse);
      expect(
        await database.verifyPasswordResetCode(userId, '222222'),
        db.OtpAttemptOutcome.verified,
      );
    });

    test('a fresh reset code resets the guess budget', () async {
      await createUser();
      await database.updateUserPasswordReset(
        userId,
        '111111',
        DateTime.now().add(const Duration(minutes: 15)),
      );
      for (var i = 0; i < 4; i++) {
        await database.verifyPasswordResetCode(userId, '000000');
      }

      await database.updateUserPasswordReset(
        userId,
        '333333',
        DateTime.now().add(const Duration(minutes: 15)),
      );

      expect(await database.isPasswordResetLockedOut(userId), isFalse);
      expect(
        await database.verifyPasswordResetCode(userId, '333333'),
        db.OtpAttemptOutcome.verified,
      );
    });

    test('an expired reset code is not verifiable', () async {
      await createUser();
      await database.updateUserPasswordReset(
        userId,
        '654321',
        DateTime.now().subtract(const Duration(minutes: 1)),
      );

      expect(
        await database.verifyPasswordResetCode(userId, '654321'),
        db.OtpAttemptOutcome.noActiveCode,
      );
    });
  });

  group('Password-reset resend cooldown', () {
    test('is throttled immediately after a send', () async {
      await createUser();
      await database.markPasswordResetSent(userId);

      expect(
        await database.isPasswordResetResendThrottled(
          userId,
          cooldown: const Duration(seconds: 60),
        ),
        isTrue,
      );
    });

    test('allows a resend once the cooldown has elapsed', () async {
      await createUser();
      await database.markPasswordResetSent(
        userId,
        at: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(
        await database.isPasswordResetResendThrottled(
          userId,
          cooldown: const Duration(seconds: 60),
        ),
        isFalse,
      );
    });
  });

  group('Account data deletion', () {
    test('clearAllUserData removes the user-owned rows', () async {
      await createUser();
      await database
          .into(database.questions)
          .insert(
            db.QuestionsCompanion.insert(
              id: 'q1',
              subject: 'Physics',
              chapter: 'Ch',
              topic: 'T',
              topicId: drift.Value('t1'),
              questionText: 'Q?',
              options: 'A|||B',
              correctAnswer: 'A',
              difficulty: drift.Value('Easy'),
              tags: drift.Value(''),
              type: drift.Value('mcq'),
            ),
          );
      await database
          .into(database.bookmarks)
          .insert(
            db.BookmarksCompanion.insert(
              userId: userId,
              questionId: 'q1',
              subject: 'Physics',
              topicId: 't1',
              bookmarkedAt: DateTime.now(),
            ),
          );

      await database.clearAllUserData(userId);

      expect(
        await (database.select(
          database.bookmarks,
        )..where((t) => t.userId.equals(userId))).get(),
        isEmpty,
      );
      expect(await database.getUserById(userId), isNull);
      // The shared question catalog is not user-owned and must survive.
      expect(
        await QuestionRepository(database).getQuestionById('q1'),
        isNotNull,
      );
    });
  });
}
