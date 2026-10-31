import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/exam_model.dart';

class QuestionPalette extends StatelessWidget {
  final ExamSession examSession;
  final Function(int) onQuestionTap;

  const QuestionPalette({
    required this.examSession,
    required this.onQuestionTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question Palette',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildLegend('Ans.', Color(0xFF10B981)),
                    SizedBox(width: 8),
                    _buildLegend('Not Ans.', Colors.white),
                    SizedBox(width: 8),
                    _buildLegend('Review', AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    examSession.questions.length,
                    (index) => _buildQuestionBox(context, index),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionBox(BuildContext context, int index) {
    final question = examSession.questions[index];
    final isCurrentQuestion = index == examSession.currentQuestionIndex;

    Color bgColor;
    if (question.status == QuestionStatus.attempted ||
        question.status == QuestionStatus.attemptedReview) {
      bgColor = Color(0xFF10B981);
    } else if (question.status == QuestionStatus.markedReview) {
      bgColor = AppColors.primary;
    } else {
      bgColor = Colors.white;
    }

    final borderColor = isCurrentQuestion ? AppColors.secondary : bgColor.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () => onQuestionTap(index),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: isCurrentQuestion ? 3 : 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: bgColor == Colors.white ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.white24, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: AppColors.textSubtle),
        ),
      ],
    );
  }
}
