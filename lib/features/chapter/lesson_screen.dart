library lesson_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/models/chapter_model.dart';
import '../../core/providers/current_user_provider.dart';
import '../../core/providers/providers.dart';
import '../../core/services/chapter_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class LessonScreen extends ConsumerWidget {
  final String chapterId;
  final String lessonId;

  const LessonScreen({
    super.key,
    required this.chapterId,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapter = ChapterService.getChapter(chapterId);
    if (chapter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chapter Not Found')),
        body: const Center(child: Text('Chapter not found')),
      );
    }

    // `orElse: throw` inside build() crashed the whole frame. This route is
    // deep-linkable (/chapter/:id/lesson/:lessonId), so a stale or unknown id
    // is reachable â€” and the catalog can change between builds.
    final lessonIndex = chapter.lessons.indexWhere((l) => l.id == lessonId);
    if (lessonIndex < 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lesson Not Found')),
        body: const Center(child: Text('That lesson is no longer available.')),
      );
    }
    final lesson = chapter.lessons[lessonIndex];
    final isFirst = lessonIndex == 0;
    final isLast = lessonIndex == chapter.lessons.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lesson ${lesson.order}: ${lesson.title}'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (chapter.pdfEntryId.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Open NCERT PDF at page ${lesson.ncertPage}',
              onPressed: () => context.push(
                '/pdf?entryId=${Uri.encodeComponent(chapter.pdfEntryId)}',
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Progress indicator
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lesson ${lesson.order} of ${chapter.lessons.length}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AdaptiveColors.textSecondary(context),
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _subjectColor(
                            chapter.subject,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${lesson.estimatedMinutes} min',
                          style: TextStyle(
                            color: _subjectColor(chapter.subject),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      // lessonIndex + 1: Lesson.order is 1-based, so using it
                      // showed lesson 1 of 2 already half-complete.
                      value: (lessonIndex + 1) / chapter.lessons.length,
                      minHeight: 4,
                      backgroundColor: AdaptiveColors.divider(context),
                      valueColor: AlwaysStoppedAnimation(
                        _subjectColor(chapter.subject),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lesson content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AdaptiveColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // NCERT reference
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _subjectColor(
                        chapter.subject,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _subjectColor(
                          chapter.subject,
                        ).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: _subjectColor(chapter.subject),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NCERT Reference',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _subjectColor(chapter.subject),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Section ${lesson.ncertSection} â€¢ Page ${lesson.ncertPage}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AdaptiveColors.textPrimary(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 20,
                          ),
                          onPressed: () => context.push(
                            '/pdf?entryId=${Uri.encodeComponent(chapter.pdfEntryId)}',
                          ),
                          tooltip: 'Open NCERT PDF',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lesson content (Markdown)
                  MarkdownBody(
                    data: lesson.content,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                        .copyWith(
                          p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AdaptiveColors.textPrimary(context),
                            height: 1.6,
                          ),
                          h1: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AdaptiveColors.textPrimary(context),
                              ),
                          h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AdaptiveColors.textPrimary(context),
                          ),
                          h3: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AdaptiveColors.textPrimary(context),
                          ),
                          code: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontFamily: 'monospace',
                                backgroundColor:
                                    AdaptiveColors.surfaceContainerHighest(
                                      context,
                                    ),
                              ),
                          codeblockDecoration: BoxDecoration(
                            color: AdaptiveColors.surfaceContainerHighest(
                              context,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          blockquote: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AdaptiveColors.textSecondary(context),
                                fontStyle: FontStyle.italic,
                              ),
                          blockquoteDecoration: BoxDecoration(
                            color: AdaptiveColors.surfaceContainerHighest(
                              context,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: _subjectColor(chapter.subject),
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Worked Example
                  if (lesson.workedExample.isNotEmpty) ...[
                    _buildCard(
                      context,
                      title: 'Worked Example',
                      icon: Icons.lightbulb_outline_rounded,
                      color: Colors.amber,
                      child: MarkdownBody(
                        data: lesson.workedExample,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(
                              Theme.of(context),
                            ).copyWith(
                              p: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AdaptiveColors.textPrimary(context),
                                    height: 1.5,
                                  ),
                              code: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    backgroundColor:
                                        AdaptiveColors.surfaceContainerHighest(
                                          context,
                                        ),
                                  ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Common Misconception
                  if (lesson.misconception.isNotEmpty) ...[
                    _buildCard(
                      context,
                      title: 'Common Misconception',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.deepOrange,
                      child: Text(
                        lesson.misconception,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AdaptiveColors.textPrimary(context),
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Quick Checks
                  if (lesson.quickChecks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Quick Check',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AdaptiveColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildQuickCheckCards(
                      context,
                      lesson.quickChecks,
                      lesson.id,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // NCERT link at bottom
                  const SizedBox(height: 24),
                  Center(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text('Open NCERT Page ${lesson.ncertPage}'),
                      onPressed: () => context.push(
                        '/pdf?entryId=${Uri.encodeComponent(chapter.pdfEntryId)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(
        context,
        ref,
        chapter,
        lesson,
        isFirst,
        isLast,
      ),
    );
  }

  List<Widget> _buildQuickCheckCards(
    BuildContext context,
    List<QuickCheck> quickChecks,
    String lessonId,
  ) {
    return quickChecks
        .map((qc) => _buildQuickCheckCard(context, qc, lessonId))
        .toList();
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildQuickCheckCard(
    BuildContext context,
    QuickCheck qc,
    String lessonId,
  ) {
    final List<Widget> children = <Widget>[];

    // Add option buttons
    children.addAll(
      qc.options.asMap().entries.map((entry) {
        final idx = entry.key;
        final option = entry.value;
        // correctAnswer is the option TEXT (e.g. 'Weak nuclear'), not an
        // index â€” comparing idx.toString() to it was always false, so the
        // green ring never appeared.
        final isCorrectOption = option == qc.correctAnswer;
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
                      ? Colors.green.withValues(alpha: 0.15)
                      : AdaptiveColors.outlineVariant(context),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + idx),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCorrectOption
                          ? Colors.green
                          : AdaptiveColors.textSecondary(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(option)),
            ],
          ),
        );
      }).toList(),
    );

    // Add explanation if present
    if (qc.explanation.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 10),
        const Divider(),
        const SizedBox(height: 4),
        Text(
          'Explanation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(qc.explanation),
      ]);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        title: Text(
          qc.questionText,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
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

  /// Persists "this lesson is done" so the chapter landing screen's progress
  /// reflects reality. Fire-and-forget from the caller's perspective: a failure
  /// here must never block navigation.
  Future<void> _recordLessonComplete(
    WidgetRef ref,
    Chapter chapter,
    Lesson lesson,
  ) async {
    try {
      final userId = ref.read(currentLocalUserIdProvider) ?? guestOwnerId;
      final db = ref.read(databaseProvider);
      await db.markLessonCompleted(chapter.id, userId, lesson.id);
      await db.updateCurrentLesson(chapter.id, userId, lesson.id);
      ref.invalidate(chapterProgressProvider(chapter.id));
    } catch (e) {
      debugPrint('chapter: failed to record lesson progress: $e');
    }
  }

  Widget _buildBottomNav(
    BuildContext context,
    WidgetRef ref,
    Chapter chapter,
    Lesson lesson,
    bool isFirst,
    bool isLast,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isFirst
                  ? null
                  : () {
                      final prevLesson = chapter.getPreviousLesson(lesson.id);
                      if (prevLesson != null) {
                        // pushReplacement, NOT go: `go` rebuilds the page list
                        // so only one route remains, and the custom back arrow
                        // (which calls context.pop()) then throws
                        // "There is nothing to pop" â€” the only way out of the
                        // screen was broken by navigating forward.
                        context.pushReplacement(
                          '/chapter/${chapter.id}/lesson/${prevLesson.id}',
                        );
                      }
                    },
              child: const Text('Previous'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              // Completing the lesson is recorded BEFORE navigating. Nothing
              // wrote chapter progress anywhere, so the landing screen's
              // "0 / 2 lessons" and 0% bar were dead for every user forever.
              onPressed: isLast
                  ? () async {
                      await _recordLessonComplete(ref, chapter, lesson);
                      if (!context.mounted) return;
                      context.pushReplacement('/chapter/${chapter.id}');
                    }
                  : () async {
                      await _recordLessonComplete(ref, chapter, lesson);
                      final nextLesson = chapter.getNextLesson(lesson.id);
                      if (nextLesson == null || !context.mounted) return;
                      context.pushReplacement(
                        '/chapter/${chapter.id}/lesson/${nextLesson.id}',
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _subjectColor(chapter.subject),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isLast ? 'Finish Lesson' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}
