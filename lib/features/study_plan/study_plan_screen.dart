import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/subject_model.dart';
import '../topic_browser/topic_detail_screen.dart';

class StudyPlanScreen extends ConsumerWidget {
  const StudyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weakTopics = ref.watch(weakTopicsProvider);
    final dailyGoal = ref.watch(dailyGoalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDailyGoalStatus(context, dailyGoal),
            const SizedBox(height: 24),
            _buildSmartStudyPlan(context, weakTopics),
            const SizedBox(height: 24),
            _buildUpcomingMilestones(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoalStatus(BuildContext context, Map<String, dynamic> goal) {
    final percent = goal['percent'] as double;
    final completed = goal['completed'] as int;
    final target = goal['target'] as int;

    return Card(
      elevation: 0,
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
                const Text(
                  'Today\'s Goal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                valueColor: AlwaysStoppedAnimation(percent >= 1.0 ? Colors.green : AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$completed of $target questions solved today',
              style: const TextStyle(color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartStudyPlan(BuildContext context, List<Topic> weakTopics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Smart Study Plan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          'Based on your performance, focus on these topics today:',
          style: TextStyle(color: AppColors.secondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        if (weakTopics.isEmpty)
          _buildEmptyState(context, 'You\'re doing great! Keep practicing to identify focus areas.')
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider),
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Accuracy < 50% • Recommended: 10 Questions'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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

  Widget _buildUpcomingMilestones(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Milestones',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        _buildMilestoneCard(
          context,
          title: 'NEET 2026 Countdown',
          subtitle: '342 Days Remaining',
          icon: Icons.event,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildMilestoneCard(
          context,
          title: 'Streak Hunter',
          subtitle: '3 Day Current Streak',
          icon: Icons.local_fire_department,
          color: Colors.orange,
        ),
      ],
    );
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.stars, color: Colors.amber, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}
