import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
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
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: August 2026',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection('1. Information We Collect',
              'We collect minimal information to provide the App\'s functionality:\n'
              '• Account data: email, username, full name (if you sign in)\n'
              '• Usage data: quiz attempts, scores, topic progress, flashcard reviews\n'
              '• Device data: app preferences, theme choice, notification settings\n'
              '• AI API key: Gemini API key (stored securely locally, never sent to us)'),
            _buildSection('2. How We Use Your Data',
              '• Provide core features: quizzes, progress tracking, spaced repetition\n'
              '• Sync data across devices (only if you enable cloud sync)\n'
              '• Send chapter text to Google Gemini for AI features (only when you use them)\n'
              '• Improve the App\'s educational content and user experience'),
            _buildSection('3. Local-First Architecture',
              'NEET Mitos is designed as a local-first app. All your quiz history, flashcard schedules, error book entries, and study progress are stored in a local SQLite database on your device. You own this data.'),
            _buildSection('4. Cloud Sync (Optional)',
              'If you sign in and enable cloud sync, your data is encrypted in transit and stored on Supabase (PostgreSQL). Supabase\'s privacy policy applies to their processing. You can disable sync or delete your account at any time.'),
            _buildSection('5. AI Features & Third-Party Services',
              'AI features (flashcard generation, doubt solver) require your own Google Gemini API key. When you use these features:\n'
              '• The relevant chapter text is sent to Google\'s Gemini API\n'
              '• Google\'s privacy policy governs their processing\n'
              '• We do not see, store, or log your API key or the content sent to Google\n'
              '• Your API key is stored only in your device\'s secure storage'),
            _buildSection('6. Authentication',
              'We use Supabase Auth for email/OTP and Google Sign-In. Supabase receives your email and authentication tokens. We do not store passwords. See Supabase\'s privacy policy for their data handling.'),
            _buildSection('7. Data Sharing',
              'We do not sell, rent, or share your personal data with third parties except:\n'
              '• Supabase (for authentication & optional cloud sync)\n'
              '• Google Gemini API (only when you explicitly use AI features)\n'
              '• As required by law'),
            _buildSection('8. Data Retention & Deletion',
              '• Local data: persists until you clear progress or uninstall the App\n'
              '• Cloud data: deleted when you use "Delete Account" in Settings\n'
              '• You can export your data before deletion (future feature)'),
            _buildSection('9. Security',
              '• Local database: SQLite with no encryption (device-level encryption recommended)\n'
              '• API keys: stored in Flutter Secure Storage (encrypted)\n'
              '• Network: all API calls use HTTPS\n'
              '• Biometric lock: optional app-level protection'),
            _buildSection('10. Children\'s Privacy',
              'The App is intended for students aged 13+. We do not knowingly collect data from children under 13. If you believe a child has provided us data, contact us to delete it.'),
            _buildSection('11. Changes to This Policy',
              'We may update this Privacy Policy. Continued use after changes constitutes acceptance. We will notify you of material changes via in-app notice.'),
            _buildSection('12. Contact',
              'For privacy concerns or data requests, contact us through the App\'s support channel.'),
            const SizedBox(height: 24),
            Text(
              'By using NEET Mitos, you acknowledge that you have read and understood this Privacy Policy.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSubtle,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
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
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSubtle,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}