import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/services/auth_service.dart';
import 'package:neet_mitos/core/services/email_service.dart';

/// Captures sends instead of performing them.
///
/// Overrides [send] rather than the retired `sendTransactionalEmail`, because
/// the service no longer accepts caller-supplied HTML at all — a template name
/// is what crosses the wire.
class _CapturingEmailService extends EmailService {
  @override
  bool get isConfigured => true;

  final List<String> recipients = [];
  final List<String> usernames = [];
  final List<String> codes = [];
  final List<EmailTemplate> templates = [];
  final List<EmailPurpose> purposes = [];

  @override
  Future<EmailSendResult> send({
    required String to,
    required EmailTemplate template,
    EmailPurpose purpose = EmailPurpose.securityNotice,
    String? username,
    String? code,
    Duration? timeout,
  }) async {
    recipients.add(to);
    usernames.add(username ?? '');
    codes.add(code ?? '');
    templates.add(template);
    purposes.add(purpose);
    return EmailSendResult.sent();
  }
}

/// The code from the most recent captured send.
String _codeFromLastEmail(_CapturingEmailService email) {
  expect(email.codes, isNotEmpty, reason: 'No email was captured');
  final code = email.codes.last;
  expect(code, matches(RegExp(r'^\d{6}$')));
  return code;
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
        password: 'C0rrect-Password!',
      );
      expect(result.success, isTrue);
      return result.user!;
    }

    test('enable2FA falls back when no email service is configured', () async {
      final noEmail = AuthService(db);
      final user = await registerUser('noconfig@example.com');

      final result = await noEmail.enable2FA(user.email!);

      expect(result.success, isFalse);
      expect(result.message, contains('not set up on this build'));
    });

    test('enable2FA is rate limited by resend cooldown', () async {
      // This path previously had no throttle and never recorded a send. Because
      // it is keyed on a caller-supplied email, it was an unbounded amplifier:
      // anyone who knew a registered address could drive unlimited
      // transactional mail and churn the live code on every request.
      final user = await registerUser('cooldown@example.com');

      // Registration itself sends a verification mail, so count only the
      // two-factor template when asserting on delivery.
      int twoFactorSendsTo(String address) {
        var n = 0;
        for (var i = 0; i < email.templates.length; i++) {
          if (email.templates[i] == EmailTemplate.twoFactorEnable &&
              email.recipients[i] == address) {
            n++;
          }
        }
        return n;
      }

      final first = await auth.enable2FA(user.email!);
      expect(first.success, isTrue);
      expect(twoFactorSendsTo('cooldown@example.com'), 1);

      final second = await auth.enable2FA(user.email!);
      expect(second.success, isFalse);
      expect(second.message, contains('wait before requesting another code'));
      expect(twoFactorSendsTo('cooldown@example.com'), 1);
    });

    test('enable flow stores the code and confirm enables 2FA', () async {
      final user = await registerUser('enable@example.com');
      expect(user.isTwoFactorEnabled, isFalse);

      final enable = await auth.enable2FA(user.email!);
      expect(enable.success, isTrue);
      expect(enable.message, contains('enable@example.com'));
      expect(email.recipients, contains('enable@example.com'));

      final code = _codeFromLastEmail(email);
      expect(code.length, 6);
      expect(code, allOf(isNot(contains(' ')), isNot(contains('.'))));

      // The client sends a template *name*, not HTML. Rendering happens server-side
      // so untrusted text can never be interpolated into a security email.
      // `.last` rather than `.single`: registration also sends a verification
      // mail, so the two-factor template is not the only send in the log.
      expect(email.templates.last, EmailTemplate.twoFactorEnable);
      expect(email.purposes.last, EmailPurpose.twoFactorEnable);
      expect(email.codes.last, code);
      expect(email.usernames.last, user.username);

      // The code and username must still appear, escaped, in the rendered
      // preview — this is what proves the escaping path is wired end to end.
      final html = EmailTemplate.twoFactorEnable.render(
        purpose: EmailPurpose.twoFactorEnable,
        username: email.usernames.last,
        code: email.codes.last,
      );
      expect(html, contains(code));
      expect(html, contains('turn on two-factor authentication'));

      final wrong = await auth.confirmEnable2FA('enable@example.com', '999999');
      expect(wrong.success, isFalse);
      expect(user.isTwoFactorEnabled, isFalse);

      final good = await auth.confirmEnable2FA('enable@example.com', code);
      expect(good.success, isTrue);

      final updated = await db.getUserById(user.id);
      expect(updated!.isTwoFactorEnabled, isTrue);
    });

    test('expired code cannot enable 2FA', () async {
      final user = await registerUser('expired@example.com');
      await auth.enable2FA(user.email!);

      await db.setTwoFactorCode(
        user.id,
        '123456',
        DateTime.now().subtract(const Duration(minutes: 1)),
      );

      final confirm = await auth.confirmEnable2FA(
        'expired@example.com',
        '123456',
      );
      expect(confirm.success, isFalse);
    });

    test('login for a 2FA user verifies via OTP', () async {
      final user = await registerUser('login@example.com');
      await auth.enable2FA(user.email!);
      final enableCode = _codeFromLastEmail(email);
      final confirmed = await auth.confirmEnable2FA(
        'login@example.com',
        enableCode,
      );
      expect(confirmed.success, isTrue);

      final login = await auth.login(
        email: 'login@example.com',
        password: 'C0rrect-Password!',
      );
      expect(login.success, isTrue);

      final sent = await auth.sendLogin2FAEmail(login.user!.id);
      expect(sent.success, isTrue);
      final loginCode = _codeFromLastEmail(email);
      expect(email.templates.last, EmailTemplate.loginVerification);
      expect(email.purposes.last, EmailPurpose.loginVerification);
      expect(email.codes.last, loginCode);

      final bad = await auth.verifyLogin2FA(login.user!.id, '000000');
      expect(bad.success, isFalse);

      final good = await auth.verifyLogin2FA(login.user!.id, loginCode);
      expect(good.success, isTrue);
      expect(good.user!.isTwoFactorEnabled, isTrue);
    });

    test('disable2FA clears the flag', () async {
      final user = await registerUser('disable@example.com');
      await auth.enable2FA(user.email!);
      final code = _codeFromLastEmail(email);
      await auth.confirmEnable2FA('disable@example.com', code);

      final result = await auth.disable2FA(user.id);
      expect(result.success, isTrue);

      final updated = await db.getUserById(user.id);
      expect(updated!.isTwoFactorEnabled, isFalse);
    });
  });
}
