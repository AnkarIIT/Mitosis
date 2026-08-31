import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/question_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';

class OptionTile extends ConsumerWidget {
  final Question question;
  final int index;
  final String option;
  final bool isAnswered;
  final String? selectedAnswer;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.question,
    required this.index,
    required this.option,
    required this.isAnswered,
    this.selectedAnswer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = selectedAnswer == option;
    final isCorrect = option == question.correctAnswer;

    Color borderColor = AdaptiveColors.divider(context);
    Color bgColor = AdaptiveColors.surface(context);
    Color textColor = AdaptiveColors.textPrimary(context);

    if (isSelected && !isAnswered) {
      borderColor = AdaptiveColors.primary(context);
      bgColor = AdaptiveColors.primary(context).withValues(alpha: 0.05);
    } else if (isAnswered) {
      if (isCorrect) {
        borderColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.05);
        textColor = AppColors.success;
      } else if (isSelected) {
        borderColor = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.05);
        textColor = AppColors.error;
      }
    }

    return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
            child: InkWell(
              onTap: isAnswered ? null : onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? borderColor : Colors.transparent,
                        border: Border.all(color: borderColor),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: TextStyle(
                            color: isSelected ? Colors.white : textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isAnswered && isCorrect)
                      const Icon(Icons.check_circle, color: AppColors.success)
                    else if (isAnswered && isSelected)
                      const Icon(Icons.cancel, color: AppColors.error),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(
          key: ValueKey(
            '${question.id}_${isAnswered ? 'answered' : 'unanswered'}',
          ),
        )
        .fadeIn(duration: AppDuration.normal)
        .slideX(
          begin: 0.08,
          end: 0,
          duration: AppDuration.normal,
          curve: Curves.easeOutCubic,
        )
        .then(
          delay: isAnswered && isCorrect ? AppDuration.fast : Duration.zero,
          duration: AppDuration.fast,
        )
        .scale(
          begin: isAnswered && isCorrect
              ? const Offset(1.05, 1.05)
              : const Offset(1, 1),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
        );
  }
}
