import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';

import '../profile/profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final geminiService = ref.read(geminiServiceProvider);
      if (geminiService.apiKey != null) {
        _apiKeyController.text = geminiService.apiKey!;
      }
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty) {
      await ref.read(geminiServiceProvider).saveApiKey(key);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API Key saved securely!')),
        );
      }
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Progress?'),
        content: const Text(
          'This will permanently delete your quiz history and topic progress. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              await ref.read(userProgressProvider.notifier).clearAllProgress();
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Progress has been reset.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Account'),
          _buildSettingsCard([
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(authState.user?.username ?? 'Guest User'),
              subtitle: Text(
                authState.user?.email ?? 'Sign in to sync progress',
              ),
              trailing: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: const Text('EDIT'),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader('Appearance'),
          _buildSettingsCard([
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Reduces eye strain at night'),
              value: themeMode == ThemeMode.dark,
              onChanged: (value) {
                ref.read(themeProvider.notifier).toggleTheme(value);
              },
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader('AI Tutor Configuration'),
          _buildSettingsCard([
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your Gemini API Key to enable the AI Doubt Solver inside the app.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSubtle),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Gemini API Key',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveApiKey,
                      child: const Text('SAVE KEY'),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader('Data Management'),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(
                Icons.delete_sweep_outlined,
                color: AppColors.error,
              ),
              title: const Text('Clear All Progress'),
              subtitle: const Text('Reset quiz scores and history'),
              onTap: _showResetConfirmation,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.textSubtle),
              title: const Text('Sign Out'),
              onTap: () {
                ref.read(authProvider.notifier).logout();
              },
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader('About'),
          _buildSettingsCard([
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('NEET Mitos'),
              subtitle: Text('Version 1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.policy_outlined),
              title: const Text('Privacy Policy'),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSubtle,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(children: children),
    );
  }
}
