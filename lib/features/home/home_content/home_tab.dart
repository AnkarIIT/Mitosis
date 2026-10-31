import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/models/learning_recommendation.dart';
import '../../../core/services/exam_engine_service.dart';
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
    final attempted = (stats['totalAttempted'] as num).toInt();
    final recommendations = ref.watch(learningRecommendationsProvider);
    final recommendation = attempted == 0 || recommendations.isEmpty
        ? null
        : recommendations.first;
    final dailyGoal = ref.watch(dailyGoalProvider);
    final hasChosenDailyCommitment = ref
        .watch(userPreferencesProvider)
        .dailyCommitmentMinutes != null;
    final dueCount = ref.watch(dueCardsProvider).valueOrNull?.length ?? 0;
    final completed = dailyGoal['completed'] as int;
    final target = hasChosenDailyCommitment
        ? dailyGoal['target'] as int
        : null;
    final subjects = ref.watch(subjectsProvider);
    final accuracy = (stats['accuracy'] as num).toDouble();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AdaptiveColors.textSecondary(
                                      context,
                                    ),
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
                  const SizedBox(height: 28),
                  _TodayActionCard(
                    completed: completed,
                    target: target,
                    title: recommendation == null
                        ? attempted == 0
                              ? 'Start with one question'
                              : 'Choose your next study session'
                        : '${recommendation.primaryAction == LearningActionType.revise ? 'Revise' : 'Practice'} ${recommendation.topicName}',
                    supportingText: recommendation == null
                        ? target == null
                              ? 'Pick a subject and study at your own pace.'
                              : '$completed of $target questions practiced today'
                        : '${recommendation.subject} · Suggested from your practice history',
                    actionLabel: recommendation == null
                        ? 'Browse subjects'
                        : recommendation.primaryAction ==
                              LearningActionType.revise
                        ? 'Open revision'
                        : 'Practice this topic',
                    onTap: () {
                      if (recommendation == null) {
                        context.go('/study');
                      } else if (recommendation.primaryAction ==
                          LearningActionType.revise) {
                        context.push(
                          '/resources/notes?chapterId='
                          '${Uri.encodeComponent(recommendation.chapterId)}',
                        );
                      } else {
                        context.push(
                          '/quiz?topicId=${Uri.encodeComponent(recommendation.topicId)}'
                          '&topicName=${Uri.encodeComponent(recommendation.topicName)}'
                          '&subject=${Uri.encodeComponent(recommendation.subject)}',
                        );
                      }
                    },
                  ),
                  if (dueCount > 0) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.replay_rounded),
                        title: Text('$dueCount cards ready to review'),
                        subtitle: const Text('A quick review helps it stick.'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.go('/study?section=review'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const _ResumeMockCard(),
                  if (attempted == 0) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Start with a subject',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (var index = 0;
                            index < subjects.length && index < 3;
                            index++) ...[
                          if (index > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _QuickStartSubjectButton(
                              name: subjects[index].name,
                              subjectId: subjects[index].id,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    Text(
                      'Your progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.insights_outlined),
                        title: Text(
                          '${accuracy.toStringAsFixed(0)}% practice accuracy',
                        ),
                        subtitle: Text('All time · Across $attempted questions'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.go('/you'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayActionCard extends StatelessWidget {
  final int completed;
  final int? target;
  final String title;
  final String supportingText;
  final String actionLabel;
  final VoidCallback onTap;

  const _TodayActionCard({
    required this.completed,
    required this.target,
    required this.title,
    required this.supportingText,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target == null || target! <= 0
        ? 0.0
        : (completed / target!).clamp(0.0, 1.0);
    return Material(
      color: AdaptiveColors.primary(context),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your next step',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AdaptiveColors.onPrimary(context).withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                supportingText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AdaptiveColors.onPrimary(context).withValues(alpha: 0.88),
                ),
              ),
              if (target != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: .18),
                    color: AdaptiveColors.onPrimary(context),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    actionLabel,
                    style: TextStyle(
                      color: AdaptiveColors.onPrimary(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AdaptiveColors.onPrimary(context),
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

class _QuickStartSubjectButton extends StatelessWidget {
  final String name;
  final String subjectId;

  const _QuickStartSubjectButton({required this.name, required this.subjectId});

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () => context.push(
      '/subjects/$subjectId?subjectName=${Uri.encodeComponent(name)}',
    ),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    child: Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium,
    ),
  );
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
