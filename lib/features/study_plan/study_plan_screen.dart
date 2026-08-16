import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/subject_model.dart';
import '../../core/models/user_preferences_model.dart';
import '../topic_browser/topic_detail_screen.dart';

class StudyPlanScreen extends ConsumerWidget {
  const StudyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weakTopics = ref.watch(studyPlanTopicsProvider);
    final dailyGoal = ref.watch(dailyGoalProvider);
    final prefs = ref.watch(userPreferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground(context),
      appBar: AppBar(
        title: const Text('Study Planner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.adaptiveText(context)),
        titleTextStyle: TextStyle(
          color: AppColors.adaptiveText(context),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStreakBanner(context, ref),
            const SizedBox(height: 24),
            _buildDailyGoalStatus(context, dailyGoal),
            const SizedBox(height: 24),
            _buildSmartStudyPlan(context, weakTopics, prefs),
            const SizedBox(height: 24),
            _buildUpcomingMilestones(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBanner(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(userProgressProvider);
    final streak = progress.currentStreak;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak Day Study Streak!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Text(
                  'Keep it up! You\'re building a powerful habit.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalStatus(
    BuildContext context,
    Map<String, dynamic> goal,
  ) {
    final percent = goal['percent'] as double;
    final completed = goal['completed'] as int;
    final target = goal['target'] as int;

    return Card(
      elevation: 0,
      color: AppColors.adaptiveSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Goal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.adaptiveText(context),
                  ),
                ),
                Text(
                  '${(percent * 100).toInt()}% Done',
                  style: TextStyle(
                    color: percent >= 1.0 ? Colors.green : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 12,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                  percent >= 1.0 ? Colors.green : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$completed of $target questions solved today',
              style: TextStyle(color: AppColors.adaptiveSubtleText(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartStudyPlan(
    BuildContext context,
    List<Topic> weakTopics,
    UserPreferences prefs,
  ) {
    final batchSubtitle = prefs.batch != null
        ? 'Your ${prefs.batch} syllabus • '
              '${prefs.dailyCommitmentMinutes ?? 60} min/day • focus on these topics:'
        : 'Based on your performance, focus on these topics today:';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Study Plan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.adaptiveText(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          batchSubtitle,
          style: TextStyle(
            color: AppColors.adaptiveSubtleText(context),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        if (weakTopics.isEmpty)
          _buildEmptyState(
            context,
            'You\'re doing great! Keep practicing to identify focus areas.',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: weakTopics.length.clamp(0, 5),
            itemBuilder: (context, index) {
              final topic = weakTopics[index];
              return _buildTopicTaskCard(context, topic);
            },
          ),
      ],
    );
  }

  Widget _buildTopicTaskCard(BuildContext context, Topic topic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.adaptiveSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.adaptiveDivider(context)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.priority_high, color: Colors.red, size: 20),
        ),
        title: Text(
          topic.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.adaptiveText(context),
          ),
        ),
        subtitle: Text(
          'Accuracy < 50% • Recommended: 10 Questions',
          style: TextStyle(color: AppColors.adaptiveSubtleText(context)),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: AppColors.adaptiveSubtleText(context),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TopicDetailScreen(
                topic: topic,
                subjectName: 'Review',
                chapterName: 'Smart Plan',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingMilestones(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(userProgressProvider);
    final streak = progress.currentStreak;
    final stats = ref.watch(overallStatsProvider);
    final accuracy = stats['accuracy'] as double;

    return FutureBuilder<int>(
      future: _loadTargetScore(),
      builder: (context, snapshot) {
        final targetScore = snapshot.data ?? 650;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Milestones',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.adaptiveText(context),
              ),
            ),
            const SizedBox(height: 16),
            _buildMilestoneCard(
              context,
              title: 'Target Score',
              subtitle: '$targetScore points goal',
              icon: Icons.flag,
              color: Colors.teal,
            ),
            const SizedBox(height: 12),
            _buildMilestoneCard(
              context,
              title: 'Current Accuracy',
              subtitle: '${accuracy.toStringAsFixed(0)}% accuracy',
              icon: Icons.track_changes,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildMilestoneCard(
              context,
              title: 'Streak Hunter',
              subtitle: '$streak Day Current Streak',
              icon: Icons.local_fire_department,
              color: Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Future<int> _loadTargetScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('neet_target_score') ?? 650;
  }

  Widget _buildMilestoneCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.adaptiveText(context),
                ),
              ),
              Text(subtitle, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.adaptiveSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adaptiveDivider(context)),
      ),
      child: Column(
        children: [
          const Icon(Icons.stars, color: Colors.amber, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.adaptiveSubtleText(context)),
          ),
        ],
      ),
    );
  }
}
