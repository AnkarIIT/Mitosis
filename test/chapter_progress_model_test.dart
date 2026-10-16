import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/chapter_model.dart';

/// Locks the two `chapter_model` defects that were live traps for any future
/// caller: a `progressFraction` that always reported 0.0 regardless of what
/// had been completed, and a `copyWith` that could never clear `completedAt`.
void main() {
  ChapterProgress progress({
    Set<String> completed = const {},
    String currentLessonId = '',
    DateTime? completedAt,
  }) {
    final now = DateTime(2026, 1, 1);
    return ChapterProgress(
      chapterId: 'phy_ch1',
      userId: 1,
      currentLessonId: currentLessonId,
      completedLessonIds: completed,
      quickCheckScores: const {},
      summaryQuizScore: -1,
      startedAt: now,
      lastAccessedAt: now,
      completedAt: completedAt,
    );
  }

  group('progressFraction', () {
    test('reflects completed lessons against the supplied total', () {
      expect(progress().progressFraction(4), 0.0);
      expect(progress(completed: {'l1'}).progressFraction(4), 0.25);
      expect(progress(completed: {'l1', 'l2'}).progressFraction(4), 0.5);
    });

    test('clamps rather than exceeding 1.0', () {
      // Over-completion (catalog changed) must not produce a >1 progress bar.
      expect(progress(completed: {'a', 'b', 'c'}).progressFraction(2), 1.0);
    });

    test('is safe when the total is unknown or zero', () {
      // A hardcoded 0.0 used to be returned here regardless of input.
      expect(progress(completed: {'l1'}).progressFraction(0), 0.0);
      expect(progress(completed: {'l1'}).progressFraction(-3), 0.0);
    });
  });

  group('copyWith completedAt', () {
    test('clearCompletedAt removes completion', () {
      final done = progress(completedAt: DateTime(2026, 2, 2));
      expect(done.isCompleted, isTrue);
      expect(done.copyWith(clearCompletedAt: true).completedAt, isNull);
      expect(done.copyWith(clearCompletedAt: true).isCompleted, isFalse);
    });

    test('an explicit completedAt sets it', () {
      final at = DateTime(2026, 3, 3);
      expect(progress().copyWith(completedAt: at).completedAt, at);
    });

    test('omitting both leaves it unchanged', () {
      final at = DateTime(2026, 2, 2);
      expect(
        progress(completedAt: at).copyWith(summaryQuizScore: 90).completedAt,
        at,
      );
    });

    test('clearCompletedAt wins over a passed completedAt', () {
      final at = DateTime(2026, 2, 2);
      expect(
        progress()
            .copyWith(completedAt: at, clearCompletedAt: true)
            .completedAt,
        isNull,
      );
    });
  });

  group('firstLessonToResume', () {
    const List<Lesson> lessons = [
      Lesson(
        id: 'l1',
        title: 'One',
        order: 1,
        content: '',
        workedExample: '',
        misconception: '',
        quickChecks: [],
        ncertPage: 1,
        ncertSection: '1.1',
        estimatedMinutes: 10,
      ),
      Lesson(
        id: 'l2',
        title: 'Two',
        order: 2,
        content: '',
        workedExample: '',
        misconception: '',
        quickChecks: [],
        ncertPage: 2,
        ncertSection: '1.1',
        estimatedMinutes: 10,
      ),
      Lesson(
        id: 'l3',
        title: 'Three',
        order: 3,
        content: '',
        workedExample: '',
        misconception: '',
        quickChecks: [],
        ncertPage: 3,
        ncertSection: '1.1',
        estimatedMinutes: 10,
      ),
    ];

    final chapter = Chapter(
      id: 'phy_ch1',
      subject: 'Physics',
      classLevel: 'Class 11',
      chapterNumber: 1,
      title: 'Physical World',
      learningOutcomes: const [],
      estimatedMinutes: 30,
      lessons: lessons,
      pdfEntryId: 'x.pdf',
      summaryQuiz: const [],
    );

    test('starts at the first lesson with no progress', () {
      expect(chapter.firstLessonToResume()?.id, 'l1');
    });

    test('resumes at the recorded current lesson', () {
      final p = progress(currentLessonId: 'l2');
      expect(chapter.firstLessonToResume(p)?.id, 'l2');
    });

    test('skips lessons already completed', () {
      final p = progress(completed: {'l1'});
      expect(chapter.firstLessonToResume(p)?.id, 'l2');
    });

    test('falls back to the first when progress is unusable', () {
      // currentLessonId no longer in the catalog.
      final p = progress(currentLessonId: 'gone', completed: {'l1', 'l2'});
      expect(chapter.firstLessonToResume(p)?.id, 'l3');
    });

    test('handles a chapter with no lessons', () {
      final empty = Chapter(
        id: 'x',
        subject: 'Physics',
        classLevel: 'Class 11',
        chapterNumber: 1,
        title: 'x',
        learningOutcomes: const [],
        estimatedMinutes: 1,
        lessons: const [],
        pdfEntryId: '',
        summaryQuiz: const [],
      );
      expect(empty.firstLessonToResume(), isNull);
    });
  });
}
