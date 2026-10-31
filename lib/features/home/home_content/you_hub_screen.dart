import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
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
    final hasActivity = attempts > 0;

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Text('You', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 18),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                      child: Text(name.isEmpty ? 'S' : name[0].toUpperCase()),
                    ),
                    title: Text(name.isEmpty ? 'Student' : name),
                    subtitle: Text(
                      auth.isGuest
                          ? 'Studying as a guest'
                          : 'Your study profile',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/profile'),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your progress',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (!hasActivity)
                          Text(
                            'Your study history will appear here after your first practice session.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AdaptiveColors.textSecondary(context),
                                ),
                          )
                        else ...[
                          Text(
                            'Across $attempts questions attempted',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AdaptiveColors.textSecondary(context),
                                ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _Metric(
                                  value: '${accuracy.toStringAsFixed(0)}%',
                                  label: 'Practice accuracy',
                                ),
                              ),
                              Expanded(
                                child: _Metric(
                                  value: '$attempts',
                                  label: 'Questions',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => context.push('/progress'),
                            child: const Text('View detailed progress'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your study',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _YouLink(
                        icon: Icons.calendar_month_outlined,
                        title: 'Study plan & goals',
                        onTap: () => context.push('/study-plan'),
                      ),
                      const Divider(height: 1, indent: 56),
                      _YouLink(
                        icon: Icons.person_outline_rounded,
                        title: 'Profile & account',
                        onTap: () => context.push('/profile'),
                      ),
                      const Divider(height: 1, indent: 56),
                      _YouLink(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () => context.push('/settings'),
                      ),
                      const Divider(height: 1, indent: 56),
                      _YouLink(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & support',
                        onTap: () => context.push('/help'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
  Widget build(BuildContext context) => ListTile(
    minVerticalPadding: 12,
    leading: Icon(icon, color: AdaptiveColors.primary(context)),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
