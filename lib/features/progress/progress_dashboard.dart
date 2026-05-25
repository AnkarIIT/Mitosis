import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import '../topic_browser/topic_detail_screen.dart';

class ProgressDashboard extends ConsumerWidget {
  const ProgressDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(overallStatsProvider);
    final allSubjects = ref.watch(subjectsProvider);
    final recentActivity = ref.watch(recentActivityProvider);
    final weakTopics = ref.watch(weakTopicsProvider);
    final dailyGoal = ref.watch(dailyGoalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Goal
            _buildDailyGoal(context, dailyGoal),
            const SizedBox(height: 24),

            // Overall Stats Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.9),
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Overall Performance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textLight,
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
                                  backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                                  valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(stats['accuracy'] as double).toStringAsFixed(0)}%',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Accuracy',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.secondary,
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
            const SizedBox(height: 32),

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
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.divider),
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
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Q${value.toInt() + 1}',
                                        style: const TextStyle(
                                          color: AppColors.textSubtle,
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
                                  color: AppColors.divider,
                                  strokeWidth: 1,
                                  dashArray: [4, 4],
                                );
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(recentActivity.length, (index) {
                              final attempt = recentActivity[recentActivity.length - 1 - index];
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: attempt.accuracy,
                                    color: attempt.accuracy >= 70 ? AppColors.primary : AppColors.secondary,
                                    width: 16,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
                          side: const BorderSide(color: Colors.red, width: 0.5),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TopicDetailScreen(
                                  topic: topic,
                                  subjectName: topic.id.startsWith('bio') ? 'Biology' : (topic.id.startsWith('chem') ? 'Chemistry' : 'Physics'),
                                  chapterName: 'Review Needed',
                                ),
                              ),
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
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(Icons.warning, color: Colors.red, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Needs Practice',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.red),
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
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : AppColors.secondary.withValues(
                                        alpha: 0.2,
                                      ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${accuracy.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: accuracy >= 70
                                      ? AppColors.primary
                                      : AppColors.secondary,
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
                            backgroundColor: AppColors.secondary.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              accuracy >= 70
                                  ? AppColors.primary
                                  : AppColors.secondary,
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Study Tips',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
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
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(percent >= 1.0 ? Colors.green : AppColors.primary),
                ),
                Icon(
                  percent >= 1.0 ? Icons.check : Icons.flag,
                  color: percent >= 1.0 ? Colors.green : AppColors.primary,
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed / $target questions answered today',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.secondary),
                ),
              ],
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.secondary, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.secondary, fontSize: 12),
        ),
      ],
    );
  }
}
