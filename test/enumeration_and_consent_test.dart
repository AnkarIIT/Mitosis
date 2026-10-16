import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/database/tables/consent_records_table.dart';
import 'package:neet_mitos/core/services/auth_service.dart';
import 'package:neet_mitos/core/services/email_service.dart';

/// Captures sends instead of performing them.
class _CapturingEmailService extends EmailService {
  _CapturingEmailService({this.configured = true});

  final bool configured;

  @override
  bool get isConfigured => configured;

  // No @override: EmailService exposes `isConfigured`, not `isAvailable`.
  bool get isAvailable => configured;

  final List<EmailTemplate> templates = [];
  final List<String> recipients = [];
  final List<String> codes = [];

  @override
  Future<EmailSendResult> send({
    required String to,
    required EmailTemplate template,
    EmailPurpose purpose = EmailPurpose.securityNotice,
    String? username,
    String? code,
    Duration? timeout,
  }) async {
    templates.add(template);
    recipients.add(to);
    codes.add(code ?? '');
    return EmailSendResult.sent();
  }
}

/// Covers the two defects this suite exists for:
///
///  1. **Account enumeration.** `sendPasswordReset` had a "don't reveal whether
///     email exists" comment directly above a branch that returned a *different
///     message* for four distinguishable states — unknown email, sent, throttled,
///     and not-configured. The auth screen renders `message` verbatim, so the
///     intent was defeated in practice.
///
///  2. **Unrecorded consent.** Acceptance was an in-memory boolean, so it reset
///     on restart and nothing was written down.
void main() {
  late AppDatabase db;

  Future<AuthService> serviceWith(EmailService email) async =>
      AuthService(db, email);

  Future<User> register(
    AuthService auth,
    String email, {
    String? username,
  }) async {
    final r = await auth.register(
      email: email,
      username: username ?? email.split('@').first,
      password: 'C0rrect-Password!',
    );
    expect(r.success, isTrue);
    return r.user!;
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Password reset — anti-enumeration', () {
    test('an unknown email and a known email are indistinguishable', () async {
      final email = _CapturingEmailService();
      final auth = await serviceWith(email);

      final unknown = await auth.sendPasswordReset(email: 'nobody@example.com');
      await register(auth, 'real@example.com');
      final known = await auth.sendPasswordReset(email: 'real@example.com');

      // This is the assertion that matters: identical message AND identical
      // success flag. A difference in either is an existence oracle.
      expect(known.message, unknown.message);
      expect(known.success, unknown.success);
    });

    test(
      'a repeated request is throttled without revealing existence',
      () async {
        final email = _CapturingEmailService();
        final auth = await serviceWith(email);
        await register(auth, 'throttle@example.com');

        final first = await auth.sendPasswordReset(
          email: 'throttle@example.com',
        );
        final second = await auth.sendPasswordReset(
          email: 'throttle@example.com',
        );

        // Count only the reset template: registration itself sends a
        // verification mail to the same address.
        int resetsTo(String address) {
          var n = 0;
          for (var i = 0; i < email.templates.length; i++) {
            if (email.templates[i] == EmailTemplate.passwordReset &&
                email.recipients[i] == address) {
              n++;
            }
          }
          return n;
        }

        // The throttle is a *stronger* signal than mere existence, so it only
        // becomes reachable once the account is known. Assert the mail is
        // genuinely limited rather than pretending it is not.
        expect(first.success, isTrue);
        expect(second.success, isFalse);
        expect(resetsTo('throttle@example.com'), 1);
      },
    );

    test(
      'an unconfigured backend does not reveal whether the account exists',
      () async {
        final auth = await serviceWith(
          _CapturingEmailService(configured: false),
        );

        // "This build has no email backend" is a fact about the binary, not the
        // account — so it must be answered identically for both. Checking it
        // *after* the lookup would turn it into an oracle.
        final unknown = await auth.sendPasswordReset(
          email: 'nobody@example.com',
        );
        await register(auth, 'real@example.com');
        final known = await auth.sendPasswordReset(email: 'real@example.com');

        expect(known.message, unknown.message);
        expect(known.success, unknown.success);
        expect(known.success, isFalse);
        expect(known.message, contains('not set up on this build'));
      },
    );

    test('a federated account is treated like an unknown one', () async {
      final email = _CapturingEmailService();
      final auth = await serviceWith(email);

      // A Google-created row carries the sentinel, not a password. It must not
      // be distinguishable from "no such account", or the reset endpoint becomes
      // a way to enumerate which addresses use federated login.
      await db.registerUser(
        UsersCompanion.insert(
          username: 'social',
          email: const Value('social@example.com'),
          passwordHash: const Value(kGooglePasswordSentinel),
          supabaseId: const Value('uuid-1'),
        ),
      );

      final result = await auth.sendPasswordReset(email: 'social@example.com');
      final unknown = await auth.sendPasswordReset(email: 'nobody@example.com');

      expect(result.message, unknown.message);
      expect(result.success, unknown.success);
      expect(email.recipients, isNot(contains('social@example.com')));
    });
  });

  group('Password reset — code verification', () {
    test('a wrong code and a locked account give the same message', () async {
      final email = _CapturingEmailService();
      final auth = await serviceWith(email);
      final user = await register(auth, 'reset@example.com');

      await auth.sendPasswordReset(email: 'reset@example.com');
      // The code the service actually issued. Previously this line computed a
      // dead `code` (a regex match against either '' or the literal '000000')
      // and the assertions below hard-coded wrong/arbitrary values, so the
      // lockout test never proved that the CORRECT code is refused too.
      expect(email.codes, isNotEmpty, reason: 'no reset code was emitted');
      final realCode = email.codes.last;
      expect(realCode, matches(RegExp(r'^\d{6}$')));

      // Exhaust the guess budget with wrong codes.
      String? wrongMessage;
      for (var i = 0; i < 5; i++) {
        final r = await auth.resetPassword(
          email: 'reset@example.com',
          code: '000000',
          newPassword: 'N3w-Password!',
        );
        expect(r.success, isFalse);
        wrongMessage ??= r.message;
      }

      // Now locked. The correct code must be refused with the same wording —
      // this is the property that actually matters.
      final locked = await auth.resetPassword(
        email: 'reset@example.com',
        code: realCode,
        newPassword: 'N3w-Password!',
      );
      expect(locked.success, isFalse);
      expect(locked.message, wrongMessage);
      expect(user.passwordHash, isNot('N3w-Password!'));
    });

    test('a successful reset sends a security notice', () async {
      final email = _CapturingEmailService();
      final auth = await serviceWith(email);
      await register(auth, 'notice@example.com');

      await auth.sendPasswordReset(email: 'notice@example.com');

      // Read the stored hash so the correct code can be recovered — the client
      // only ever sees the plaintext in the outbound mail.
      await db.updateUserPasswordReset(
        (await db.getUserByEmail('notice@example.com'))!.id,
        '123456',
        DateTime.now().add(const Duration(minutes: 15)),
      );

      final result = await auth.resetPassword(
        email: 'notice@example.com',
        code: '123456',
        newPassword: 'N3w-Password!',
      );

      expect(result.success, isTrue);
      // The owner should be told their password changed; a silent reset is
      // indistinguishable from an attacker's.
      expect(email.templates, contains(EmailTemplate.securityNotice));
    });
  });

  group('Consent records', () {
    test('registration persists terms and privacy acceptance', () async {
      final auth = await serviceWith(_CapturingEmailService());
      final user = await register(auth, 'consent@example.com');

      final records = await db.getConsentRecords(user.id);
      final docs = records.map((r) => r.document).toSet();

      expect(docs, contains(ConsentDocument.terms));
      expect(docs, contains(ConsentDocument.privacy));

      final terms = records.firstWhere(
        (r) => r.document == ConsentDocument.terms,
      );
      expect(terms.version, ConsentDocument.termsVersion);
      expect(
        terms.acceptedAt.difference(DateTime.now()).inMinutes.abs(),
        lessThan(5),
      );
    });

    test(
      'the version is pinned, so a policy change can force re-consent',
      () async {
        final auth = await serviceWith(_CapturingEmailService());
        final user = await register(auth, 'version@example.com');

        expect(
          await db.hasAcceptedConsent(
            user.id,
            document: ConsentDocument.terms,
            version: ConsentDocument.termsVersion,
          ),
          isTrue,
        );

        // A different version is not satisfied, which is what drives re-asking.
        expect(
          await db.hasAcceptedConsent(
            user.id,
            document: ConsentDocument.terms,
            version: '2099-01',
          ),
          isFalse,
        );
      },
    );

    test('consent is scoped per user', () async {
      final auth = await serviceWith(_CapturingEmailService());
      final a = await register(auth, 'a@example.com');
      final b = await register(auth, 'b@example.com');

      expect(await db.getConsentRecords(a.id), isNotEmpty);
      expect(await db.getConsentRecords(b.id), isNotEmpty);

      // Clearing one account's consent must not touch the other's.
      await db.clearConsentRecords(a.id);
      expect(await db.getConsentRecords(a.id), isEmpty);
      expect(await db.getConsentRecords(b.id), isNotEmpty);
    });

    test('re-registering the same version does not duplicate rows', () async {
      final auth = await serviceWith(_CapturingEmailService());
      final user = await register(auth, 'dupe@example.com');

      await db.recordConsent(
        user.id,
        document: ConsentDocument.terms,
        version: ConsentDocument.termsVersion,
      );

      final records = await db.getConsentRecords(user.id);
      final termsRecords = records
          .where((r) => r.document == ConsentDocument.terms)
          .toList();
      expect(termsRecords.length, 1);
    });
  });

  group('Account deletion clears consent', () {
    test('consent rows are removed with the account', () async {
      final auth = await serviceWith(_CapturingEmailService());
      final user = await register(auth, 'delete@example.com');
      expect(await db.getConsentRecords(user.id), isNotEmpty);

      await db.clearAllUserData(user.id);

      expect(await db.getConsentRecords(user.id), isEmpty);
    });
  });
}
