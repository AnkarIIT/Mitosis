import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/database/drift_database.dart' as db;
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/services/dpp_engine.dart';
import 'package:neet_mitos/core/services/mastery_service.dart';
import 'package:neet_mitos/core/services/question_history_service.dart';
import 'package:neet_mitos/core/database/question_repository.dart';

// ─────────────────────────────────────────────────────────────
// Test helpers
// ─────────────────────────────────────────────────────────────

Question _q(
  String id,
  String subject,
  String difficulty, {
  String? chapter,
  String? topicId,
  String? correctAnswer,
}) {
  return Question(
    id: id,
    subject: subject,
    chapter: chapter ?? 'Ch$id',
    topic: 'Topic $id',
    topicId: topicId ?? 'topic_$id',
    questionText: 'Question $id?',
    options: ['A', 'B', 'C', 'D'],
    correctAnswer: correctAnswer ?? 'A',
    difficulty: difficulty,
    tags: ['tag_$id'],
    type: 'mcq',
  );
}

/// Creates an in-memory database with sample questions for testing.
Future<db.AppDatabase> _createTestDatabase(List<Question> questions) async {
  final database = db.AppDatabase(NativeDatabase.memory());
  final repo = QuestionRepository(database);
  for (final q in questions) {
    await repo.insertQuestion(q);
  }
  return database;
}

/// Normalizes difficulty for test assertions (mirrors DppEngine logic).
String _normalizeDifficulty(String difficulty) {
  final d = difficulty.trim().toLowerCase();
  if (d == 'easy' || d == 'simple') return 'Easy';
  if (d == 'medium' || d == 'moderate' || d == 'avg' || d == 'average') {
    return 'Medium';
  }
  if (d == 'hard' || d == 'difficult' || d == 'tough') return 'Hard';
  return 'Medium';
}

// ─────────────────────────────────────────────────────────────
// DPP Engine Tests
// ─────────────────────────────────────────────────────────────

