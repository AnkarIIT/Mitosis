import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/mark_booster_model.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/models/subject_model.dart';
import 'package:neet_mitos/core/models/user_progress_model.dart';
import 'package:neet_mitos/core/services/mark_booster_service.dart';

Question _makeQuestion(String id, {String topicId = 'weak_topic', String? type}) {
  return Question(
    id: id,
    subject: 'Biology',
    chapter: 'Chapter',
    topic: 'Topic',
    topicId: topicId,
    questionText: 'Question $id',
    options: ['A', 'B', 'C', 'D'],
    correctAnswer: 'A',
    difficulty: 'Medium',
    tags: [],
    type: type ?? 'mcq',
  );
}

WeakTopicDiagnosis _weakTopic(String topicId, {double accuracy = 40}) {
  return WeakTopicDiagnosis(
    topic: Topic(
      id: topicId,
      name: 'Weak Topic $topicId',
      chapterId: 'chapter',
      description: '',
      questionCount: 5,
    ),
    subjectName: 'Biology',
    chapterName: 'Chapter',
    questionsAttempted: 10,
    questionsCorrect: (accuracy / 10).round(),
    questionsAvailable: 5,
  );
}

MarkBoosterDiagnosis _diagnosis({
  List<Question>? errorQuestions,
  List<WeakTopicDiagnosis> weakTopics = const [],
}) {
  return MarkBoosterDiagnosis(
    weakTopics: weakTopics,
    typeWeaknesses: const [],
    difficultyWeaknesses: const [],
    errorBookQuestions: errorQuestions ?? const [],
  );
}

void main() {
  test('prioritizes unresolved error book questions in the drill', () {
    final errorQ1 = _makeQuestion('1');
    final errorQ2 = _makeQuestion('2');
    final pool = [_makeQuestion('3'), errorQ1, _makeQuestion('4'), errorQ2];
    final drill = MarkBoosterService.buildDrill(
      diagnosis: _diagnosis(errorQuestions: [errorQ1, errorQ2]),
      allQuestions: pool,
      size: 3,
    );

    expect(drill, containsAll([errorQ1, errorQ2]));
    expect(drill[0], anyOf(errorQ1, errorQ2));
  });

  test('includes questions from weak topics', () {
    final pool = [
      _makeQuestion('1', topicId: 'weak_topic'),
      _makeQuestion('2', topicId: 'weak_topic'),
      _makeQuestion('3', topicId: 'other_topic'),
    ];
    final drill = MarkBoosterService.buildDrill(
      diagnosis: _diagnosis(weakTopics: [_weakTopic('weak_topic')]),
      allQuestions: pool,
      size: 3,
    );

    expect(
      drill.any((q) => q.topicId == 'weak_topic'),
      isTrue,
      reason: 'Drill should favour the weak topic',
    );
  });

  test('returns at most the requested size and never duplicates', () {
    final pool = List.generate(30, (i) => _makeQuestion('${i + 1}'));
    final drill = MarkBoosterService.buildDrill(
      diagnosis: _diagnosis(),
      allQuestions: pool,
      size: 10,
    );

    expect(drill.length, 10);
    final ids = drill.map((q) => q.id).toSet();
    expect(ids.length, drill.length);
  });

  test('returns all available questions when pool is smaller than size', () {
    final pool = [_makeQuestion('1'), _makeQuestion('2')];
    final drill = MarkBoosterService.buildDrill(
      diagnosis: _diagnosis(),
      allQuestions: pool,
      size: 10,
    );

    expect(drill.length, 2);
  });

  test('returns empty when no questions exist', () {
    final drill = MarkBoosterService.buildDrill(
      diagnosis: _diagnosis(),
      allQuestions: const [],
      size: 5,
    );

    expect(drill, isEmpty);
  });

  test('caps weak-topic contribution and fills with variety', () {
    final rng = Random(42);
    final pool = List.generate(20, (i) => _makeQuestion('${i + 1}'));
    final drill = MarkBoosterService.buildDrill(
      diagnosis: _diagnosis(weakTopics: [_weakTopic('weak_topic')]),
      allQuestions: pool,
      size: 20,
      random: rng,
    );

    expect(drill.length, 20);
    expect(drill.map((q) => q.id).toSet().length, 20);
  });

  test('resolveErrorBookEntry maps stored id back to a question', () {
    final q = _makeQuestion('7');
    final resolved = MarkBoosterService.resolveErrorBookEntry(
      '7',
      [_makeQuestion('1'), q],
    );
    expect(resolved?.id, '7');
  });

  test('resolveErrorBookEntry returns null for missing question', () {
    final resolved = MarkBoosterService.resolveErrorBookEntry('99', []);
    expect(resolved, isNull);
  });

  group('aggregateTopicResults', () {
    test('groups correctness per topicId', () {
      final questions = [
        _makeQuestion('1', topicId: 'a'),
        _makeQuestion('2', topicId: 'b'),
        _makeQuestion('3', topicId: 'a'),
      ];
      final result = MarkBoosterService.aggregateTopicResults(
        questions: questions,
        answerResults: {0: true, 1: false, 2: false},
      );

      expect(result['a'], (correct: 1, total: 2));
      expect(result['b'], (correct: 0, total: 1));
    });

    test('treats unanswered indices as incorrect', () {
      final questions = [_makeQuestion('1', topicId: 'a')];
      final result = MarkBoosterService.aggregateTopicResults(
        questions: questions,
        answerResults: const {},
      );

      expect(result['a'], (correct: 0, total: 1));
    });
  });

  group('mastery helpers', () {
    test('masteryProgress clamps to mastery threshold', () {
      expect(MarkBoosterService.masteryProgress(0), 0.0);
      expect(MarkBoosterService.masteryProgress(30), closeTo(0.5, 0.001));
      expect(MarkBoosterService.masteryProgress(60), 1.0);
      expect(MarkBoosterService.masteryProgress(90), 1.0);
    });

    test('isTopicMastered requires threshold and attempts', () {
      expect(
        MarkBoosterService.isTopicMastered(5, 70),
        isTrue,
      );
      expect(
        MarkBoosterService.isTopicMastered(4, 70),
        isFalse,
        reason: 'too few attempts',
      );
      expect(
        MarkBoosterService.isTopicMastered(5, 59),
        isFalse,
        reason: 'below threshold',
      );
    });
  });

  group('extractBoosterSessions', () {
    QuizAttempt makeAttempt(String id, String testType, DateTime at) {
      return QuizAttempt(
        id: id,
        topicId: 't',
        subject: 'Mixed',
        testType: testType,
        score: 5,
        incorrectCount: 5,
        totalQuestions: 10,
        timeSpentSeconds: 60,
        attemptedAt: at,
        selectedAnswers: const [],
      );
    }

    test('filters booster attempts and sorts newest first', () {
      final older = DateTime(2026, 1, 1);
      final newer = DateTime(2026, 2, 1);
      final attempts = [
        makeAttempt('1', 'topic', older),
        makeAttempt('2', 'booster', newer),
        makeAttempt('3', 'booster', older),
      ];

      final sessions = MarkBoosterService.extractBoosterSessions(attempts);

      expect(sessions.map((s) => s.id), ['2', '3']);
    });

    test('respects limit', () {
      final attempts = List.generate(
        10,
        (i) => makeAttempt('$i', 'booster', DateTime(2026, 1, 1 + i)),
      );
      final sessions = MarkBoosterService.extractBoosterSessions(attempts, limit: 3);
      expect(sessions, hasLength(3));
    });
  });
}
