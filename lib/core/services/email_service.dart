import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../config/app_config.dart';

/// Outcome of a send attempt.
///
/// [message] is safe to show to a user: it never carries a provider response
/// body, a stack trace or an exception string.
class EmailSendResult {
  final bool success;
  final String message;

  const EmailSendResult({required this.success, required this.message});

  static const EmailSendResult ok = EmailSendResult(
    success: true,
    message: 'Sent.',
  );

  static EmailSendResult sent([String message = 'Sent.']) =>
      EmailSendResult(success: true, message: message);

  static EmailSendResult fail(String message) =>
      EmailSendResult(success: false, message: message);
}

/// Why an email was sent, used for the reason-for-contact line and for
/// template branching.
enum EmailPurpose {
  passwordReset('reset your password'),
  loginVerification('verify your sign-in'),
  twoFactorEnable('turn on two-factor authentication'),
  emailVerification('verify your email address'),
  welcome('finish setting up your account'),
  accountDeleted('confirm your account was deleted'),
  securityNotice('a security change on your account');

  const EmailPurpose(this.reason);

  /// Phrased to complete "You are receiving this because you asked to …".
  final String reason;
}

/// Sends transactional email through the `send-email` Supabase Edge Function.
///
/// ## Why the endpoint is derived, not configurable
///
/// The previous implementation read a backend URL from `SharedPreferences` and
/// POSTed a caller-supplied `{from, subject, html}` blob to it with **no
/// authorization header**. Two consequences:
///
///  * Any party who learned the URL could send arbitrary mail through it,
///    choosing their own `from` — an open relay for spoofing.
///  * Worse, no UI ever wrote that preference, so `_backendUrl` was always
///    null, `isConfigured` was always false, and **password reset and 2FA mail
///    could never be delivered at all**.
///
/// The endpoint is now derived from `SUPABASE_URL` at compile time, so it
/// cannot be pointed elsewhere, and the API key is attached automatically.
///
/// ## Secret handling
///
/// No mail-provider credential ever reaches the device. The Edge Function holds
/// it in a Supabase secret and is the only thing that talks to the provider.
///
/// ## Known limitation: signed-out callers
///
/// `send-email` authenticates every request with the caller's Supabase JWT and
/// binds the recipient to that account's own verified address. Password reset
/// is requested *while signed out*, so there is no session to present and the
/// function answers 401. Reset codes are still generated and stored locally in
/// Drift (see `AuthService.sendPasswordReset`) and the user-facing flow is
/// deliberately non-committal, so nothing is corrupted — but the email simply
/// does not go out.
///
/// Closing that needs a server-side reset endpoint that mints its own code
/// (unauthenticated, fixed templates, per-email and per-IP ceilings, never
/// revealing whether an account exists). That is a deliberate design decision,
/// not a patch, and has not been made here.
class EmailService {
  /// Bounded so a hung endpoint cannot wedge the OTP/resend button forever.
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  EmailService({http.Client? client}) : _client = client ?? http.Client();

  /// Whether a backend is compiled into this build.
  ///
  /// False when `SUPABASE_URL` is absent, which is the offline-only build. In
  /// that case every send fails fast with a clear message instead of hanging.
  bool get isConfigured => AppConfig.supabaseUrl.trim().isNotEmpty;

  /// Current Supabase access token, or null when nobody is signed in.
  ///
  /// The `send-email` function requires `Authorization: Bearer <jwt>`; it does
  /// not accept the anon key alone. This service previously sent only `apikey`,
  /// so the function rejected **every** call with 401 and password-reset / 2FA
  /// mail never left the device.
  String? _accessToken() {
    if (!AppConfig.enableCloudAuth) return null;
    try {
      return supabase.Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      // Supabase.initialize has not run (offline-only build).
      return null;
    }
  }

  String? get _endpoint {
    final base = AppConfig.supabaseUrl.trim();
    if (base.isEmpty) return null;
    return '$base/functions/v1/send-email';
  }

