import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/providers/providers.dart';
import '../../core/services/email_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/theme/app_colors.dart';

import '../profile/profile_screen.dart';
import 'import_questions_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _resendApiKeyController = TextEditingController();
  final _senderEmailController = TextEditingController();
  final _backendUrlController = TextEditingController();
  final _testEmailController = TextEditingController();
  EmailDeliveryMode _deliveryMode = EmailDeliveryMode.clientDirect;
  String? _emailStatusMessage;
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

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

      final emailService = ref.read(emailServiceProvider);
      if (emailService.apiKey != null) {
        _resendApiKeyController.text = emailService.apiKey!;
      }
      if (emailService.senderEmail != null) {
        _senderEmailController.text = emailService.senderEmail!;
      }
      _deliveryMode = emailService.deliveryMode;
      if (emailService.backendUrl != null) {
        _backendUrlController.text = emailService.backendUrl!;
      }

      final authState = ref.read(authProvider);
      if (authState.user?.email != null) {
        _testEmailController.text = authState.user!.email!;
      }
    });
  }

  Future<void> _loadNotificationSettings() async {
    final service = NotificationService();
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
        await NotificationService().scheduleDailyReminder(
          hour: picked.hour,
          minute: picked.minute,
        );
      }
    }
  }

  Future<void> _toggleReminders(bool value) async {
    final service = NotificationService();
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
    final service = BiometricService();
    final available = await service.isBiometricAvailable();
    final enabled = await service.isBiometricEnabled();
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final service = BiometricService();
    if (value) {
      final success = await service.authenticate();
      if (success) {
        await service.setBiometricEnabled(true);
        setState(() => _biometricEnabled = true);
      }
    } else {
      await service.setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _resendApiKeyController.dispose();
    _senderEmailController.dispose();
    _backendUrlController.dispose();
    _testEmailController.dispose();
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

  Future<void> _saveEmailConfig() async {
    final apiKey = _resendApiKeyController.text.trim();
    final senderEmail = _senderEmailController.text.trim();
    final backendUrl = _backendUrlController.text.trim();

    if (_deliveryMode == EmailDeliveryMode.clientDirect) {
      if (apiKey.isEmpty || senderEmail.isEmpty) {
        setState(() {
          _emailStatusMessage =
              'Enter both the Resend API key and sender email for direct delivery.';
        });
        return;
      }
    }

    if (_deliveryMode == EmailDeliveryMode.backend && backendUrl.isEmpty) {
      setState(() {
        _emailStatusMessage =
            'Enter a backend endpoint URL for backend delivery.';
      });
      return;
    }

    final emailService = ref.read(emailServiceProvider);
    if (_deliveryMode == EmailDeliveryMode.clientDirect) {
      await emailService.saveApiKey(apiKey);
      await emailService.saveSenderEmail(senderEmail);
    }
    await emailService.saveDeliveryMode(_deliveryMode);
    await emailService.saveBackendUrl(backendUrl);

    if (!mounted) return;
    setState(() {
      _emailStatusMessage =
          'Email settings saved. You can now send test emails.';
    });
  }

  Future<void> _sendTestEmail() async {
    final destination = _testEmailController.text.trim();
    final authState = ref.read(authProvider);

    if (destination.isEmpty) {
      setState(() {
        _emailStatusMessage = 'Enter a recipient email address first.';
      });
      return;
    }

    setState(() {
      _emailStatusMessage = 'Sending test email...';
    });

    final result = await ref
        .read(emailServiceProvider)
        .sendWelcomeEmail(
          to: destination,
          username: authState.user?.username ?? 'Learner',
        );

    if (!mounted) return;
    setState(() {
      _emailStatusMessage = result.message;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
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
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final res = await ref.read(authServiceProvider).deleteAccount();
              if (res.success) {
                ref.read(authProvider.notifier).logout();
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Account deleted successfully.')),
                );
              } else {
                navigator.pop();
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

          _buildSectionHeader('Cloud Sync'),
          _buildSettingsCard([
            ListTile(
              leading: Icon(
                AppConfig.isCloudAuthConfigured
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: AppConfig.isCloudAuthConfigured
                    ? AppColors.success
                    : AppColors.error,
              ),
              title: const Text('Supabase Sync'),
              subtitle: Text(
                AppConfig.isCloudAuthConfigured
                    ? 'Cloud sync is active'
                    : 'Cloud sync is not configured',
              ),
              trailing: AppConfig.isCloudAuthConfigured
                  ? IconButton(
                      icon: const Icon(Icons.sync),
                      onPressed: () async {
                        final sync = ref.read(cloudSyncServiceProvider);
                        if (sync != null) {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Syncing with cloud...'),
                            ),
                          );
                          await sync.syncAll();
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Sync complete!')),
                            );
                          }
                        }
                      },
                    )
                  : null,
            ),
            if (!AppConfig.isCloudAuthConfigured)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  AppConfig.cloudAuthHelpText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSubtle,
                  ),
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
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Try New Home'),
              subtitle: const Text('Premium redesigned home screen (preview)'),
              value: ref.watch(usePremiumHomeProvider),
              onChanged: (value) {
                ref.read(usePremiumHomeProvider.notifier).toggle(value);
              },
              secondary: const Icon(Icons.auto_awesome_outlined),
            ),
            if (_biometricAvailable) ...[
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Biometric Lock'),
                subtitle: const Text('Unlock app with Fingerprint/FaceID'),
                value: _biometricEnabled,
                onChanged: _toggleBiometric,
                secondary: const Icon(Icons.fingerprint),
              ),
            ],
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
                  style: const TextStyle(
                    color: AppColors.primary,
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
                  const Text(
                    'Enter your Gemini API Key to enable the AI Doubt Solver inside the app.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSubtle),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gemini API Key',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
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

          _buildSectionHeader('Email Delivery'),
          _buildSettingsCard([
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose direct delivery with Resend for demos or switch to a backend endpoint for production-safe sends.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSubtle),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<EmailDeliveryMode>(
                    initialValue: _deliveryMode,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Mode',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.swap_horiz),
                    ),
                    items: EmailDeliveryMode.values
                        .map(
                          (mode) => DropdownMenuItem(
                            value: mode,
                            child: Text(
                              mode == EmailDeliveryMode.clientDirect
                                  ? 'Direct Resend (demo/test)'
                                  : 'Backend endpoint',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (mode) {
                      if (mode != null) {
                        setState(() {
                          _deliveryMode = mode;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _resendApiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Resend API Key',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _senderEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Sender Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _backendUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Backend Email Endpoint',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cloud_upload_outlined),
                      helperText:
                          'Provide a URL that accepts JSON email payloads when using backend delivery.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveEmailConfig,
                      child: const Text('SAVE EMAIL SETTINGS'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _testEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Test Email Recipient',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.send_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _sendTestEmail,
                      child: const Text('SEND TEST EMAIL'),
                    ),
                  ),
                  if (_emailStatusMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _emailStatusMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader('Data Management'),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(
                Icons.upload_file_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Import Questions'),
              subtitle: const Text('Bulk-load questions from JSON or CSV'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportQuestionsScreen(),
                  ),
                );
              },
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
