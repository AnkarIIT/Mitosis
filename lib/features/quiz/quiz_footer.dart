import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

/// Footer widget for quiz screen with navigation buttons
class QuizFooter extends ConsumerWidget {
  final int currentIndex;
  final int totalQuestions;
  final bool isAnswered;
  final bool isLastQuestion;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const QuizFooter({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.isAnswered,
    required this.isLastQuestion,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Previous button
          if (currentIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: onPrevious,
                child: const Text('Previous'),
              ),
            ),
          if (currentIndex > 0) const SizedBox(width: 12),

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
              child: Text(
                isLastQuestion ? 'Submit Quiz' : 'Next Question',
              ),
            ),
          ),
        ],
      ),
    );
  }
}