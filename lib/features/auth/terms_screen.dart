import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
            _buildSection(context, '1. Acceptance of Terms',
              'By accessing or using NEET Mitos ("the App"), you agree to be bound by these Terms of Service. If you disagree with any part of these terms, you may not use the App.'),
            _buildSection(context, '2. Description of Service',
              'NEET Mitos is an educational application designed to help students prepare for the NEET UG examination. The App provides practice questions, mock tests, flashcards, study planning, and AI-assisted doubt solving features.'),
            _buildSection(context, '3. User Accounts',
              'You may use the App as a guest or create an account using email/OTP or Google Sign-In. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.'),
            _buildSection(context, '4. Content',
              'The questions, explanations, and study materials in the App are for educational purposes only. While we strive for accuracy, we do not guarantee that all content is error-free or up-to-date with the latest NEET syllabus. NCERT content references are for educational use only.'),
            _buildSection(context, '5. AI Features',
              'AI-powered features (flashcard generation, doubt solving) require a user-provided Gemini API key. Your chapter text is sent to Google Gemini for processing. We do not store or log your API key or the content sent to AI services beyond what is necessary for the feature to function.'),
            _buildSection(context, '6. Data & Privacy',
              'Your quiz progress, flashcard schedules, and error book are stored locally on your device. If you enable cloud sync, data is synced to Supabase. See our Privacy Policy for details.'),
            _buildSection(context, '7. Intellectual Property',
              'The App and its original content, features, and functionality are owned by NEET Mitos and are protected by international copyright, trademark, and other intellectual property laws.'),
            _buildSection(context, '8. Disclaimer of Warranties',
              'The App is provided "as is" and "as available" without warranties of any kind, either express or implied. We do not warrant that the App will be uninterrupted, error-free, or free of harmful components.'),
            _buildSection(context, '9. Limitation of Liability',
              'In no event shall NEET Mitos be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the App.'),
            _buildSection(context, '10. Changes to Terms',
              'We may modify these Terms at any time. Continued use of the App after changes constitutes acceptance of the new Terms.'),
            _buildSection(context, '11. Contact',
              'For questions about these Terms, contact us through the App\'s support channel.'),
            const SizedBox(height: 24),
            Text(
              'By using NEET Mitos, you acknowledge that you have read, understood, and agree to these Terms of Service.',
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
