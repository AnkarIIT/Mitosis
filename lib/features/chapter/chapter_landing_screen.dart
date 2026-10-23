library chapter_landing_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/chapter_model.dart';
import '../../core/providers/providers.dart';
import '../../core/services/chapter_service.dart';
import '../../core/theme/app_theme.dart';

class ChapterLandingScreen extends ConsumerWidget {
  final String chapterId;

  const ChapterLandingScreen({super.key, required this.chapterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapter = ChapterService.getChapter(chapterId);
    if (chapter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chapter Not Found')),
        body: const Center(child: Text('Chapter not found')),
      );
    }

    final progressAsync = ref.watch(chapterProgressProvider(chapterId));

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      appBar: AppBar(
        title: Text(chapter.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading progress: $e')),
        data: (ChapterProgress? progress) {
          final completedCount = progress?.completedLessonIds.length ?? 0;
          final totalLessons = chapter.lessons.length;
          final progressFraction = totalLessons > 0
              ? completedCount / totalLessons
              : 0.0;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _subjectColor(chapter.subject).withValues(alpha: 0.9),
                        _subjectColor(chapter.subject).withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progress',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$completedCount / $totalLessons lessons',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Progress circle
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    value: progressFraction,
                                    strokeWidth: 6,
                                    backgroundColor: Colors.white24,
                                    valueColor: const AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(progressFraction * 100).round()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$completedCount/${chapter.lessons.length} lessons',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Meta info
                      Row(
                        children: [
                          _buildMetaChip(
                            Icons.timer_outlined,
                            '${chapter.totalEstimatedMinutes} min',
                          ),
                          const SizedBox(width: 12),
                          _buildMetaChip(
                            Icons.menu_book_outlined,
                            '${chapter.lessons.length} lessons',
                          ),
                          const SizedBox(width: 12),
                          _buildMetaChip(
                            Icons.quiz_outlined,
                            '${chapter.summaryQuiz.length} quiz Qs',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Lessons list
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList.separated(
                  itemCount: chapter.lessons.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final lesson = chapter.lessons[index];
                    final isCompleted =
                        progress?.completedLessonIds.contains(lesson.id) ??
                        false;
                    final isCurrent = progress?.currentLessonId == lesson.id;

                    return _buildLessonTile(
                      context,
                      chapter,
                      lesson,
                      isCompleted,
                      isCurrent,
                    );
                  },
                ),
              ),

              // Summary quiz action
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.quiz_outlined),
                      label: const Text('Take Chapter Quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _subjectColor(chapter.subject),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () =>
                          context.push('/chapter/${chapter.id}/quiz'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonTile(
    BuildContext context,
    Chapter chapter,
    Lesson lesson,
    bool isCompleted,
    bool isCurrent,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              context.push('/chapter/${chapter.id}/lesson/${lesson.id}'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                // Status icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: AdaptiveColors.textSecondary(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Lesson info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${lesson.order}. ${lesson.title}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AdaptiveColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: AdaptiveColors.textSecondary(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${lesson.estimatedMinutes} min',
                            style: TextStyle(
                              color: AdaptiveColors.textSecondary(context),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (lesson.quickChecks.isNotEmpty) ...[
                            Icon(
                              Icons.quiz_outlined,
                              size: 14,
                              color: AdaptiveColors.textSecondary(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${lesson.quickChecks.length} Qs',
                              style: TextStyle(
                                fontSize: 12,
                                color: AdaptiveColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _subjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'physics':
        return const Color(0xFF1E88E5);
      case 'chemistry':
        return const Color(0xFFE53935);
      case 'biology':
      case 'botany':
      case 'zoology':
        return const Color(0xFF009688);
      default:
        return const Color(0xFF1E88E5);
    }
  }
}
