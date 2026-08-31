import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/question_model.dart';
import '../../core/models/user_progress_model.dart';
import '../../core/services/test_analytics_service.dart';
import '../../core/services/result_export_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CbtResultScreen extends ConsumerWidget {
  final QuizAttempt attempt;
  final TestAnalytics analytics;
  final List<Question>? questions;
  final Map<int, String?>? answersByIndex;

  const CbtResultScreen({
    super.key,
    required this.attempt,
    required this.analytics,
    this.questions,
    this.answersByIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raw = analytics.score.rawScore;
    final maxScore = analytics.score.maxScore;
    final accuracy = analytics.score.accuracy;
    final ratio = maxScore <= 0 ? 0.0 : raw / maxScore;
    final color = ratio >= 0.5
        ? AppColors.success
        : (ratio >= 0.25 ? AppColors.warning : AppColors.error);

    return Scaffold(
      backgroundColor: AppColors.surfaceWarm,
      appBar: AppBar(
        title: const Text('Test Result'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          if (attempt.seed != null &&
              questions != null &&
              questions!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.replay_rounded),
              tooltip: 'Replay exact paper',
              onPressed: () => _replayPaper(context, ref),
            ),
          if (questions != null && answersByIndex != null)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Export to CSV',
              onPressed: () => _exportToCsv(context, ref),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScoreHeader(context, raw, maxScore, accuracy, color),
            const SizedBox(height: 16),
            if (analytics.showRankEstimate) ...[
              _buildRankEstimates(context),
              const SizedBox(height: 8),
              Text(
                'Rough estimate — not an official NEET rank/percentile.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AdaptiveColors.textSecondary(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
            ],
            _buildSectionTitle(context, 'Subject Analysis'),
            _buildSubjectBreakdown(context),
            const SizedBox(height: 20),
            _buildSectionTitle(context, 'Time Analysis'),
            _buildTimeAnalysis(context),
            if (analytics.score.results.isNotEmpty &&
                analytics.score.config.isFullLengthMock)
              _buildTimeHeatmap(context),
            if (analytics.weakTopics.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Weak Topics to Revise'),
              _buildWeakTopics(context),
            ],
            if (questions != null && questions!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Question Review'),
              _buildQuestionReview(context),
            ],
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to Home'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader(
    BuildContext context,
    int raw,
    int maxScore,
    double accuracy,
    Color color,
  ) {
    final scoreRatio = maxScore <= 0 ? 0.0 : raw / maxScore;

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
            'NEET Score',
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
                height: 150,
                width: 150,
                child: CircularProgressIndicator(
                  value: scoreRatio.clamp(0.0, 1.0),
                  strokeWidth: 12,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$raw/$maxScore',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AdaptiveColors.textPrimary(context),
                    ),
                  ),
                  Text(
                    '+${analytics.score.config.marksPerCorrect} / '
                    '${analytics.score.config.marksPerWrong} • '
                    '${analytics.score.correct} correct • '
                    '${analytics.score.incorrect} wrong',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Accuracy: ${accuracy.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankEstimates(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildEstimateBox(
            context,
            'Percentile Estimate',
            '${analytics.percentileEstimate.toStringAsFixed(2)}%',
            Icons.leaderboard,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEstimateBox(
            context,
            'Estimated AIR',
            _formatAir(analytics.airEstimate),
            Icons.emoji_events,
            AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildEstimateBox(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textSubtle),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAir(int air) {
    if (air >= 100000) return '${(air / 100000).toStringAsFixed(1)} L';
    return air.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AdaptiveColors.textPrimary(context),
        ),
      ),
    );
  }

  Widget _buildSubjectBreakdown(BuildContext context) {
    final subjects = analytics.subjects.values.toList();
    if (subjects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: subjects.map((subject) {
          final color = _subjectColor(subject.subject);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subject.subject,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AdaptiveColors.textPrimary(context),
                      ),
                    ),
                    Text(
                      '${subject.correct}C • ${subject.incorrect}W • '
                      '${subject.unanswered}U',
                      style: TextStyle(
                        fontSize: 12,
                        color: AdaptiveColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: subject.attempted == 0
                            ? 0
                            : (subject.accuracy / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${subject.accuracy.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeAnalysis(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            context,
            'Total Time',
            _formatTime(attempt.timeSpentSeconds),
            Icons.timer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            context,
            'Avg / Question',
            '${analytics.averageTimePerQuestion.toStringAsFixed(1)}s',
            Icons.speed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            context,
            'Attempted',
            '${analytics.score.attempted}/${analytics.score.results.length}',
            Icons.checklist,
          ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textSubtle),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildWeakTopics(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: analytics.weakTopics.map((topic) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.report_problem,
                  color: AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.topic,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AdaptiveColors.textPrimary(context),
                        ),
                      ),
                      Text(
                        '${topic.chapter} • ${topic.attempted} attempted, '
                        '${topic.correct} correct (${topic.accuracy.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AdaptiveColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuestionReview(BuildContext context) {
    final allQuestions = questions ?? const <Question>[];
    final answers = answersByIndex ?? const <int, String?>{};

    if (allQuestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final correct = <int>[];
    final incorrect = <int>[];
    final unattempted = <int>[];

    for (var i = 0; i < allQuestions.length; i++) {
      final q = allQuestions[i];
      final answer = answers[i];
      if (answer == null || answer.isEmpty) {
        unattempted.add(i);
      } else if (answer.trim() == q.correctAnswer.trim()) {
        correct.add(i);
      } else {
        incorrect.add(i);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildReviewChip(
              context,
              'Correct',
              correct.length,
              AppColors.success,
            ),
            const SizedBox(width: 8),
            _buildReviewChip(
              context,
              'Incorrect',
              incorrect.length,
              AppColors.error,
            ),
            const SizedBox(width: 8),
            _buildReviewChip(
              context,
              'Skipped',
              unattempted.length,
              AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(allQuestions.length, (index) {
          final q = allQuestions[index];
          final userAnswer = answers[index];
          final isCorrect = correct.contains(index);
          final isIncorrect = incorrect.contains(index);
          // Unattached logic is intentionally folded into the else branch below.

          Color statusColor;
          IconData statusIcon;
          String statusText;
          if (isCorrect) {
            statusColor = AppColors.success;
            statusIcon = Icons.check_circle_rounded;
            statusText = 'Correct';
          } else if (isIncorrect) {
            statusColor = AppColors.error;
            statusIcon = Icons.cancel_rounded;
            statusText = 'Incorrect';
          } else {
            statusColor = AppColors.warning;
            statusIcon = Icons.remove_circle_rounded;
            statusText = 'Skipped';
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: statusColor.withValues(alpha: 0.06),
            child: ExpansionTile(
              leading: Icon(statusIcon, color: statusColor, size: 22),
              title: Text(
                'Q${index + 1}. ${q.questionText}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(statusText),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...q.options.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final option = entry.value;
                        final isUserChoice =
                            userAnswer == String.fromCharCode(65 + idx);
                        final isCorrectOption =
                            idx.toString() == q.correctAnswer;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCorrectOption
                                      ? AppColors.success
                                      : (isUserChoice
                                            ? AppColors.error
                                            : AppColors.divider),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + idx),
                                    style: TextStyle(
                                      color: isCorrectOption || isUserChoice
                                          ? Colors.white
                                          : AdaptiveColors.textPrimary(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(option)),
                            ],
                          ),
                        );
                      }),
                      if (q.explanation != null &&
                          q.explanation!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Divider(),
                        Text(
                          'Explanation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(q.explanation!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReviewChip(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            '$label $count',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _subjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('physics')) return AppColors.physicsAccent;
    if (s.contains('chem')) return AppColors.chemistryAccent;
    if (s.contains('bot') || s.contains('zoo') || s.contains('bio')) {
      return AppColors.biologyAccent;
    }
    return AppColors.primary;
  }

  String _formatTime(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final m = safe ~/ 60;
    final s = safe % 60;
    return '${m}m ${s}s';
  }

  Future<void> _replayPaper(BuildContext context, WidgetRef ref) async {
    try {
      final attempt = this.attempt;
      final seed = attempt.seed;
      final pool = questions;
      if (seed == null || pool == null || pool.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot replay: missing seed or question pool.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final random = math.Random(seed);
      final shuffled = List<Question>.from(pool);
      shuffled.shuffle(random);

      await context.push(
        '/cbt/replay',
        extra: {'config': analytics.score.config, 'questionPool': shuffled},
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to replay: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportToCsv(BuildContext context, WidgetRef ref) async {
    try {
      final qs = questions;
      final answers = answersByIndex;
      if (qs == null || answers == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No attempt data available to export.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final path = await ResultExportService.exportQuizAttemptToCsv(
        attempt,
        qs,
        answers,
      );

      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export CSV.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV exported to: $path'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTimeHeatmap(BuildContext context) {
    final results = analytics.score.results;
    final secondsPerQuestion = <int>[];

    // Derive per-question seconds from answersByIndex when available,
    // otherwise fall back to average distribution.
    if (answersByIndex != null && answersByIndex!.isNotEmpty) {
      // We don't have exact per-question seconds in this widget, so we
      // show a normalized bar chart using the analytics average.
      final avg = analytics.averageTimePerQuestion;
      secondsPerQuestion.addAll(List.filled(results.length, avg.round()));
    } else {
      final avg = analytics.averageTimePerQuestion;
      secondsPerQuestion.addAll(List.filled(results.length, avg.round()));
    }

    if (secondsPerQuestion.isEmpty) return const SizedBox.shrink();

    final maxSeconds = secondsPerQuestion.reduce(math.max).toDouble();
    if (maxSeconds <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(context, 'Time per Question'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('0s', style: Theme.of(context).textTheme.labelSmall),
                  const Spacer(),
                  Text(
                    '${_formatTime(maxSeconds.toInt())}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: List.generate(secondsPerQuestion.length, (i) {
                  final seconds = secondsPerQuestion[i];
                  final ratio = (seconds / maxSeconds).clamp(0.0, 1.0);
                  final result = results.length > i ? results[i] : null;
                  Color barColor;
                  if (result == null) {
                    barColor = AppColors.divider;
                  } else if (result.isCorrect) {
                    barColor = AppColors.success;
                  } else if (result.isIncorrect) {
                    barColor = AppColors.error;
                  } else {
                    barColor = AppColors.warning;
                  }

                  return Tooltip(
                    message: 'Q${i + 1}: ${_formatTime(seconds)}',
                    child: Container(
                      width: 12,
                      height: 28 + ratio * 32,
                      decoration: BoxDecoration(
                        color: barColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                'Average: ${_formatTime(analytics.averageTimePerQuestion.toInt())} per question',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
