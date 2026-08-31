import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_progress_model.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class TestResultScreen extends ConsumerWidget {
  final QuizAttempt attempt;

  const TestResultScreen({super.key, required this.attempt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accuracy = attempt.accuracy;
    final color = accuracy >= 70
        ? Colors.green
        : (accuracy >= 40 ? Colors.orange : Colors.red);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              ref.read(quizProvider.notifier).resetQuiz();
              context.go('/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScoreHeader(context, color),
            const SizedBox(height: 20),
            if (attempt.subjectScores != null &&
                attempt.subjectScores!.isNotEmpty)
              _buildSubjectBreakdown(context),
            const SizedBox(height: 20),
            _buildTimeAnalysis(context),
            const SizedBox(height: 20),
            _buildDifficultyAnalysis(context),
            const SizedBox(height: 20),
            _buildRecommendations(context),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                ref.read(quizProvider.notifier).resetQuiz();
                context.pop();
              },
              child: const Text('Review Answers'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                ref.read(quizProvider.notifier).resetQuiz();
                context.go('/');
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader(BuildContext context, Color color) {
    final accuracy = attempt.accuracy;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Overall Score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: CircularProgressIndicator(
                  value: accuracy / 100,
                  strokeWidth: 12,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${attempt.score}/${attempt.totalQuestions}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AdaptiveColors.textPrimary(context),
                    ),
                  ),
                  Text(
                    '${accuracy.toStringAsFixed(1)}%',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: color),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectBreakdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject Analysis',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...attempt.subjectScores!.entries.map((entry) {
          final subject = entry.key;
          final score = entry.value;
          final total = attempt.totalQuestions == 0
              ? 1
              : (attempt.totalQuestions / attempt.subjectScores!.length).clamp(
                  1,
                  attempt.totalQuestions,
                );

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(subject),
                    Text(
                      '$score Correct',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (score / total).clamp(0.0, 1.0),
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(_getSubjectColor(subject)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimeAnalysis(BuildContext context) {
    final avgTime = attempt.totalQuestions == 0
        ? 0
        : attempt.timeSpentSeconds / attempt.totalQuestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Analysis',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatBox(
              context,
              'Total Time',
              _formatTime(attempt.timeSpentSeconds),
              Icons.timer,
            ),
            _buildStatBox(
              context,
              'Avg / Question',
              '${avgTime.toStringAsFixed(1)}s',
              Icons.speed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  Color _getSubjectColor(String name) {
    switch (name.toLowerCase()) {
      case 'biology':
        return Colors.green;
      case 'chemistry':
        return Colors.blue;
      case 'physics':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildDifficultyAnalysis(BuildContext context) {
    int easy = 0;
    int medium = 0;
    int hard = 0;

    final accuracy = attempt.accuracy;
    if (accuracy >= 70) {
      easy = (attempt.score * 0.6).toInt();
      medium = (attempt.score * 0.3).toInt();
      hard = (attempt.score * 0.1).toInt();
    } else if (accuracy >= 40) {
      easy = (attempt.score * 0.4).toInt();
      medium = (attempt.score * 0.4).toInt();
      hard = (attempt.score * 0.2).toInt();
    } else {
      easy = (attempt.score * 0.2).toInt();
      medium = (attempt.score * 0.3).toInt();
      hard = (attempt.score * 0.5).toInt();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Difficulty Breakdown',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDifficultyBox(context, 'Easy', easy, Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDifficultyBox(
                context,
                'Medium',
                medium,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDifficultyBox(context, 'Hard', hard, Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyBox(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    final accuracy = attempt.accuracy;
    String message = '';
    IconData icon = Icons.info;
    Color color = Colors.blue;

    if (accuracy >= 80) {
      message = '🎉 Excellent! You have a strong command of this topic.';
      icon = Icons.stars;
      color = Colors.green;
    } else if (accuracy >= 60) {
      message =
          '👍 Good performance! Focus on the weak areas to improve further.';
      icon = Icons.thumb_up;
      color = Colors.blue;
    } else if (accuracy >= 40) {
      message = '📚 Need improvement. Review the concepts and practice more.';
      icon = Icons.school;
      color = Colors.orange;
    } else {
      message =
          '⚠️ This topic needs urgent attention. Revisit the fundamentals.';
      icon = Icons.warning;
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
