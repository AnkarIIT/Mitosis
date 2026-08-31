import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';

import '../../core/services/biometric_service.dart';

import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _biometricEnabled = false;
  BiometricStatus _biometricStatus = BiometricStatus.unavailable;
  String? _biometricUnavailableReason;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    _loadBiometricSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final geminiService = ref.read(geminiServiceProvider);
      if (geminiService.apiKey != null) {
        _apiKeyController.text = geminiService.apiKey!;
      }
    });
  }

  Future<void> _loadNotificationSettings() async {
    final service = ref.read(notificationServiceProvider);
    final enabled = await service.areRemindersEnabled();
    final timeStr = await service.getReminderTime();
    final parts = timeStr.split(':');

    setState(() {
      _remindersEnabled = enabled;
      _reminderTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      if (_remindersEnabled) {
        await ref
            .read(notificationServiceProvider)
            .scheduleDailyReminder(hour: picked.hour, minute: picked.minute);
      }
    }
  }

  Future<void> _toggleReminders(bool value) async {
    final service = ref.read(notificationServiceProvider);
    if (value) {
      final granted = await service.requestPermissions();
      if (granted) {
        await service.scheduleDailyReminder(
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
        );
        setState(() => _remindersEnabled = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notification permissions are required for reminders.',
              ),
            ),
          );
        }
      }
    } else {
      await service.cancelAllReminders();
      setState(() => _remindersEnabled = false);
    }
  }

  Future<void> _loadBiometricSettings() async {
    final service = ref.read(biometricServiceProvider);
    final status = await service.getBiometricStatus();
    final enabled = await service.isBiometricEnabled();

    String? reason;
    switch (status) {
      case BiometricStatus.available:
        reason = null;
        break;
      case BiometricStatus.enrolledButUnavailable:
        reason =
            'No fingerprint or face enrolled. Add one in device Settings to enable app lock.';
        break;
      case BiometricStatus.unavailable:
        reason = 'This device does not support biometric authentication.';
        break;
      case BiometricStatus.error:
        reason = 'Could not check biometric availability. Please try again.';
        break;
    }

    if (mounted) {
      setState(() {
        _biometricStatus = status;
        _biometricUnavailableReason = reason;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final service = ref.read(biometricServiceProvider);
    if (value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.fingerprint,
            size: 32,
            color: AppColors.primary,
          ),
          title: const Text('Enable Biometric Lock?'),
          content: const Text(
            'You will need to authenticate with your fingerprint, face, or device PIN every time you open the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('ENABLE'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      final success = await service.authenticate();
      if (success) {
        await service.setBiometricEnabled(true);
        if (mounted) {
          setState(() => _biometricEnabled = true);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Lock not enabled.'),
          ),
        );
      }
    } else {
      await service.setBiometricEnabled(false);
      if (mounted) {
        setState(() => _biometricEnabled = false);
      }
    }
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

  void _showBackupInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.backup_outlined, size: 32),
        title: const Text('Backup Data'),
        content: const Text(
          'Your quiz progress, flashcard schedules, and error book are stored locally on this device.\n\n'
          'A future update will add cloud backup for signed-in users. For now, your data stays safe on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRestoreInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.restore_outlined, size: 32),
        title: const Text('Restore Data'),
        content: const Text(
          'Data restore will be available in a future update when cloud backup is launched.\n\n'
          'Your current data is preserved as long as you don\'t uninstall the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.policy_outlined, size: 32),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'NEET Mitos respects your privacy.\n\n'
            '• All quiz data, flashcards, and progress are stored locally on your device.\n'
            '• We do not collect, sell, or share any personal data.\n'
            '• No analytics or tracking tools are used.\n'
            '• AI features (when enabled) send chapter text to Google Gemini for flashcard generation only.\n'
            '• Authentication is handled by Supabase when cloud features are enabled.\n\n'
            'This is a placeholder policy. A full legal policy will be published before the app\'s public release.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
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
            onPressed: () => context.pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(userProgressProvider.notifier).clearAllProgress();
              context.pop();
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

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action is IRREVERSIBLE.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final res = await ref.read(authProvider.notifier).deleteAccount();
              if (res.success) {
                context.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Account deleted successfully.'),
                  ),
                );
              } else {
                context.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('Error: ${res.message}')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('DELETE PERMANENTLY'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPyqs() async {
    final messenger = ScaffoldMessenger.of(context);
    final downloader = ref.read(pyqDownloaderProvider);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Downloading NEET PYQs... This may take a while.'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final count = await downloader.downloadAll();
      if (!mounted) return;

      if (count > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Successfully downloaded $count NEET PYQ questions!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'No new questions downloaded. Sources may be unavailable.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              leading: CircleAvatar(
                backgroundColor: AdaptiveColors.primary(context),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(authState.user?.username ?? 'Guest User'),
              subtitle: Text(
                authState.user?.email ?? 'Sign in to sync progress',
              ),
              trailing: TextButton(
                onPressed: () {
                  context.push('/profile');
                },
                child: const Text('EDIT'),
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Two-Factor Authentication'),
              subtitle: const Text('Extra security via Email OTP'),
              value: authState.user?.isTwoFactorEnabled ?? false,
              onChanged: authState.user == null
                  ? null
                  : (value) {
                      ref.read(authProvider.notifier).toggle2FA(value);
                    },
              secondary: const Icon(Icons.security),
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
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Biometric Lock'),
              subtitle: Text(
                _biometricUnavailableReason ??
                    'Unlock app with Fingerprint/FaceID',
              ),
              value: _biometricEnabled,
              onChanged: _biometricStatus == BiometricStatus.available
                  ? _toggleBiometric
                  : null,
              secondary: Icon(
                _biometricStatus == BiometricStatus.available
                    ? Icons.fingerprint
                    : Icons.fingerprint_outlined,
              ),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader('Study Reminders'),
          _buildSettingsCard([
            SwitchListTile(
              title: const Text('Daily Study Nudge'),
              subtitle: const Text('Get reminded to keep your streak'),
              value: _remindersEnabled,
              onChanged: _toggleReminders,
              secondary: const Icon(Icons.notifications_active_outlined),
            ),
            if (_remindersEnabled) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Reminder Time'),
                trailing: Text(
                  _reminderTime.format(context),
                  style: TextStyle(
                    color: AdaptiveColors.primary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: _selectTime,
              ),
            ],
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader('AI Tutor Configuration'),
          _buildSettingsCard([
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your Gemini API Key to enable the AI Doubt Solver inside the app.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AdaptiveColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gemini API Key',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AdaptiveColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                Icons.backup_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Backup Data'),
              subtitle: const Text('Export your quiz history and progress'),
              onTap: _showBackupInfo,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.restore_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Restore Data'),
              subtitle: const Text('Import a previously exported backup'),
              onTap: _showRestoreInfo,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.upload_file_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Import Questions'),
              subtitle: const Text('Bulk-load questions from JSON or CSV'),
              onTap: () {
                context.push('/settings/import');
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.download_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Download NEET PYQs'),
              subtitle: const Text(
                'Fetch previous year questions from configured sources',
              ),
              onTap: _downloadPyqs,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.delete_sweep_outlined,
                color: AppColors.error,
              ),
              title: const Text('Clear All Progress'),
              subtitle: const Text('Reset quiz scores and history'),
              onTap: _showResetConfirmation,
            ),
            if (authState.user != null) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.person_remove_outlined,
                  color: AppColors.error,
                ),
                title: const Text('Delete Account'),
                subtitle: const Text('Permanently remove all your data'),
                onTap: _showDeleteAccountConfirmation,
              ),
            ],
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: AdaptiveColors.textSecondary(context),
              ),
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
              onTap: _showPrivacyPolicy,
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Licenses'),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'NEET Mitos',
                applicationVersion: '1.0.0',
              ),
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AdaptiveColors.textSecondary(context),
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
        side: BorderSide(
          color: AdaptiveColors.divider(context).withValues(alpha: 0.5),
        ),
      ),
      child: Column(children: children),
    );
  }
}
