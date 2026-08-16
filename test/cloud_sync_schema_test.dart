import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/database/drift_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Cloud Sync Schema (v17)', () {
    test('local writes are stamped with an updated_at timestamp', () async {
      final attemptedAt = DateTime.now();
      await db.insertQuizAttempt(QuizAttemptsCompanion.insert(
        topicId: 'phy1',
        subject: 'Physics',
        score: 1,
        totalQuestions: 2,
        timeSpentSeconds: 30,
        attemptedAt: attemptedAt,
        selectedAnswers: '["A"]',
      ));

      await db.upsertTopicProgress(TopicProgressEntriesCompanion.insert(
        topicId: 'phy1',
        lastAttempted: DateTime.now(),
      ));

      await db.insertBookmark(BookmarksCompanion.insert(
        questionId: 101,
        subject: 'Physics',
        topicId: 'phy1',
        bookmarkedAt: DateTime.now(),
      ));

      final attempts = await db.getAllQuizAttempts();
      final progress = await db.getAllTopicProgress();
      final bookmarks = await db.getAllBookmarks();

      expect(attempts.single.updatedAt, isNotNull);
      expect(progress.single.updatedAt, isNotNull);
      expect(bookmarks.single.updatedAt, isNotNull);
    });

    test('bookmarks are idempotent across repeated upserts', () async {
      final now = DateTime.now();
      await db.insertBookmark(BookmarksCompanion.insert(
        questionId: 101,
        subject: 'Botany',
        topicId: 'bio1',
        bookmarkedAt: now,
      ));
      await db.insertBookmark(BookmarksCompanion.insert(
        questionId: 101,
        subject: 'Botany',
        topicId: 'bio1',
        bookmarkedAt: now.add(const Duration(hours: 1)),
      ));
      await db.insertBookmark(BookmarksCompanion.insert(
        questionId: 202,
        subject: 'Zoology',
        topicId: 'zoo2',
        bookmarkedAt: now,
      ));

      final rows = await db.getAllBookmarks();
      expect(rows.length, 2);
      expect(rows.map((b) => b.questionId).toSet(), {101, 202});
    });

    test('upsertQuizAttempt updates duplicate rows without throwing', () async {
      final at = DateTime.now();
      await db.into(db.quizAttempts).insert(QuizAttemptsCompanion.insert(
            topicId: 'bio1',
            subject: 'Botany',
            score: 3,
            totalQuestions: 5,
            timeSpentSeconds: 60,
            attemptedAt: at,
            selectedAnswers: '["A"]',
          ));
      await db.into(db.quizAttempts).insert(QuizAttemptsCompanion.insert(
            topicId: 'bio1',
            subject: 'Botany',
            score: 4,
            totalQuestions: 5,
            timeSpentSeconds: 70,
            attemptedAt: at,
            selectedAnswers: '["A","B"]',
          ));

      // Two rows share attempted_at (a state the old schema could reach).
      // This must not throw a "multiple rows" StateError.
      await db.upsertQuizAttempt(QuizAttemptsCompanion.insert(
        topicId: 'bio1',
        subject: 'Botany',
        score: 5,
        totalQuestions: 5,
        timeSpentSeconds: 80,
        attemptedAt: at,
        selectedAnswers: '["A","B","C"]',
        updatedAt: Value(DateTime.now()),
      ));

      final rows = await db.getAllQuizAttempts();
      expect(rows.length, 2);
      expect(rows.every((r) => r.score == 5), isTrue);
    });

    test('topic progress upsert keeps a single row per topic', () async {
      await db.upsertTopicProgress(TopicProgressEntriesCompanion.insert(
        topicId: 'chem1',
        questionsAttempted: const Value(2),
        questionsCorrect: const Value(1),
        lastAttempted: DateTime.now(),
      ));
      await db.upsertTopicProgress(TopicProgressEntriesCompanion.insert(
        topicId: 'chem1',
        questionsAttempted: const Value(4),
        questionsCorrect: const Value(3),
        lastAttempted: DateTime.now(),
      ));

      final rows = await db.getAllTopicProgress();
      expect(rows.length, 1);
      expect(rows.single.questionsAttempted, 4);
      expect(rows.single.questionsCorrect, 3);
    });
  });
}
