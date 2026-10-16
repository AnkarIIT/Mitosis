import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/theme/app_theme.dart';

/// Support email. Shown to users and used by the mail templates, so the
/// address a student is told to contact is never a placeholder.
const String _supportEmail = 'support@neetmitos.app';
const String _website = 'https://neetmitos.app';

/// Help, FAQ and contact.
///
/// ## Why this screen exists
/// Two flows already told users to get in touch — the exam instructions said
/// "contact support immediately with your attempt ID", and account linking said
/// "contact support to merge your progress" — while no support channel existed
/// anywhere in the app. Both the Privacy Policy and the Terms pointed at "the
/// App's support channel", which was also absent. This is that channel.
class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _ContactCard(),
          const SizedBox(height: 8),
          const _Expansion(
            title: 'Signing in',
            children: [
              _QA(
                q: 'Google sign-in says "not configured".',
                a:
                    'This build ships without Google credentials, so the button is '
                    'hidden. Use email sign-in or continue as guest — your progress '
                    'is stored on your device either way.',
              ),
              _QA(
                q: 'I forgot my password.',
                a:
                    'On the sign-in screen choose "Forgot password". If an account '
                    'exists for that email, a 6-digit code is sent. It expires in 15 '
                    'minutes and you get 5 attempts before a 15-minute lockout.',
              ),
              _QA(
                q: 'It says my account has no email on file.',
                a:
                    'Accounts created through Google sign-in can be stored without a '
                    'local email address. Those cannot receive a password-reset code; '
                    'sign in with Google instead.',
              ),
              _QA(
                q: 'I am locked out.',
                a:
                    'After 5 wrong password attempts the account locks for 15 '
                    'minutes. This resets automatically — no action needed.',
              ),
            ],
          ),
          const _Expansion(
            title: 'Account & data',
            children: [
              _QA(
                q: 'Where is my data stored?',
                a:
                    'On your device. The app is offline-first: quizzes, progress, '
                    'flashcards and bookmarks live in a local database on this '
                    'device and work with no internet connection.',
              ),
              _QA(
                q: 'How do I delete my account?',
                a:
                    'Settings → Delete Account. This removes your local data '
                    'immediately and deletes the cloud account. It cannot be undone.',
              ),
              _QA(
                q: 'Can I move progress to a new phone?',
                a:
                    'Not yet. Cloud sync is still being validated and is disabled in '
                    'this build. Export is on the roadmap.',
              ),
              _QA(
                q:
                    'I used Google on one device and email on another. Will my '
                    'progress merge?',
                a:
                    'No — they are separate accounts, and we will not merge them '
                    'automatically. Merging is done deliberately by support after '
                    'you confirm ownership of the account.',
              ),
            ],
          ),
          const _Expansion(
            title: 'Tests & exams',
            children: [
              _QA(
                q: 'My exam closed when I switched apps.',
                a:
                    'That is the proctoring rule working: leaving the exam screen is '
                    'recorded as a violation and shown in the timer bar. Your answers '
                    'are saved continuously, so you can resume without losing work.',
              ),
              _QA(
                q: 'Will I lose progress if the app is killed?',
                a:
                    'No. Answers, flags, position and remaining time are checkpointed '
                    'as you go. Reopening restores the exact state.',
              ),
              _QA(
                q: 'My timer jumped when I changed the device clock.',
                a:
                    'Exam timers run on an absolute deadline rather than counting '
                    'seconds, so changing the clock does not grant extra time.',
              ),
              _QA(
                q: 'How do I report a wrong question?',
                a:
                    'Email $_supportEmail with the question text. Incorrect answers you '
                    'give are also added to your Error Book automatically.',
              ),
            ],
          ),
          const _Expansion(
            title: 'AI tutor & privacy',
            children: [
              _QA(
                q: 'What does the AI tutor send anywhere?',
                a:
                    'Only the text you ask it about. If the app-managed AI is enabled, '
                    'requests pass through our server; if you supplied your own key, '
                    'the request goes from your device to the provider directly. We '
                    'do not use your AI key for anything else.',
              ),
              _QA(
                q: 'Do you track me?',
                a:
                    'No analytics or advertising SDKs. The app stores nothing about '
                    'you beyond what is listed in the Privacy Policy.',
              ),
              _QA(
                q: 'Do you use cookies?',
                a:
                    'The web version uses only the cookie strictly needed to keep you '
                    'signed in. We do not use advertising or cross-site tracking '
                    'cookies.',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'NEET Mitos · Version 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AdaptiveColors.textSecondary(context),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ContactCard extends ConsumerWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final isSignedIn = user != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Still stuck?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Email us and include any error text. '
              '${isSignedIn ? 'Do not send your password or any code we sent you.' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AdaptiveColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: const Text('Email support'),
                  onPressed: () => _copyOrLaunch(
                    context,
                    'mailto:$_supportEmail'
                    '${isSignedIn ? '?subject=${Uri.encodeComponent('NEET Mitos support — ${user.username}')}' : ''}',
                    _supportEmail,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy address'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _supportEmail));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support address copied')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.public, size: 18),
              label: const Text(_website),
              onPressed: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }

  void _copyOrLaunch(BuildContext context, String uri, String fallback) {
    // No url_launcher dependency here; a copy is the reliable path, and the
    // snackbar tells the user exactly what happened.
    Clipboard.setData(ClipboardData(text: fallback));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Email address copied: $fallback')));
  }
}

class _Expansion extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Expansion({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: children,
    );
  }
}

class _QA extends StatelessWidget {
  final String q;
  final String a;

  const _QA({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(a, style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
