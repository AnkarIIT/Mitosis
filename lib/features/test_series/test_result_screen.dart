import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_progress_model.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';

class TestResultScreen extends ConsumerWidget {
  final QuizAttempt attempt;

  const TestResultScreen({super.key, required this.attempt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildScoreHeader(context),
            const SizedBox(height: 24),
            _buildSubjectBreakdown(context),
            const SizedBox(height: 24),
            _buildTimeAnalysis(context),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(quizProvider.notifier).resetQuiz();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Review Answers'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(quizProvider.notifier).resetQuiz();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader(BuildContext context) {
    final accuracy = attempt.accuracy;
    final color = accuracy >= 70 ? Colors.green : (accuracy >= 40 ? Colors.orange : Colors.red);

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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
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
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '${accuracy.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
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
    if (attempt.subjectScores == null || attempt.subjectScores!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject Analysis',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...attempt.subjectScores!.entries.map((e) {
          final subject = e.key;
          final score = e.value;
          // Note: In a real app we'd need total per subject, for now we show absolute score
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(subject),
                    Text('$score Correct', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: score / (attempt.totalQuestions / attempt.subjectScores!.length),
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
    final avgTime = attempt.totalQuestions == 0 ? 0 : attempt.timeSpentSeconds / attempt.totalQuestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Analysis',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatBox(context, 'Total Time', _formatTime(attempt.timeSpentSeconds), Icons.timer),
            _buildStatBox(context, 'Avg / Question', '${avgTime.toStringAsFixed(1)}s', Icons.speed),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String value, IconData icon) {
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
      case 'biology': return Colors.green;
      case 'chemistry': return Colors.blue;
      case 'physics': return Colors.orange;
      default: return AppColors.primary;
    }
  }
}
