import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/question_model.dart';
import '../../core/utils/answer_normalizer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

class OptionTile extends ConsumerWidget {
  final Question question;
  final int index;
  final String option;
  final bool isAnswered;
  /// When true, correctness feedback is shown (practice/review mode).
  /// When false, correctness is hidden (test/exam mode until submission).
  final bool showResults;
  final String? selectedAnswer;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.question,
    required this.index,
    required this.option,
    required this.isAnswered,
    this.showResults = true,
    this.selectedAnswer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = selectedAnswer == option;
    final isCorrect = AnswerNormalizer.isCorrect(option, question);

    final scheme = Theme.of(context).colorScheme;
    Color borderColor = AdaptiveColors.outline(context);
    Color bgColor = AdaptiveColors.surface(context);
    Color textColor = AdaptiveColors.textPrimary(context);

    // Only show correctness feedback when showResults is true.
    // In test/exam mode, correctness is hidden until quiz completion.
    final revealCorrectness = showResults && isAnswered;

    if (isSelected && !isAnswered) {
      borderColor = scheme.primary;
      bgColor = scheme.primaryContainer;
    } else if (revealCorrectness) {
      if (isCorrect) {
        borderColor = AdaptiveColors.success(context);
        bgColor = AdaptiveColors.success(context).withValues(alpha: 0.10);
      } else if (isSelected) {
        borderColor = AdaptiveColors.error(context);
        bgColor = AdaptiveColors.error(context).withValues(alpha: 0.10);
      }
    }

    // Result label only appears in review (showResults) mode
    final resultLabel = revealCorrectness && isCorrect
        ? 'Correct answer'
        : revealCorrectness && isSelected
        ? 'Your answer · Incorrect'
        : null;

    // In review mode, correct answer is always highlighted even if not selected
    if (showResults && isAnswered && isCorrect && !isSelected) {
      borderColor = AdaptiveColors.success(context);
      bgColor = AdaptiveColors.success(context).withValues(alpha: 0.06);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : AppDuration.fast,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Semantics(
          button: !isAnswered,
          selected: isSelected,
          label:
              'Option ${String.fromCharCode(65 + index)}. $option${resultLabel == null ? '' : '. $resultLabel'}',
          child: InkWell(
            onTap: isAnswered ? null : onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? scheme.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? scheme.primary : borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: TextStyle(
                            color: isSelected ? scheme.onPrimary : textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: textColor,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : null,
                                ),
                          ),
                          if (resultLabel != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCorrect
                                      ? Icons.check_circle_outline
                                      : Icons.cancel_outlined,
                                  size: 16,
                                  color: isCorrect
                                      ? AdaptiveColors.success(context)
                                      : AdaptiveColors.error(context),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    resultLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: isCorrect
                                              ? AdaptiveColors.success(context)
                                              : AdaptiveColors.error(context),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected && !isAnswered)
                      Icon(Icons.check_rounded, color: scheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
