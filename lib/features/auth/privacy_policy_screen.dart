import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AdaptiveColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: August 2026',
              style: TextStyle(
                fontSize: 14,
                color: AdaptiveColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Information We Collect',
              'We collect minimal information to provide the App\'s functionality:\n'
                  '• Account data: email, username, full name (if you sign in)\n'
                  '• Usage data: quiz attempts, scores, topic progress, flashcard reviews\n'
                  '• Device data: app preferences, theme choice, notification settings\n'
                  '• AI API key: Gemini API key (stored securely locally, never sent to us)',
            ),
            _buildSection(
              context,
              '2. How We Use Your Data',
              '• Provide core features: quizzes, progress tracking, spaced repetition\n'
                  '• Sync data across devices (only if you enable cloud sync)\n'
                  '• Send chapter text to Google Gemini for AI features (only when you use them)\n'
                  '• Improve the App\'s educational content and user experience',
            ),
            _buildSection(
              context,
              '3. Local-First Architecture',
              'NEET Mitos is designed as a local-first app. All your quiz history, flashcard schedules, error book entries, and study progress are stored in a local SQLite database on your device. You own this data.',
            ),
            _buildSection(
              context,
              '4. Cloud Sync (Optional)',
              'If you sign in and enable cloud sync, your data is encrypted in transit and stored on Supabase (PostgreSQL). Supabase\'s privacy policy applies to their processing. You can disable sync or delete your account at any time.',
            ),
            _buildSection(
              context,
              '5. AI Features & Third-Party Services',
              'AI features (flashcard generation, doubt solver) send the relevant '
                  'chapter text to Google\'s Gemini API. There are two possible '
                  'routes, and which one applies depends on your build:\n\n'
                  '• App-managed AI: requests pass through our server before reaching '
                  'Google. We do not retain the prompt or the response as content; we '
                  'record only a timestamped usage entry for rate-limiting and a short '
                  'truncated prefix to diagnose failures.\n'
                  '• Your own key: if you supplied a Gemini API key, requests go '
                  'directly from your device to Google. We never receive or store that '
                  'key.\n\n'
                  'Either way, Google\'s privacy policy governs their processing. AI '
                  'features are off unless you use them.',
            ),
            _buildSection(
              context,
              '6. Authentication',
              'We use Supabase Auth for Google Sign-In and optional cloud features. '
                  'Local email accounts are hashed with PBKDF2-HMAC-SHA256 '
                  '(600,000 iterations, per-account random salt) and stored only on your '
                  'device. We do not store your password. Supabase receives your email '
                  'address and authentication tokens when you use cloud features.',
            ),
            _buildSection(
              context,
              '7. Email & Verification Codes',
              'When you request a password reset, a sign-in code, or two-factor '
                  'enablement, your email address and a 6-digit code are transmitted '
                  'to our server and relayed to an email delivery provider. Codes are '
                  'stored on your device only as a salted hash, expire after 15 minutes, '
                  'and are limited to 5 attempts followed by a 15-minute lockout. '
                  'Requests are rate-limited per account and per recipient.',
            ),
            _buildSection(
              context,
              '8. Data Sharing',
              'We do not sell, rent, or share your personal data with third parties '
                  'except:\n'
                  '• Supabase (authentication, optional cloud sync)\n'
                  '• An email delivery provider (only for the transactional messages '
                  'described in section 7)\n'
                  '• Google Gemini API (only when you explicitly use AI features)\n'
                  '• As required by law',
            ),
            _buildSection(
              context,
              '9. Cookies & Web Analytics',
              'The Android and iOS apps set no tracking cookies. The web version uses '
                  'only the cookie strictly required to keep you signed in. We use no '
                  'advertising, profiling, or cross-site tracking cookies, and we run '
                  'no third-party analytics or tag scripts.',
            ),
            _buildSection(
              context,
              '10. Data Retention & Deletion',
              '• Local data: persists until you clear progress, delete your account, '
                  'or uninstall the App\n'
                  '• Cloud data: deleted when you use "Delete Account" in Settings. If '
                  'the cloud deletion cannot be completed immediately, your local data '
                  'is still removed and you will see a message telling you to retry\n'
                  '• Verification codes: discarded within minutes\n'
                  '• Email send logs: retained for up to 48 hours for rate-limiting, '
                  'then pruned\n'
                  '• You can request an export of your data by contacting us',
            ),
            _buildSection(
              context,
              '11. Security',
              '• Local database: SQLite without application-level encryption. Enable '
                  'device encryption for full protection.\n'
                  '• Passwords: PBKDF2-HMAC-SHA256, 600,000 iterations, random salt\n'
                  '• Network: all traffic uses HTTPS with certificate pinning for our '
                  'backend\n'
                  '• Biometric lock: optional app-level protection\n'
                  '• Secrets: no service credential is ever present in the app; mail '
                  'and AI provider keys live only on the server',
            ),
            _buildSection(
              context,
              '12. Your Rights',
              'Depending on where you live, you may have the right to:\n'
                  '• Access a copy of your data\n'
                  '• Correct data that is inaccurate\n'
                  '• Delete your data\n'
                  '• Restrict or object to processing\n'
                  '• Port your data to another provider\n'
                  '• Object to automated decision-making\n\n'
                  'These apply under the EU/UK GDPR, the India DPDP Act 2023, and '
                  'similar laws. To exercise any of them, contact us at the address in '
                  'section 16. We respond within 30 days. You may also complain to your '
                  'local data protection authority.\n\n'
                  'We do not use your data for automated decision-making or profiling '
                  'that produces legal or similarly significant effects.',
            ),
            _buildSection(
              context,
              '13. Children\'s Privacy',
              'The App is intended for students aged 13 and over. We do knowingly '
                  'collect data from children under 13. If you believe a child has '
                  'provided us data, contact us and we will delete it.',
            ),
            _buildSection(
              context,
              '14. International Transfers',
              'Our service providers (Supabase, Google, our email delivery provider) '
                  'may process data outside your country. Where data is transferred '
                  'internationally, the provider\'s standard contractual or equivalent '
                  'safeguards apply.',
            ),
            _buildSection(
              context,
              '15. Changes to This Policy',
              'We may update this Privacy Policy. Continued use after changes '
                  'constitutes acceptance. We will notify you of material changes via '
                  'in-app notice.',
            ),
            _buildSection(
              context,
              '16. Contact',
              'For privacy concerns, data requests, or to exercise any right in '
                  'section 12, email support@neetmitos.app or use Help & Support in '
                  'the App. Please describe your request and the account involved. We '
                  'do not ask for your password or any verification code by email.',
            ),
            const SizedBox(height: 24),
            Text(
              'By using NEET Mitos, you acknowledge that you have read and understood this Privacy Policy.',
              style: TextStyle(
                fontSize: 13,
                color: AdaptiveColors.textSecondary(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AdaptiveColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AdaptiveColors.textSecondary(context),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