  /// Sends a transactional email.
  ///
  /// [to] must be a single address. [template] selects one of the built-in
  /// templates rather than accepting raw HTML: a raw-HTML parameter would make
  /// it far too easy to interpolate untrusted text into a security email, which
  /// is exactly the injection bug this class previously had.
  Future<EmailSendResult> send({
    required String to,
    required EmailTemplate template,
    EmailPurpose purpose = EmailPurpose.securityNotice,
    String? username,
    String? code,
    Duration? timeout,
  }) async {
    final endpoint = _endpoint;
    if (endpoint == null) {
      return EmailSendResult.fail(
        'This build has no email backend configured.',
      );
    }

    final recipient = to.trim();
    if (recipient.isEmpty || !recipient.contains('@')) {
      return EmailSendResult.fail('Invalid email address.');
    }
    final token = _accessToken();
    try {
      final response = await _client
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              // The function scopes the sender, template and rate limit by the
              // caller's JWT, so it must authenticate. Without this the endpoint
              // is an unauthenticated open relay.
              if (AppConfig.supabaseAnonKey.isNotEmpty)
                'apikey': AppConfig.supabaseAnonKey,
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              // Only a template *name* crosses the wire. The function owns the
              // HTML, so user text can never be interpolated into a security
              // email on the server side either.
              'template': template.wireName,
              'to': recipient,
              ?username: username,
              ?code: code,
              'purpose': purpose.reason,
            }),
          )
          .timeout(timeout ?? _timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return EmailSendResult.ok;
      }

      // The body is deliberately not surfaced: it can contain provider detail.
      if (response.statusCode == 429) {
        return EmailSendResult.fail(
          'Too many emails requested. Please wait a minute and try again.',
        );
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return EmailSendResult.fail('Email could not be sent from this build.');
      }
      return EmailSendResult.fail(
        'Email could not be sent (${response.statusCode}). Please try again.',
      );
    } on TimeoutException {
      return EmailSendResult.fail(
        'Email service did not respond. Please try again.',
      );
    } catch (_) {
      // Never surface the exception: it can contain the endpoint URL and
      // provider internals.
      return EmailSendResult.fail(
        'Could not reach the email service. Please try again.',
      );
    }
  }

  /// Convenience wrapper kept for callers that predate [EmailTemplate].
  Future<EmailSendResult> sendTransactionalEmail({
    required String to,
    required String subject,
    required String html,
    String? text,
    String? from,
  }) {
    // `subject`, `html`, `text` and `from` are all ignored. Sending arbitrary
    // HTML from the client is how the injection bug happened; this method exists
    // only so existing call sites keep compiling, and it refuses to send.
    return Future.value(
      EmailSendResult.fail(
        'sendTransactionalEmail is retired. Use EmailService.send with an '
        'EmailTemplate so the HTML stays under server control.',
      ),
    );
  }

  void dispose() => _client.close();
}

/// The set of emails this app can send.
///
/// Each maps to a server-side template. The client never assembles HTML, so
/// there is no path for user-controlled text (`username`) to reach a security
/// email unescaped.
enum EmailTemplate {
  passwordReset('password_reset'),
  loginVerification('login_verification'),
  twoFactorEnable('two_factor_enable'),
  emailVerification('email_verification'),
  welcome('welcome'),
  accountDeleted('account_deleted'),
  securityNotice('security_notice');

  const EmailTemplate(this.wireName);

  /// Identifier understood by the `send-email` Edge Function.
  final String wireName;

  /// Local, mobile-safe rendering used for in-app preview and tests.
  ///
  /// Not sent to anyone — the server owns delivery HTML — but it keeps template
  /// wording reviewable in one place and gives the tests something concrete to
  /// assert about escaping.
  String render({
    required EmailPurpose purpose,
    String? username,
    String? code,
  }) {
    final greeting = (username != null && username.trim().isNotEmpty)
        ? 'Hi ${escapeHtml(username)},'
        : 'Hi there,';

    final codeBlock = (code != null && code.trim().isNotEmpty)
        ? '''
        <p style="margin:24px 0;">
          <span style="display:inline-block;font-size:30px;font-weight:700;
            letter-spacing:6px;padding:14px 22px;border-radius:10px;
            background:#eef2ff;color:#3730a3;">${escapeHtml(code)}</span>
        </p>
        <p style="margin:0 0 8px;font-size:13px;color:#6b7280;">
          This code expires in 15 minutes.</p>'''
        : '';

    return '''
    <div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;
                max-width:560px;margin:0 auto;padding:24px;color:#111827;
                background:#ffffff;">
      <div style="border-bottom:3px solid #4f46e5;padding-bottom:14px;margin-bottom:22px;">
        <span style="font-size:19px;font-weight:700;color:#4f46e5;">NEET Mitos</span>
      </div>
      <p style="margin:0 0 14px;font-size:15px;line-height:1.55;">$greeting</p>
      <p style="margin:0 0 6px;font-size:15px;line-height:1.55;">
        Use this email to ${escapeHtml(purpose.reason)}.</p>
      $codeBlock
      <p style="margin:22px 0 0;font-size:13px;line-height:1.6;color:#4b5563;">
        If you did not request this, no action is needed — you can ignore
        this message and nothing has changed on your account.</p>
      <div style="margin-top:26px;padding-top:16px;border-top:1px solid #e5e7eb;
                  font-size:12px;line-height:1.6;color:#6b7280;">
        <p style="margin:0 0 6px;">NEET Mitos &middot; support@neetmitos.app</p>
        <p style="margin:0;">Read our
          <a href="https://neetmitos.app/privacy" style="color:#4f46e5;">Privacy Policy</a>
          and <a href="https://neetmitos.app/terms" style="color:#4f46e5;">Terms</a>.
        </p>
      </div>
    </div>''';
  }
}

/// Escapes text for safe interpolation into HTML.
///
/// Applied to every interpolated value in [EmailTemplate.render]. The previous
/// implementation escaped only `sendWelcomeEmail` — which nothing called — while
/// the two templates that actually shipped (password reset and 2FA, both built
/// in `AuthService`) interpolated `users.username` raw. A username of
/// `<img src=x onerror=...>` therefore rendered as markup in every security
/// email the app sent.
String escapeHtml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
