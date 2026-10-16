import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/utils/rank_predictor.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/learning_recommendation.dart';
import '../../core/theme/tokens.dart';

class ProgressDashboard extends ConsumerWidget {
  const ProgressDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(overallStatsProvider);
    final allSubjects = ref.watch(subjectsProvider);
    final recentActivity = ref.watch(recentActivityProvider);
    final weakTopics = ref.watch(weakTopicsProvider);
    final dailyGoal = ref.watch(dailyGoalProvider);
    final mockStats = ref.watch(mockTestStatsProvider);
    final recommendations = ref.watch(learningRecommendationsProvider);

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      appBar: AppBar(
        title: const Text('Your Progress'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headline first: estimated score + predicted rank, then the
            // daily goal ring, then what to do next.
            _buildRankPredictor(
              context,
              stats['accuracy'] as double,
              mockStats,
            ),
            const SizedBox(height: 24),
            _buildDailyGoal(context, dailyGoal),
            const SizedBox(height: 24),

            // Overall Stats Card (fixed deep-teal: readable in both modes)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.xlAll,
                side: BorderSide(color: AdaptiveColors.outlineVariant(context)),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B3538), Color(0xFF0E5B54)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.xlAll,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Overall Performance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: CircularProgressIndicator(
                                  value: (stats['accuracy'] as double) / 100,
                                  strokeWidth: 12,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(stats['accuracy'] as double).toStringAsFixed(0)}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    'Accuracy',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: [
                              _StatItem(
                                label: 'Quizzes',
                                value: '${stats['quizCount']}',
                                icon: Icons.quiz,
                              ),
                              const SizedBox(height: 16),
                              _StatItem(
                                label: 'Topics',
                                value: '${stats['topicsCompleted']}',
                                icon: Icons.check_circle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (recommendations.isNotEmpty) ...[
              Text(
                'Next best actions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...recommendations.map(
                (recommendation) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AdaptiveColors.primary(
                        context,
                      ).withValues(alpha: 0.12),
                      child: Icon(
                        recommendation.mastery < 50
                            ? Icons.menu_book
                            : Icons.bolt,
                        color: AdaptiveColors.primary(context),
                      ),
                    ),
                    title: Text(recommendation.topicName),
                    subtitle: Text(
                      '${recommendation.subject} • '
                      '${recommendation.mastery.toStringAsFixed(0)}% mastery\n'
                      '${recommendation.diagnosis}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (recommendation.primaryAction ==
                          LearningActionType.revise) {
                        context.push(
                          '/resources/notes?chapterId='
                          '${Uri.encodeComponent(recommendation.chapterId)}',
                        );
                        return;
                      }
                      context.push(
                        '/quiz?topicId=${Uri.encodeComponent(recommendation.topicId)}'
                        '&topicName=${Uri.encodeComponent(recommendation.topicName)}'
                        '&subject=${Uri.encodeComponent(recommendation.subject)}',
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 22),
            ],

            // Recent Quizzes Chart
            Text(
              'Recent Performance',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: AdaptiveColors.surface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AdaptiveColors.divider(context)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 160,
                  child: recentActivity.isEmpty
                      ? const Center(child: Text('No data yet'))
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 100,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            'Q${value.toInt() + 1}',
                                            style: TextStyle(
                                              color:
                                                  AdaptiveColors.textSecondary(
                                                    context,
                                                  ),
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 25,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: AdaptiveColors.divider(context),
                                  strokeWidth: 1,
                                  dashArray: [4, 4],
                                );
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(recentActivity.length, (
                              index,
                            ) {
                              final attempt =
                                  recentActivity[recentActivity.length -
                                      1 -
                                      index];
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: attempt.accuracy,
                                    color: attempt.accuracy >= 70
                                        ? AdaptiveColors.primary(context)
                                        : AdaptiveColors.warning(context),
                                    width: 16,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Weak Topics Section
            if (weakTopics.isNotEmpty) ...[
              Text(
                'Focus Areas (Weak Topics)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: weakTopics.length,
                  itemBuilder: (context, index) {
                    final topic = weakTopics[index];
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AdaptiveColors.error(context),
                            width: 0.5,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            context.push(
                              '/topic/${topic.id}?subjectName=${Uri.encodeComponent(topic.id.startsWith('bio') ? 'Biology' : (topic.id.startsWith('chem') ? 'Chemistry' : 'Physics'))}&chapterName=${Uri.encodeComponent('Review Needed')}',
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  topic.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: AdaptiveColors.error(context),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Needs Practice',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AdaptiveColors.error(
                                              context,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Subject-wise Performance
            Text(
              'Subject-wise Performance',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...allSubjects.map((subject) {
              final subjectStats = ref.watch(
                subjectStatsProvider(subject.name),
              );
              final accuracy = subjectStats['accuracy'] as double;
              final totalQuestions = subjectStats['totalQuestions'] as int;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              subject.name,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accuracy >= 70
                                    ? AdaptiveColors.primary(
                                        context,
                                      ).withValues(alpha: 0.2)
                                    : AdaptiveColors.warning(
                                        context,
                                      ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${accuracy.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: accuracy >= 70
                                      ? AdaptiveColors.primary(context)
                                      : AdaptiveColors.warning(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: totalQuestions == 0 ? 0 : accuracy / 100,
                            minHeight: 6,
                            backgroundColor: AdaptiveColors.outlineVariant(
                              context,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              accuracy >= 70
                                  ? AdaptiveColors.primary(context)
                                  : AdaptiveColors.warning(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          totalQuestions == 0
                              ? 'No quizzes attempted yet'
                              : '${(subjectStats['correctAnswers'] as int)} / $totalQuestions questions correct',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Study Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdaptiveColors.primary(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AdaptiveColors.primary(context).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AdaptiveColors.primary(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Study Tips',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AdaptiveColors.primary(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Review topics where your accuracy is below 70%\n'
                    '• Practice regularly to improve retention\n'
                    '• Read explanations after each question\n'
                    '• Attempt mixed tests to strengthen weak areas',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoal(BuildContext context, Map<String, dynamic> goal) {
    final percent = goal['percent'] as double;
    final completed = goal['completed'] as int;
    final target = goal['target'] as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdaptiveColors.divider(context)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 6,
                  backgroundColor: AdaptiveColors.divider(context),
                  valueColor: AlwaysStoppedAnimation(
                    percent >= 1.0
                        ? AdaptiveColors.success(context)
                        : AdaptiveColors.primary(context),
                  ),
                ),
                Icon(
                  percent >= 1.0 ? Icons.check : Icons.flag,
                  color: percent >= 1.0
                      ? AdaptiveColors.success(context)
                      : AdaptiveColors.primary(context),
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Practice Goal',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed / $target questions answered today',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AdaptiveColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankPredictor(
    BuildContext context,
    double accuracy,
    Map<String, dynamic> mockStats,
  ) {
    final bool hasMock = mockStats['hasMockTests'] as bool;
    final int estimatedScore = hasMock
        ? mockStats['highestScore'] as int
        : (accuracy / 100 * 720).toInt();

    final predictedRank = RankPredictor.predictRank(estimatedScore);
    final percentile = RankPredictor.getPercentile(estimatedScore);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdaptiveColors.primary(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AdaptiveColors.primary(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AdaptiveColors.primary(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'NEET Rank Predictor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AdaptiveColors.primary(context),
                  ),
                ),
              ),
              if (hasMock)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AdaptiveColors.success(
                      context,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Based on Mocks',
                    style: TextStyle(
                      fontSize: 10,
                      color: AdaptiveColors.success(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasMock ? 'Highest Mock Score' : 'Estimated Score',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      '$estimatedScore / 720',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Predicted AIR',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '~${predictedRank.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AdaptiveColors.primary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Current Percentile: $percentile',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AdaptiveColors.textSecondary(context),
                  ),
                ),
              ),
              if (!hasMock)
                Flexible(
                  child: Text(
                    'Rough estimate from topic accuracy',
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: AdaptiveColors.textSecondary(context),
                    ),
                  ),
                ),
            ],
          ),
          if (!hasMock) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/test-series'),
                icon: const Icon(Icons.quiz_outlined, size: 18),
                label: const Text('Take a mock test for a real prediction'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  // Rendered on the fixed deep-teal headline card: constant white keeps
  // contrast identical in light and dark mode.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
