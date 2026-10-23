import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/exam_engine_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final rawName = (user?.fullName ?? user?.username ?? 'Student').trim();
    final name = rawName.isEmpty ? 'Student' : rawName.split(' ').first;
    final stats = ref.watch(overallStatsProvider);
    final streak = ref.watch(
      userProgressProvider.select((s) => s.currentStreak),
    );
    final dailyGoal = ref.watch(dailyGoalProvider);
    final dueCount = ref.watch(dueCardsProvider).valueOrNull?.length ?? 0;
    final completed = dailyGoal['completed'] as int;
    final target = dailyGoal['target'] as int;
    final accuracy = (stats['accuracy'] as num).toDouble();
    final attempted = stats['totalAttempted'];
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AdaptiveColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Your profile',
                  onPressed: () => context.go('/you'),
                  icon: const Icon(Icons.person_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _TodayActionCard(
              completed: completed,
              target: target,
              onTap: () => context.push('/study-plan'),
            ),
            if (dueCount > 0) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.replay_rounded),
                  title: Text('$dueCount cards ready to review'),
                  subtitle: const Text('A quick review helps it stick.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/study'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const _ResumeMockCard(),
            const SizedBox(height: 24),
            Text(
              'A little progress adds up.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.show_chart_rounded),
                title: Text(
                  '${accuracy.toStringAsFixed(0)}% practice accuracy',
                ),
                subtitle: Text(
                  '$attempted questions attempted · $streak day streak',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go('/you'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Featured Subjects',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final subject in const [
              (name: 'Physics', id: 'phys', color: SubjectColors.physics),
              (name: 'Chemistry', id: 'chem', color: SubjectColors.chemistry),
              (
                name: 'Biology (Botany)',
                id: 'bot',
                color: SubjectColors.biology,
              ),
              (
                name: 'Biology (Zoology)',
                id: 'zoo',
                color: SubjectColors.biologyDark,
              ),
            ])
              Card(
                child: ListTile(
                  leading: Icon(Icons.science, size: 24, color: subject.color),
                  title: Text(subject.name),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(
                    '/subjects/${subject.id}?subjectName=${subject.name}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TodayActionCard extends StatelessWidget {
  final int completed;
  final int target;
  final VoidCallback onTap;

  const _TodayActionCard({
    required this.completed,
    required this.target,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (completed / target).clamp(0.0, 1.0);
    return Material(
      color: AppColors.brandNavy,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR NEXT STEP',
                style: TextStyle(
                  color: Color(0xFF9CCBCB),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Today's study plan",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$completed of $target minutes completed',
                style: const TextStyle(color: Color(0xFFD5E1EA), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: .18),
                  color: AppColors.brandTeal,
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Text(
                    'Start studying',
                    style: TextStyle(
                      color: Color(0xFF082B3C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Color(0xFF082B3C),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumeMockCard extends ConsumerWidget {
  const _ResumeMockCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkpoint = ref.watch(activeCbtCheckpointProvider).valueOrNull;
    if (checkpoint == null) return const SizedBox.shrink();
    final answered = checkpoint.answersByIndex.values
        .where((answer) => answer != null && answer.isNotEmpty)
        .length;
    final total = checkpoint.sectionQuestionIds.fold<int>(
      0,
      (sum, ids) => sum + ids.length,
    );
    final remaining = checkpoint.remainingSecondsAt(DateTime.now());
    final minutes = (remaining / 60).ceil();

    return Card(
      child: ListTile(
        leading: const Icon(Icons.play_circle_outline_rounded),
        title: const Text('Continue your mock'),
        subtitle: Text(
          '$answered of $total answered · about $minutes min left',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          final questions = ref.read(allQuestionsProvider).valueOrNull ?? [];
          final pool = ExamEngineService.validatePool(questions);
          context.push(
            '/cbt',
            extra: {
              'config': checkpoint.config,
              'questionPool': pool,
              'resumeCheckpoint': checkpoint,
            },
          );
        },
      ),
    );
  }
}