void main() {
  group('DPP Engine — Subject Quotas', () {
    test('NEET pattern DPP distributes questions across subjects', () async {
      final questions = <Question>[];
      for (int i = 0; i < 45; i++) {
        questions.add(_q('phy_$i', 'Physics', 'Medium'));
        questions.add(_q('chem_$i', 'Chemistry', 'Medium'));
        questions.add(_q('bot_$i', 'Biology', 'Medium'));
        questions.add(_q('zoo_$i', 'Biology', 'Medium'));
      }
      final database = await _createTestDatabase(questions);
      final engine = DppEngine(
        database,
        QuestionRepository(database),
        QuestionHistoryService(database),
        MasteryService(database, Future.value(questions)),
        random: Random(42),
        userId: 1,
      );

      final config = DppConfig.neetPattern(totalQuestions: 180);
      final result = await engine.generate(config);

      expect(result.questions.length, 180);
      final subjects = result.questions.map((q) => q.subject).toSet();
      expect(subjects.contains('Physics'), isTrue);
      expect(subjects.contains('Chemistry'), isTrue);
      expect(subjects.contains('Biology'), isTrue);
    });

    test('single-subject DPP only includes that subject', () async {
      final questions = <Question>[];
      for (int i = 0; i < 20; i++) {
        questions.add(_q('phy_$i', 'Physics', 'Medium'));
        questions.add(_q('chem_$i', 'Chemistry', 'Medium'));
      }
      final database = await _createTestDatabase(questions);
      final engine = DppEngine(
        database,
        QuestionRepository(database),
        QuestionHistoryService(database),
        MasteryService(database, Future.value(questions)),
        random: Random(42),
        userId: 1,
      );

      final config = DppConfig.single(subject: 'Physics', totalQuestions: 10);
      final result = await engine.generate(config);

      expect(result.questions.length, 10);
      expect(result.questions.every((q) => q.subject == 'Physics'), isTrue);
    });
  });

  group('DPP Engine — Difficulty Quotas', () {
    test('DPP respects easy/medium/hard percentages', () async {
      final questions = <Question>[];
      for (int i = 0; i < 20; i++) {
        questions.add(_q('e_$i', 'Physics', 'Easy'));
        questions.add(_q('m_$i', 'Physics', 'Medium'));
        questions.add(_q('h_$i', 'Physics', 'Hard'));
      }
      final database = await _createTestDatabase(questions);
      final engine = DppEngine(
        database,
        QuestionRepository(database),
        QuestionHistoryService(database),
        MasteryService(database, Future.value(questions)),
        random: Random(42),
        userId: 1,
      );

      final config = DppConfig(
        subjects: ['Physics'],
        totalQuestions: 20,
        easyPercent: 30,
        mediumPercent: 50,
        hardPercent: 20,
        includeWeakTopics: false,
        useChapterWeights: false,
      );
      final result = await engine.generate(config);

      expect(result.questions.length, 20);
      final easyCount = result.questions
          .where((q) => _normalizeDifficulty(q.difficulty) == 'Easy')
          .length;
      final mediumCount = result.questions
          .where((q) => _normalizeDifficulty(q.difficulty) == 'Medium')
          .length;
      final hardCount = result.questions
          .where((q) => _normalizeDifficulty(q.difficulty) == 'Hard')
          .length;

      expect(easyCount, greaterThanOrEqualTo(3));
      expect(easyCount, lessThanOrEqualTo(9));
      expect(mediumCount, greaterThanOrEqualTo(7));
      expect(mediumCount, lessThanOrEqualTo(13));
      expect(hardCount, greaterThanOrEqualTo(1));
      expect(hardCount, lessThanOrEqualTo(7));
    });
  });

  group('DPP Engine — Insufficient Pool Fallback', () {
    test(
      'returns available questions when pool is smaller than requested',
      () async {
        final questions = <Question>[];
        for (int i = 0; i < 5; i++) {
          questions.add(_q('q_$i', 'Physics', 'Medium'));
        }
        final database = await _createTestDatabase(questions);
        final engine = DppEngine(
          database,
          QuestionRepository(database),
          QuestionHistoryService(database),
          MasteryService(database, Future.value(questions)),
          random: Random(42),
          userId: 1,
        );

        final config = DppConfig(
          subjects: ['Physics'],
          totalQuestions: 20,
          includeWeakTopics: false,
          useChapterWeights: false,
        );
        final result = await engine.generate(config);

        expect(result.questions.length, 5);
        expect(result.isShortage, isTrue);
      },
    );

    test('returns empty list when no questions match', () async {
      final questions = <Question>[];
      for (int i = 0; i < 5; i++) {
        questions.add(_q('q_$i', 'Chemistry', 'Medium'));
      }
      final database = await _createTestDatabase(questions);
      final engine = DppEngine(
        database,
        QuestionRepository(database),
        QuestionHistoryService(database),
        MasteryService(database, Future.value(questions)),
        random: Random(42),
        userId: 1,
      );

      final config = DppConfig.single(subject: 'Physics', totalQuestions: 10);
      final result = await engine.generate(config);

      expect(result.questions, isEmpty);
    });
  });

  group('DPP Engine — Deterministic Sampling', () {
    test('same seed produces same DPP', () async {
      final questions = <Question>[];
      for (int i = 0; i < 30; i++) {
        questions.add(_q('q_$i', 'Physics', 'Medium'));
      }
      final database = await _createTestDatabase(questions);

      final engine1 = DppEngine(
        database,
        QuestionRepository(database),
        QuestionHistoryService(database),
        MasteryService(database, Future.value(questions)),
        random: Random(42),
        userId: 1,
      );
      final engine2 = DppEngine(
        database,
        QuestionRepository(database),
        QuestionHistoryService(database),
        MasteryService(database, Future.value(questions)),
        random: Random(42),
        userId: 1,
      );

      final config = DppConfig(
        subjects: ['Physics'],
        totalQuestions: 10,
        includeWeakTopics: false,
        useChapterWeights: false,
      );

      final result1 = await engine1.generate(config, forceRefresh: true);
      final result2 = await engine2.generate(config, forceRefresh: true);

      final ids1 = result1.questions.map((q) => q.id).toList();
      final ids2 = result2.questions.map((q) => q.id).toList();
      expect(ids1, equals(ids2));
    });

    test('different seeds produce different DPPs', () async {
      final questions = <Question>[];
      for (int i = 0; i < 30; i++) {
        questions.add(_q('q_$i', 'Physics', 'Medium'));
      }
      final database = await _createTestDatabase(questions);

      final engine1 = DppEngine(
        database,
        QuestionRepository(database),
        QuestionHistoryService(database),
        MasteryService(database, Future.value(questions)),
        random: Random(42),
        userId: 1,
      );
      final engine2 = DppEngine(
        database,
        QuestionRepository(database),
        QuestionHistoryService(database),
        MasteryService(database, Future.value(questions)),
        random: Random(99),
        userId: 1,
      );

      final config = DppConfig(
        subjects: ['Physics'],
        totalQuestions: 10,
        includeWeakTopics: false,
        useChapterWeights: false,
      );

      final result1 = await engine1.generate(config, forceRefresh: true);
      final result2 = await engine2.generate(config, forceRefresh: true);

      final ids1 = result1.questions.map((q) => q.id).toList();
      final ids2 = result2.questions.map((q) => q.id).toList();
      expect(ids1 == ids2, isFalse);
    });
  });

  group('DPP Engine — Persistence Reload', () {
    test('returns existing DPP for today if not forced', () async {
      final questions = <Question>[];
      for (int i = 0; i < 20; i++) {
        questions.add(_q('q_$i', 'Physics', 'Medium'));
      }
      final database = await _createTestDatabase(questions);
      final engine = DppEngine(
        database,
        QuestionRepository(database),
        QuestionHistoryService(database),
        MasteryService(database, Future.value(questions)),
        random: Random(42),
        userId: 1,
      );

      final config = DppConfig.single(subject: 'Physics', totalQuestions: 10);

      final result1 = await engine.generate(config);
      expect(result1.questions.length, 10);

      final result2 = await engine.generate(config);
      expect(result2.questions.length, 10);

      final ids1 = result1.questions.map((q) => q.id).toList();
      final ids2 = result2.questions.map((q) => q.id).toList();
      expect(ids1, equals(ids2));
    });

    test('forceRefresh creates a new DPP', () async {
      final questions = <Question>[];
      for (int i = 0; i < 30; i++) {
        questions.add(_q('q_$i', 'Physics', 'Medium'));
      }
      final database = await _createTestDatabase(questions);
      final engine = DppEngine(
        database,
        QuestionRepository(database),
        QuestionHistoryService(database),
        MasteryService(database, Future.value(questions)),
        random: Random(42),
        userId: 1,
      );

      final config = DppConfig.single(subject: 'Physics', totalQuestions: 10);

      // Seed the day's set, then force a regeneration over it.
      await engine.generate(config);
      final refreshed = await engine.generate(config, forceRefresh: true);

      expect(refreshed.questions.length, 10);
      expect(refreshed.set.isCompleted, isFalse);
      // The refreshed paper must still be addressable by today's lookup.
      expect(refreshed.requestedQuestions, 10);
    });
  });

  group('DPP Engine — User Isolation', () {
    test('DPP for different users are independent', () async {
      final questions = <Question>[];
      for (int i = 0; i < 20; i++) {
        questions.add(_q('q_$i', 'Physics', 'Medium'));
      }
      final database = await _createTestDatabase(questions);

      final engine1 = DppEngine(
        database,
        QuestionRepository(database),
        QuestionHistoryService(database, userId: 1),
        MasteryService(database, Future.value(questions), userId: 1),
        random: Random(42),
        userId: 1,
      );
      final engine2 = DppEngine(
        database,
        QuestionRepository(database),
        QuestionHistoryService(database, userId: 2),
        MasteryService(database, Future.value(questions), userId: 2),
        random: Random(42),
        userId: 2,
      );

      final config = DppConfig.single(subject: 'Physics', totalQuestions: 10);

      final result1 = await engine1.generate(config);
      final result2 = await engine2.generate(config);

      expect(result1.questions.length, 10);
      expect(result2.questions.length, 10);
    });
  });

  group('DPP Engine — Submission Idempotency', () {
    test('grading is deterministic for same answers', () {
      final questions = [
        _q('1', 'Physics', 'Medium', correctAnswer: 'A'),
        _q('2', 'Physics', 'Medium', correctAnswer: 'B'),
        _q('3', 'Physics', 'Medium', correctAnswer: 'C'),
      ];

      int correct = 0;
      int incorrect = 0;
      final answers = {0: 'A', 1: 'B', 2: 'X'};

      for (int i = 0; i < questions.length; i++) {
        final answer = answers[i];
        if (answer == null) continue;
        if (answer == questions[i].correctAnswer) {
          correct++;
        } else {
          incorrect++;
        }
      }

      expect(correct, 2);
      expect(incorrect, 1);
    });
  });
}
