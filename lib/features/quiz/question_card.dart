import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/question_model.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import 'option_tile.dart';

class QuestionCard extends ConsumerWidget {
  final Question question;
  final bool isAnswered;
  final bool showResults;
  final String? selectedAnswer;

  const QuestionCard({
    super.key,
    required this.question,
    required this.isAnswered,
    this.showResults = true,
    this.selectedAnswer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AdaptiveColors.textPrimary(context),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 24),
        if (question.type != 'shortAnswer')
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return OptionTile(
              question: question,
              index: index,
              option: option,
              isAnswered: isAnswered,
              showResults: showResults,
              selectedAnswer: selectedAnswer,
              onTap: () {
                ref
                    .read(quizProvider.notifier)
                    .selectAnswer(
                      ref.read(quizProvider).currentIndex,
                      option,
                      0,
                    );
              },
            );
          }),
      ],
    );
  }
}
