import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class TopicBrowserScreen extends ConsumerWidget {
  final String subjectId;
  final String subjectName;

  const TopicBrowserScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(chaptersProvider(subjectId));

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      appBar: AppBar(
        title: Text(subjectName),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: AdaptiveColors.textPrimary(context)),
        titleTextStyle: TextStyle(
          color: AdaptiveColors.textPrimary(context),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: chapters.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: AppColors.secondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chapters available',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.secondary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    color: AdaptiveColors.surface(context),
                    child: ExpansionTile(
                      title: Text(
                        chapter.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: AdaptiveColors.textPrimary(context),
                            ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.topic,
                              size: 14,
                              color: AdaptiveColors.textSecondary(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${chapter.topics.length} topics',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AdaptiveColors.textSecondary(
                                      context,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      collapsedBackgroundColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      iconColor: AppColors.primary,
                      collapsedIconColor: AdaptiveColors.textSecondary(context),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            children: [
                              ...chapter.topics.map((topic) {
                                final topicQuestions =
                                    ref
                                        .watch(
                                          questionsForTopicProvider(topic.id),
                                        )
                                        .valueOrNull ??
                                    [];
                                final progress = ref
                                    .watch(userProgressProvider)
                                    .topicProgress[topic.id];
                                final isCompleted =
                                    progress?.isCompleted ?? false;
                                final accuracy = progress?.accuracy ?? 0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AdaptiveColors.background(context),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          context.push(
                                            '/topic/${topic.id}?subjectName=${Uri.encodeComponent(subjectName)}&chapterName=${Uri.encodeComponent(chapter.name)}',
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              // Leading icon
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isCompleted
                                                      ? AppColors.primary
                                                            .withValues(
                                                              alpha: 0.2,
                                                            )
                                                      : AppColors.secondary
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                ),
                                                child: Center(
                                                  child: isCompleted
                                                      ? const Icon(
                                                          Icons.check_circle,
                                                          color:
                                                              AppColors.primary,
                                                          size: 24,
                                                        )
                                                      : Text(
                                                          topicQuestions.length
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                AdaptiveColors.textPrimary(
                                                                  context,
                                                                ),
                                                          ),
                                                        ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Title and subtitle
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      topic.name,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                AdaptiveColors.textPrimary(
                                                                  context,
                                                                ),
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .help_outline_rounded,
                                                          size: 12,
                                                          color:
                                                              AdaptiveColors.textPrimary(
                                                                context,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '${topicQuestions.length} questions',
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color:
                                                                    AdaptiveColors.textPrimary(
                                                                      context,
                                                                    ),
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Accuracy badge
                                              if (accuracy > 0)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: accuracy >= 70
                                                        ? AppColors.primary
                                                              .withValues(
                                                                alpha: 0.15,
                                                              )
                                                        : AppColors.secondary
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    border: Border.all(
                                                      color: accuracy >= 70
                                                          ? AppColors.primary
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                )
                                                          : AppColors.secondary
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '${accuracy.toStringAsFixed(0)}%',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: accuracy >= 70
                                                          ? AppColors.primary
                                                          : AppColors.secondary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(width: 8),
                                              // Trailing arrow
                                              Icon(
                                                Icons.chevron_right,
                                                color: AppColors.secondary
                                                    .withValues(alpha: 0.5),
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
