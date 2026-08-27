import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/question_model.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import 'option_tile.dart';

class QuestionCard extends ConsumerWidget {
  final Question question;
  final bool isAnswered;
  final String? selectedAnswer;

  const QuestionCard({
    super.key,
    required this.question,
    required this.isAnswered,
    this.selectedAnswer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AdaptiveColors.textPrimary(context),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        if (question.type != 'shortAnswer')
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return OptionTile(
              question: question,
              index: index,
              option: option,
              isAnswered: isAnswered,
              selectedAnswer: selectedAnswer,
              onTap: () {
                ref.read(quizProvider.notifier).selectAnswer(
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
