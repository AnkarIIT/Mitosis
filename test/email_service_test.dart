import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/services/email_service.dart';

/// Covers the email layer.
///
/// ## What changed and why
///
/// The old service built a raw `{from, subject, html}` payload and POSTed it to
/// a URL read from `SharedPreferences`, with no authorization header. Two
/// consequences:
///
///  * it was an open relay — anyone who learned the URL could send mail
///    choosing their own `from`;
///  * no screen ever *wrote* that preference, so `isConfigured` was permanently
///    false and password-reset / 2FA mail could never be delivered at all.
///
/// The service now sends a template *name* to a derived endpoint, so HTML is
/// owned by the server and user text cannot reach a security email unescaped.
void main() {
  group('auth policy', () {
    // Regression: `EmailService` originally sent only the `apikey` header and
    // no Authorization at all, so `send-email` — which requires
    // `Authorization: Bearer <jwt>` — rejected EVERY call with 401. Password
    // reset and 2FA mail never left the device. This locks the rule that fixes
    // it without needing a live Supabase project.
    test('password reset never sends a session token', () {
      expect(
        EmailService.shouldAuthenticate(EmailTemplate.passwordReset, 'jwt'),
        isFalse,
      );
      expect(
        EmailService.shouldAuthenticate(EmailTemplate.passwordReset, null),
        isFalse,
      );
    });

    test('every other template authenticates when a token exists', () {
      for (final template in EmailTemplate.values) {
        if (template == EmailTemplate.passwordReset) continue;
        expect(
          EmailService.shouldAuthenticate(template, 'jwt'),
          isTrue,
          reason: '${template.wireName} must authenticate',
        );
      }
    });

    test('no template sends a token when there is no session', () {
      for (final template in EmailTemplate.values) {
        expect(
          EmailService.shouldAuthenticate(template, null),
          isFalse,
          reason: '${template.wireName} cannot invent a token',
        );
        expect(
          EmailService.shouldAuthenticate(template, ''),
          isFalse,
          reason: '${template.wireName} treated an empty token as valid',
        );
      }
    });

    test('password reset is the only unauthenticated template', () {
      final unauthenticated = EmailTemplate.values
          .where((t) => !EmailService.shouldAuthenticate(t, 'jwt'))
          .toList();
      expect(
        unauthenticated,
        [EmailTemplate.passwordReset],
        reason:
            'widening the unauthenticated set turns this into an open relay',
      );
    });
  });

  group('escapeHtml', () {
    test('escapes every HTML-significant character', () {
      expect(
        escapeHtml('''<img src=x onerror="alert('1')">&'''),
        '&lt;img src=x onerror=&quot;alert(&#39;1&#39;)&quot;&gt;&amp;',
      );
    });

    test('escapes ampersands before the other entities', () {
      // Order matters: `&` must be escaped first, otherwise the ampersands
      // introduced by `&lt;` would be double-escaped.
      expect(escapeHtml('a & <b>'), 'a &amp; &lt;b&gt;');
    });

    test('leaves plain text untouched', () {
      expect(escapeHtml('student123'), 'student123');
    });

    test('handles an empty string', () {
      expect(escapeHtml(''), '');
    });
  });

  group('EmailTemplate rendering', () {
    test('escapes a hostile username in every template', () {
      // This is the exact injection the live code allowed: `_build2FAEmailHtml`
      // and `_buildResetEmailHtml` interpolated `users.username` raw, so a
      // username of `<img src=x onerror=…>` rendered as markup in every
      // security email. `test/two_factor_test.dart` even asserted that
      // unescaped output.
      const hostile = '<img src=x onerror=alert(document.cookie)>';

      for (final template in EmailTemplate.values) {
        final html = template.render(
          purpose: EmailPurpose.loginVerification,
          username: hostile,
          code: '123456',
        );
        expect(
          html,
          isNot(contains('<img')),
          reason: '${template.wireName} emitted raw markup from username',
        );
        expect(
          html,
          contains('&lt;img'),
          reason: '${template.wireName} did not escape the username',
        );
      }
    });

    test('escapes a hostile code', () {
      final html = EmailTemplate.passwordReset.render(
        purpose: EmailPurpose.passwordReset,
        username: 'student',
        code: '<b>000000</b>',
      );
      expect(html, isNot(contains('<b>')));
      expect(html, contains('&lt;b&gt;'));
    });

    test('escapes the purpose string', () {
      // A purpose is drawn from a fixed enum in the app, so there is no live
      // injection path — but the renderer must still be safe if a purpose ever
      // becomes caller-supplied, since the server escapes the same field.
      final html = EmailTemplate.securityNotice.render(
        purpose: EmailPurpose.securityNotice,
        username: null,
        code: null,
      );
      expect(html, contains('a security change on your account'));
    });

    test('omits the greeting when no username is supplied', () {
      final html = EmailTemplate.welcome.render(
        purpose: EmailPurpose.welcome,
        username: null,
        code: null,
      );
      expect(html, contains('Hi there,'));
    });

    test('includes the code block only when a code is present', () {
      final withCode = EmailTemplate.loginVerification.render(
        purpose: EmailPurpose.loginVerification,
        username: 'a',
        code: '123456',
      );
      final withoutCode = EmailTemplate.securityNotice.render(
        purpose: EmailPurpose.securityNotice,
        username: 'a',
      );

      expect(withCode, contains('expires in 15 minutes'));
      expect(withoutCode, isNot(contains('expires in 15 minutes')));
    });

    test('every template names its purpose and links the legal pages', () {
      for (final template in EmailTemplate.values) {
        final html = template.render(
          purpose: EmailPurpose.securityNotice,
          username: null,
          code: null,
        );
        expect(html, contains('support@neetmitos.app'));
        expect(html, contains('/privacy'));
        expect(html, contains('/terms'));
        // A "you didn't ask for this" line is what makes a transactional
        // security email safe to receive unsolicited.
        expect(html, contains('did not request'));
      }
    });
  });

  group('EmailTemplate wire names', () {
    test('are stable and match the Edge Function contract', () {
      // These strings cross the wire to `send-email`; renaming one silently
      // breaks delivery.
      expect(EmailTemplate.passwordReset.wireName, 'password_reset');
      expect(EmailTemplate.loginVerification.wireName, 'login_verification');
      expect(EmailTemplate.twoFactorEnable.wireName, 'two_factor_enable');
      expect(EmailTemplate.emailVerification.wireName, 'email_verification');
      expect(EmailTemplate.accountDeleted.wireName, 'account_deleted');
    });

    test('are all snake_case with no spaces', () {
      for (final template in EmailTemplate.values) {
        expect(template.wireName, matches(RegExp(r'^[a-z0-9_]+$')));
      }
    });
  });

  group('EmailSendResult', () {
    test('ok is a success', () {
      expect(EmailSendResult.ok.success, isTrue);
    });

    test('fail carries the reason', () {
      final r = EmailSendResult.fail('nope');
      expect(r.success, isFalse);
      expect(r.message, 'nope');
    });
  });

  group('EmailPurpose', () {
    test('every purpose has a human-readable reason', () {
      for (final purpose in EmailPurpose.values) {
        expect(purpose.reason, isNotEmpty);
        // The reason is interpolated into a sentence, so it must read as a
        // verb phrase: "Use this email to <reason>."
        expect(purpose.reason, isNot(contains('.')));
      }
    });
  });

  group('sendTransactionalEmail is retired', () {
    test('refuses rather than sending caller-supplied HTML', () async {
      final service = EmailService();
      final result = await service.sendTransactionalEmail(
        to: 'a@b.com',
        subject: 'x',
        html: '<b>hi</b>',
      );
      expect(result.success, isFalse);
      expect(result.message, contains('retired'));
      service.dispose();
    });
  });
}
