import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/services/auth_service.dart';
import 'package:neet_mitos/core/services/email_service.dart';

class _CapturingEmailService extends EmailService {
  @override
  bool get isConfigured => true;

  final List<String> sentTexts = [];
  final List<String> sentHtmls = [];
  final List<String> recipients = [];

  @override
  Future<EmailSendResult> sendTransactionalEmail({
    required String to,
    required String subject,
    required String html,
    String? text,
    String? from,
  }) async {
    recipients.add(to);
    sentHtmls.add(html);
    sentTexts.add(text ?? '');
    return EmailSendResult.ok('sent');
  }
}

void main() {
  group('Two-factor authentication (email OTP)', () {
    late AppDatabase db;
    late AuthService auth;
    late _CapturingEmailService email;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      email = _CapturingEmailService();
      auth = AuthService(db, email);
    });

    tearDown(() async {
      await db.close();
    });

    Future<User> registerUser(String email) async {
      final result = await auth.register(
        email: email,
        username: email.split('@').first,
        password: 'c0rrect-password',
      );
      expect(result.success, isTrue);
      return result.user!;
    }

    test('enable2FA falls back when no email service is configured', () async {
      final noEmail = AuthService(db);
      final user = await registerUser('noconfig@example.com');

      final result = await noEmail.enable2FA(user.email!);

      expect(result.success, isFalse);
      expect(result.message, contains('not configured'));
      expect(await db.getActiveTwoFactorCode(user.id), isNull);
    });

    test('enable flow stores the code and confirm enables 2FA', () async {
      final user = await registerUser('enable@example.com');
      expect(user.isTwoFactorEnabled, isFalse);

      final enable = await auth.enable2FA(user.email!);
      expect(enable.success, isTrue);
      expect(enable.message, contains('enable@example.com'));
      expect(email.recipients, contains('enable@example.com'));

      final stored = await db.getActiveTwoFactorCode(user.id);
      expect(stored, isNotNull);
      expect(stored!.code.length, 6);
      expect(stored.code, allOf(isNot(contains(' ')), isNot(contains('.'))));

      expect(email.sentTexts.single, contains(stored.code));
      expect(email.sentHtmls.single, contains(stored.code));
      expect(email.sentHtmls.single, contains('Hi enable,'));
      expect(email.sentHtmls.single, contains('Hi ${user.username},'));
      expect(
        email.sentHtmls.single,
        contains('Enable two-factor authentication'),
      );

      final wrong = await auth.confirmEnable2FA('enable@example.com', '999999');
      expect(wrong.success, isFalse);
      expect(user.isTwoFactorEnabled, isFalse);

      final good = await auth.confirmEnable2FA(
        'enable@example.com',
        stored.code,
      );
      expect(good.success, isTrue);

      final updated = await db.getUserById(user.id);
      expect(updated!.isTwoFactorEnabled, isTrue);
      expect(await db.getActiveTwoFactorCode(user.id), isNull);
    });

    test('getActiveTwoFactorCode returns null once code has expired', () async {
      final user = await registerUser('expired@example.com');
      await auth.enable2FA(user.email!);

      await db.setTwoFactorCode(
        user.id,
        '123456',
        DateTime.now().subtract(const Duration(minutes: 1)),
      );

      expect(await db.getActiveTwoFactorCode(user.id), isNull);
      final confirm = await auth.confirmEnable2FA(
        'expired@example.com',
        '123456',
      );
      expect(confirm.success, isFalse);
    });

    test('login for a 2FA user verifies via OTP', () async {
      final user = await registerUser('login@example.com');
      await auth.enable2FA(user.email!);
      final stored = await db.getActiveTwoFactorCode(
        (await db.getUserByEmail('login@example.com'))!.id,
      );
      final confirmed = await auth.confirmEnable2FA(
        'login@example.com',
        stored!.code,
      );
      expect(confirmed.success, isTrue);

      final login = await auth.login(
        email: 'login@example.com',
        password: 'c0rrect-password',
      );
      expect(login.success, isTrue);

      final sent = await auth.sendLogin2FAEmail(login.user!.id);
      expect(sent.success, isTrue);
      final loginCode = (await db.getActiveTwoFactorCode(login.user!.id))!.code;
      expect(email.sentTexts.last, contains(loginCode));
      expect(email.sentHtmls.last, contains(loginCode));
      expect(email.sentHtmls.last, contains('Login verification'));

      final bad = await auth.verifyLogin2FA(login.user!.id, '000000');
      expect(bad.success, isFalse);

      final good = await auth.verifyLogin2FA(login.user!.id, loginCode);
      expect(good.success, isTrue);
      expect(good.user!.isTwoFactorEnabled, isTrue);
      expect(await db.getActiveTwoFactorCode(login.user!.id), isNull);
    });

    test('disable2FA clears the flag and any pending code', () async {
      final user = await registerUser('disable@example.com');
      await auth.enable2FA(user.email!);
      final stored = await db.getActiveTwoFactorCode(user.id);
      await auth.confirmEnable2FA('disable@example.com', stored!.code);

      final result = await auth.disable2FA(user.id);
      expect(result.success, isTrue);

      final updated = await db.getUserById(user.id);
      expect(updated!.isTwoFactorEnabled, isFalse);
      expect(await db.getActiveTwoFactorCode(user.id), isNull);
    });
  });
}
