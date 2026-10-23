import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class YouHubScreen extends ConsumerWidget {
  const YouHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final name = (user?.fullName ?? user?.username ?? 'Student').trim();
    final stats = ref.watch(overallStatsProvider);
    final accuracy = (stats['accuracy'] as num).toDouble();
    final attempts = (stats['totalAttempted'] as num).toInt();

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Text('You', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: AppColors.brandTeal.withValues(alpha: .14),
                  foregroundColor: AppColors.brandNavy,
                  child: Text(name.isEmpty ? 'S' : name[0].toUpperCase()),
                ),
                title: Text(name.isEmpty ? 'Student' : name),
                subtitle: Text(
                  auth.isGuest ? 'Studying as a guest' : 'Your study profile',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/profile'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _Metric(
                            value: '${accuracy.toStringAsFixed(0)}%',
                            label: 'Accuracy',
                          ),
                        ),
                        Expanded(
                          child: _Metric(value: '$attempts', label: 'Attempts'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.push('/progress'),
                      child: const Text('View detailed progress'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Your study', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _YouLink(
              icon: Icons.calendar_month_outlined,
              title: 'Study plan & goals',
              onTap: () => context.push('/study-plan'),
            ),
            _YouLink(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () => context.push('/settings'),
            ),
            _YouLink(
              icon: Icons.help_outline_rounded,
              title: 'Help & support',
              onTap: () => context.push('/help'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.headlineSmall),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _YouLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _YouLink({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: AdaptiveColors.primary(context)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}
