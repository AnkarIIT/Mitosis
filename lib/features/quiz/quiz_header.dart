import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/models/question_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';

/// Header widget for quiz screen showing topic name, timer, and progress
class QuizHeader extends ConsumerWidget {
  final String topicName;
  final int elapsedSeconds;
  final int currentIndex;
  final int totalQuestions;

  const QuizHeader({
    super.key,
    required this.topicName,
    required this.elapsedSeconds,
    required this.currentIndex,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);

    return Column(
      children: [
        Text(
          topicName,
          style: TextStyle(
            color: AdaptiveColors.textPrimary(context),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _formatTime(elapsedSeconds),
          style: TextStyle(
            color: AdaptiveColors.textSecondary(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class QuizProgressBar extends ConsumerWidget {
  final int currentIndex;
  final int totalQuestions;

  const QuizProgressBar({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: (currentIndex + 1) / totalQuestions,
        minHeight: 8,
        backgroundColor: AdaptiveColors.primary(context).withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation(AdaptiveColors.primary(context)),
      ),
    );
  }
}

class QuizQuestionCounter extends ConsumerWidget {
  final int currentIndex;
  final int totalQuestions;

  const QuizQuestionCounter({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
      'Question ${currentIndex + 1} of $totalQuestions',
      style: TextStyle(
        color: AdaptiveColors.textSecondary(context),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class QuizScoreIndicator extends ConsumerWidget {
  final String? selectedAnswer;
  final String? correctAnswer;

  const QuizScoreIndicator({
    super.key,
    required this.selectedAnswer,
    required this.correctAnswer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedAnswer == null) return const SizedBox.shrink();

    final isCorrect = selectedAnswer == correctAnswer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isCorrect ? '+4 NEET' : '-1 NEET',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isCorrect ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

/// AppBar for quiz screen - implements PreferredSizeWidget
class QuizAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String topicName;
  final int elapsedSeconds;
  final int currentIndex;
  final int totalQuestions;
  final bool isBookmarked;
  final Question currentQuestion;
  final VoidCallback onClose;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onHintPressed;

  const QuizAppBar({
    super.key,
    required this.topicName,
    required this.elapsedSeconds,
    required this.currentIndex,
    required this.totalQuestions,
    required this.isBookmarked,
    required this.currentQuestion,
    required this.onClose,
    required this.onBookmarkToggle,
    required this.onHintPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 32);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: AdaptiveColors.textPrimary(context)),
        onPressed: onClose,
      ),
      title: Column(
        children: [
          Text(
            topicName,
            style: TextStyle(
              color: AdaptiveColors.textPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _formatTime(elapsedSeconds),
            style: TextStyle(
              color: AdaptiveColors.textSecondary(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        _buildHintButton(context, currentQuestion),
        IconButton(
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: isBookmarked ? AdaptiveColors.primary(context) : AdaptiveColors.textSecondary(context),
          ),
          onPressed: onBookmarkToggle,
        ),
      ],
    );
  }

  Widget _buildHintButton(BuildContext context, Question question) {
    return IconButton(
      onPressed: onHintPressed,
      icon: Icon(Icons.lightbulb_outline, color: AdaptiveColors.primary(context)),
      tooltip: 'Get a hint',
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  }