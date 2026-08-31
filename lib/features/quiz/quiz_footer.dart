import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

/// Footer widget for quiz screen with navigation buttons
class QuizFooter extends ConsumerWidget {
  final int currentIndex;
  final int totalQuestions;
  final bool isAnswered;
  final bool isLastQuestion;
  final bool isFlagged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFlagToggle;
  final VoidCallback onMarkForReviewAndNext;
  final VoidCallback onSubmit;
  final VoidCallback onPaletteToggle;

  const QuizFooter({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.isAnswered,
    required this.isLastQuestion,
    required this.isFlagged,
    required this.onPrevious,
    required this.onNext,
    required this.onFlagToggle,
    required this.onMarkForReviewAndNext,
    required this.onSubmit,
    required this.onPaletteToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action buttons row
          Row(
            children: [
              // Previous button
              if (currentIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Previous'),
                  ),
                ),
              if (currentIndex > 0) const SizedBox(width: 8),

              // Flag/Mark for Review button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFlagToggle,
                  icon: Icon(
                    isFlagged ? Icons.flag : Icons.flag_outlined,
                    color: isFlagged ? Colors.orange : null,
                    size: 18,
                  ),
                  label: Text(
                    isFlagged ? 'Unmark' : 'Flag',
                    style: TextStyle(
                      color: isFlagged ? Colors.orange : null,
                      fontWeight: isFlagged
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isFlagged
                          ? Colors.orange
                          : AdaptiveColors.divider(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Mark for Review & Next
              if (!isLastQuestion)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isAnswered ? onMarkForReviewAndNext : null,
                    icon: const Icon(Icons.flag_rounded, size: 18),
                    label: const Text('Mark & Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

              // Next/Submit button
              Expanded(
                child: ElevatedButton(
                  onPressed: isAnswered
                      ? () {
                          if (isLastQuestion) {
                            onSubmit();
                          } else {
                            onNext();
                          }
                        }
                      : null,
                  child: Text(isLastQuestion ? 'Submit Quiz' : 'Next'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question palette button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPaletteToggle,
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: const Text('Question Palette'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AdaptiveColors.primary(context)),
                foregroundColor: AdaptiveColors.primary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
