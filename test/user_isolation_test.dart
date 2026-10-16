import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/database/question_repository.dart';

/// Isolation matrix for user-owned data.
///
/// The release gate is: an authenticated user must not be able to read or
/// mutate another user's rows. Ownership is keyed on `user_id`, so a DAO that
/// takes a `userId` must scope every read *and* every delete — a silent
/// `userId = -1` default turns an authenticated user's write into a mutation of
/// the guest bucket.
///
/// These tests pin both halves:
///   * reads are scoped, so User A never sees User B's rows;
///   * deletes are scoped, so User A never removes User B's rows.
///
/// Note on drift's `.insert()` factory: a column that is non-nullable *and* has
/// no default is emitted as `required Value<T>` rather than `required T`, so the
/// caller must consciously choose a value (possibly `Value(null)`). Nullable
/// columns stay optional. That asymmetry is deliberate in drift and is why the
/// wrappers below are not uniform.
void main() {
  late AppDatabase db;
  late int userA;
  late int userB;

  Future<void> seedQuestion(String id) async {
    await db
        .into(db.questions)
        .insert(
          QuestionsCompanion.insert(
            id: id,
            subject: 'Physics',
            chapter: 'Mechanics',
            topic: 'Newton',
            questionText: 'Question $id?',
            options: 'A|||B|||C|||D',
            correctAnswer: 'A',
            topicId: const Value('phy_01'),
            difficulty: const Value('Easy'),
            tags: const Value(''),
            type: const Value('mcq'),
          ),
        );
  }

  Future<void> seedBookmark(int userId) async {
    await db.insertBookmark(
      BookmarksCompanion.insert(
        userId: userId,
        questionId: 'q_shared',
        subject: 'Physics',
        topicId: 'phy_01',
        bookmarkedAt: DateTime.now(),
      ),
    );
  }

  Future<void> seedAttempt(int userId, {required int score}) async {
    await db.insertQuizAttempt(
      QuizAttemptsCompanion.insert(
        topicId: 'mock_test',
        subject: 'NEET',
        score: score,
        totalQuestions: 180,
        timeSpentSeconds: 3600,
        attemptedAt: DateTime.now(),
        selectedAnswers: '[]',
        userId: Value(userId),
        incorrectCount: const Value(10),
      ),
    );
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await seedQuestion('q_shared');
    userA = (await db.registerUser(
      UsersCompanion.insert(
        email: const Value('a@example.com'),
        username: 'user_a',
        passwordHash: const Value(r'pbkdf2-sha256$1$aaaa$bbbb'),
      ),
    ))!.id;
    userB = (await db.registerUser(
      UsersCompanion.insert(
        email: const Value('b@example.com'),
        username: 'user_b',
        passwordHash: const Value(r'pbkdf2-sha256$1$aaaa$bbbb'),
      ),
    ))!.id;
  });

  tearDown(() async {
    await db.close();
  });

  group('Bookmarks are scoped per user', () {
    setUp(() => seedBookmark(userA));

    test('User A sees only their own bookmark', () async {
      expect((await db.getAllBookmarks(userId: userA)).length, 1);
      expect(await db.getAllBookmarks(userId: userB), isEmpty);
    });

    test('isBookmarked is scoped, so B is not told A bookmarked it', () async {
      expect(await db.isBookmarked('q_shared', userId: userA), isTrue);
      expect(await db.isBookmarked('q_shared', userId: userB), isFalse);
    });

    test('B bookmarking the same question does not displace A', () async {
      await seedBookmark(userB);

      expect((await db.getAllBookmarks(userId: userA)).length, 1);
      expect((await db.getAllBookmarks(userId: userB)).length, 1);
    });

    test('B removing a bookmark leaves A intact', () async {
      // The cross-user mutation hazard: an unscoped delete would remove the
      // other user's row and write into the guest bucket instead.
      await db.removeBookmark('q_shared', userId: userB);

      expect(await db.isBookmarked('q_shared', userId: userA), isTrue);
      expect(await db.getAllBookmarks(userId: userB), isEmpty);
    });
  });

  group('Quiz attempts are scoped per user', () {
    setUp(() => seedAttempt(userA, score: 100));

    test('User A sees only their own attempts', () async {
      expect((await db.getAllQuizAttempts(userId: userA)).length, 1);
      expect(await db.getAllQuizAttempts(userId: userB), isEmpty);
    });

    test('a second user\'s attempt does not merge into the first', () async {
      await seedAttempt(userB, score: 40);

      final aAttempts = await db.getAllQuizAttempts(userId: userA);
      final bAttempts = await db.getAllQuizAttempts(userId: userB);

      expect(aAttempts.single.score, 100);
      expect(bAttempts.single.score, 40);
    });
  });

  group('Topic progress is scoped per user', () {
    test('progress rows do not leak across accounts', () async {
      await db.upsertTopicProgress(
        TopicProgressEntriesCompanion.insert(
          userId: userA,
          topicId: 'phy_01',
          lastAttempted: DateTime.now(),
          questionsAttempted: const Value(10),
          questionsCorrect: const Value(8),
        ),
      );

      expect((await db.getAllTopicProgress(userId: userA)).length, 1);
      expect(await db.getAllTopicProgress(userId: userB), isEmpty);
    });

    test('upserting for B does not overwrite A', () async {
      await db.upsertTopicProgress(
        TopicProgressEntriesCompanion.insert(
          userId: userA,
          topicId: 'phy_01',
          lastAttempted: DateTime.now(),
          questionsAttempted: const Value(10),
          questionsCorrect: const Value(8),
        ),
      );
      await db.upsertTopicProgress(
        TopicProgressEntriesCompanion.insert(
          userId: userB,
          topicId: 'phy_01',
          lastAttempted: DateTime.now(),
          questionsAttempted: const Value(3),
          questionsCorrect: const Value(1),
        ),
      );

      expect(
        (await db.getAllTopicProgress(userId: userA)).single.questionsCorrect,
        8,
      );
      expect(
        (await db.getAllTopicProgress(userId: userB)).single.questionsCorrect,
        1,
      );
    });
  });

  group('Spaced repetition is scoped per user', () {
    test('cards do not leak across accounts', () async {
      await db.upsertSpacedRepetition(
        SpacedRepetitionCompanion.insert(
          questionId: 'q_shared',
          dueAt: DateTime.now(),
          userId: Value(userA),
          box: const Value(2),
        ),
      );

      expect((await db.getSpacedRepetitionCards(userId: userA)).length, 1);
      expect(await db.getSpacedRepetitionCards(userId: userB), isEmpty);
    });
  });

  group('Account deletion is scoped', () {
    test('deleting User A leaves User B fully intact', () async {
      for (final uid in [userA, userB]) {
        await seedBookmark(uid);
        await seedAttempt(uid, score: 50);
      }

      await db.clearAllUserData(userA);

      expect(await db.getAllBookmarks(userId: userA), isEmpty);
      expect(await db.getAllQuizAttempts(userId: userA), isEmpty);
      expect(await db.getUserById(userA), isNull);

      // User B must be completely unaffected.
      expect((await db.getAllBookmarks(userId: userB)).length, 1);
      expect((await db.getAllQuizAttempts(userId: userB)).length, 1);
      expect(await db.getUserById(userB), isNotNull);
    });
  });

  group('The shared catalog is not user-owned', () {
    test('deleting a user does not remove shared questions', () async {
      await db.clearAllUserData(userA);

      final remaining = await QuestionRepository(db).getAllQuestionsFromDb();
      expect(remaining.any((q) => q.id == 'q_shared'), isTrue);
    });
  });
}
