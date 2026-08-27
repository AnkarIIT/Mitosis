import 'package:flutter/material.dart';
import '../../core/models/user_progress_model.dart';
import '../../core/services/test_analytics_service.dart';
import '../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class CbtResultScreen extends StatelessWidget {
  final QuizAttempt attempt;
  final TestAnalytics analytics;

  const CbtResultScreen({
    super.key,
    required this.attempt,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    final raw = analytics.score.rawScore;
    final maxScore = analytics.score.maxScore;
    final accuracy = analytics.score.accuracy;
    // Colour by score ratio, not a 720-based threshold: practice tests and
    // optional-section mocks have a smaller maxScore.
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
            // Percentile/AIR are only defensible for a full-length mock, and even
            // then they're a rough model — gate + label them (never claim an
            // official NEET rank).
            if (analytics.showRankEstimate) ...[
              _buildRankEstimates(context),
              const SizedBox(height: 8),
              Text(
                'Rough estimate — not an official NEET rank/percentile.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSubtle,
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
            if (analytics.weakTopics.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Weak Topics to Revise'),
              _buildWeakTopics(context),
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
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '+${analytics.score.config.marksPerCorrect} / '
                    '${analytics.score.config.marksPerWrong} • '
                    '${analytics.score.correct} correct • '
                    '${analytics.score.incorrect} wrong',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textSubtle),
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
          color: AppColors.textDark,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${subject.correct}C • ${subject.incorrect}W • '
                      '${subject.unanswered}U',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubtle,
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
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '${topic.chapter} • ${topic.attempted} attempted, '
                        '${topic.correct} correct (${topic.accuracy.toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSubtle,
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

  Color _subjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('physics')) return AppColors.physicsAccent;
    if (s.contains('chem')) return AppColors.chemistryAccent;
    // Botany and Zoology are both Biology sections.
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
}
