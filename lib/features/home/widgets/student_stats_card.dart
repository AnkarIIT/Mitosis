import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';

class StudentStatsCard extends StatelessWidget {
  final int targetScore;
  final int currentScore;
  final int studyHours;
  final int daysStudied;

  const StudentStatsCard({
    super.key,
    required this.targetScore,
    required this.currentScore,
    required this.studyHours,
    required this.daysStudied,
  });

  @override
  Widget build(BuildContext context) {
    final safeTarget = targetScore == 0 ? 1 : targetScore;
    final percentage = (currentScore / safeTarget) * 100;
    final progressColor = percentage >= 80
        ? AdaptiveColors.success(context)
        : percentage >= 60
        ? AdaptiveColors.warning(context)
        : AdaptiveColors.error(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currentScore / $targetScore',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'NEET Score',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdaptiveColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: (currentScore / safeTarget).clamp(0.0, 1.0),
                        strokeWidth: 8,
                        backgroundColor: AdaptiveColors.primary(
                          context,
                        ).withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${percentage.toInt()}%',
                            style: TextStyle(
                              color: progressColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'ready',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AdaptiveColors.textSecondary(context),
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  icon: Icons.timer_outlined,
                  value: studyHours.toString(),
                  label: 'Study Hours',
                ),
                _buildStatItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  value: daysStudied.toString(),
                  label: 'Days',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AdaptiveColors.primary(context)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AdaptiveColors.textSecondary(context),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
