import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';

class TopicProgressBar extends StatelessWidget {
  final String topic;
  final double progress;
  final int questions;
  final int mastered;

  const TopicProgressBar({
    super.key,
    required this.topic,
    required this.progress,
    required this.questions,
    required this.mastered,
  });

  @override
  Widget build(BuildContext context) {
    final color = progress >= 0.8
        ? AdaptiveColors.success(context)
        : progress >= 0.6
        ? AdaptiveColors.primary(context)
        : AdaptiveColors.warning(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AdaptiveColors.surfaceWarm(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                topic,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '$mastered/$questions',
                style: TextStyle(
                  color: AdaptiveColors.textSecondary(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AdaptiveColors.outlineVariant(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
