import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/services/exam_checkpoint_service.dart';
import 'package:neet_mitos/core/services/exam_engine_service.dart';

// ─────────────────────────────────────────────────────────────
// Test helpers
// ─────────────────────────────────────────────────────────────

Question _q(
  String id,
  String subject,
  String correctAnswer, {
  List<String>? options,
}) {
  return Question(
    id: id,
    subject: subject,
    chapter: 'Ch$id',
    topic: 'Topic $id',
    topicId: 'topic_$id',
    questionText: 'Question $id?',
    options: options ?? ['A', 'B', 'C', 'D'],
    correctAnswer: correctAnswer,
    difficulty: 'Medium',
    tags: ['test'],
    type: 'mcq',
  );
}

ExamCheckpoint _checkpointWithSnapshots({
  String attemptId = 'test-attempt',
  int? deadlineEpochMs,
  Map<int, String?> answers = const {},
}) {
  final questions = [
    _q('1', 'Physics', 'A'),
    _q('2', 'Physics', 'B'),
    _q('3', 'Chemistry', 'C'),
    _q('4', 'Chemistry', 'D'),
  ];
  return ExamCheckpoint(
    attemptId: attemptId,
    configJson: ExamConfig.practice(
      questionCount: 4,
      durationMinutes: 10,
    ).toJson(),
    sectionQuestionIds: [
      ['1', '2'],
      ['3', '4'],
    ],
    sectionQuestions: [
      [questions[0], questions[1]],
      [questions[2], questions[3]],
    ],
    answersByIndex: answers,
    flagged: const [],
    visited: const [0, 1, 2, 3],
    currentIndex: 0,
    currentSection: 0,
    phase: 'taking',
    deadlineEpochMs:
        deadlineEpochMs ??
        DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
    startedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    savedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
  );
}

// ─────────────────────────────────────────────────────────────
// Durable Snapshot Tests
// ─────────────────────────────────────────────────────────────

void main() {
  group('Durable Snapshots', () {
    test('checkpoint stores full question data, not just IDs', () {
      final cp = _checkpointWithSnapshots();
      final json = cp.toJson();

      expect(json['sectionQuestions'], isNotNull);
      final sections = json['sectionQuestions'] as List;
      expect(sections.length, 2);
      expect((sections[0] as List).length, 2);
      expect((sections[0][0] as Map)['id'], '1');
      expect((sections[0][0] as Map)['questionText'], 'Question 1?');
      expect((sections[0][0] as Map)['correctAnswer'], 'A');
    });

    test('checkpoint restores questions even if pool changes', () {
      final cp = _checkpointWithSnapshots();
      final restored = ExamCheckpoint.fromJson(
        jsonDecode(jsonEncode(cp.toJson())) as Map<String, dynamic>,
      );

      // Simulate pool change: original questions no longer available.
      // Snapshots should still restore.
      expect(restored.sectionQuestions.length, 2);
      expect(restored.sectionQuestions[0][0].id, '1');
      expect(restored.sectionQuestions[0][0].questionText, 'Question 1?');
      expect(restored.sectionQuestions[0][0].options, ['A', 'B', 'C', 'D']);
      expect(restored.sectionQuestions[0][0].correctAnswer, 'A');
    });

    test('question toJson/fromJson round-trips correctly', () {
      final q = _q('test-1', 'Physics', 'B');
      final json = q.toJson();
      final restored = Question.fromJson(json);

      expect(restored.id, q.id);
      expect(restored.subject, q.subject);
      expect(restored.questionText, q.questionText);
      expect(restored.options, q.options);
      expect(restored.correctAnswer, q.correctAnswer);
      expect(restored.difficulty, q.difficulty);
      expect(restored.tags, q.tags);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Result Recomputation Tests
  // ─────────────────────────────────────────────────────────────

  group('Result Recomputation', () {
    test('grade recomputes from saved answers', () {
      final questions = [
        _q('1', 'Physics', 'A'),
        _q('2', 'Physics', 'B'),
        _q('3', 'Chemistry', 'C'),
        _q('4', 'Chemistry', 'D'),
      ];
      final config = ExamConfig.practice(questionCount: 4, durationMinutes: 10);
      final sectionQuestions = [
        [questions[0], questions[1]],
        [questions[2], questions[3]],
      ];

      // Simulate saved answers from a previous session.
      final savedAnswers = {0: 'A', 1: 'B', 2: 'C', 3: 'D'};

      final score = ExamEngineService.grade(
        config: config,
        sectionQuestions: sectionQuestions,
        answersByIndex: savedAnswers,
      );

      expect(score.correct, 4);
      expect(score.incorrect, 0);
      expect(score.rawScore, 16);
      expect(score.maxScore, 16);
    });

    test('grade handles partial answers correctly', () {
      final questions = [
        _q('1', 'Physics', 'A'),
        _q('2', 'Physics', 'B'),
        _q('3', 'Chemistry', 'C'),
        _q('4', 'Chemistry', 'D'),
      ];
      final config = ExamConfig.practice(questionCount: 4, durationMinutes: 10);
      final sectionQuestions = [
        [questions[0], questions[1]],
        [questions[2], questions[3]],
      ];

      // Only 2 answers saved (app crashed before answering all).
      final savedAnswers = {0: 'A', 1: 'X'}; // 1 correct, 1 wrong

      final score = ExamEngineService.grade(
        config: config,
        sectionQuestions: sectionQuestions,
        answersByIndex: savedAnswers,
      );

      expect(score.correct, 1);
      expect(score.incorrect, 1);
      expect(score.unanswered, 2);
      expect(score.rawScore, 3); // +4 -1
    });

    test('grade handles empty answers after crash', () {
      final questions = [_q('1', 'Physics', 'A'), _q('2', 'Physics', 'B')];
      final config = ExamConfig.practice(questionCount: 2, durationMinutes: 5);
      final sectionQuestions = [
        [questions[0], questions[1]],
      ];

      // No answers saved (crash before any answer).
      final score = ExamEngineService.grade(
        config: config,
        sectionQuestions: sectionQuestions,
        answersByIndex: const {},
      );

      expect(score.correct, 0);
      expect(score.incorrect, 0);
      expect(score.unanswered, 2);
      expect(score.rawScore, 0);
    });

    test('grade recomputes from checkpoint data', () {
      final cp = _checkpointWithSnapshots(
        answers: {0: 'A', 1: 'B', 2: 'C', 3: 'D'},
      );

      final score = ExamEngineService.grade(
        config: cp.config,
        sectionQuestions: cp.sectionQuestions,
        answersByIndex: cp.answersByIndex,
      );

      expect(score.correct, 4);
      expect(score.rawScore, 16);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Timer Correctness Tests
  // ─────────────────────────────────────────────────────────────

  group('Timer Correctness', () {
    test('remainingSecondsAt is wall-clock and clamped at 0', () {
      final deadline = DateTime(2030, 1, 1, 12, 0, 0);
      final cp = _checkpointWithSnapshots(
        deadlineEpochMs: deadline.millisecondsSinceEpoch,
      );

      expect(
        cp.remainingSecondsAt(deadline.subtract(const Duration(minutes: 5))),
        300,
      );
      expect(
        cp.remainingSecondsAt(deadline.subtract(const Duration(seconds: 1))),
        1,
      );
      expect(
        cp.remainingSecondsAt(deadline.add(const Duration(seconds: 30))),
        0,
      );
    });

    test('timer survives app kill and resume', () {
      final deadline = DateTime.now().add(const Duration(minutes: 10));
      final cp = _checkpointWithSnapshots(
        deadlineEpochMs: deadline.millisecondsSinceEpoch,
      );

      // Simulate app kill: checkpoint is saved, app restarts.
      final restored = ExamCheckpoint.fromJson(
        jsonDecode(jsonEncode(cp.toJson())) as Map<String, dynamic>,
      );

      // Remaining time should be based on the original deadline, not reset.
      final remaining = restored.remainingSecondsAt(DateTime.now());
      expect(remaining, greaterThan(0));
      expect(remaining, lessThanOrEqualTo(600));
    });

    test('timer expires correctly after deadline passes', () {
      final deadline = DateTime.now().subtract(const Duration(minutes: 1));
      final cp = _checkpointWithSnapshots(
        deadlineEpochMs: deadline.millisecondsSinceEpoch,
      );

      expect(cp.remainingSecondsAt(DateTime.now()), 0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // App Kill/Resume Tests
  // ─────────────────────────────────────────────────────────────

  group('App Kill/Resume', () {
    test('checkpoint preserves all state for resume', () {
      final cp = _checkpointWithSnapshots(
        answers: {0: 'A', 1: 'B', 2: 'C', 3: 'D'},
      );
      final restored = ExamCheckpoint.fromJson(
        jsonDecode(jsonEncode(cp.toJson())) as Map<String, dynamic>,
      );

      expect(restored.attemptId, cp.attemptId);
      expect(restored.answersByIndex, cp.answersByIndex);
      expect(restored.flagged, cp.flagged);
      expect(restored.visited, cp.visited);
      expect(restored.currentIndex, cp.currentIndex);
      expect(restored.currentSection, cp.currentSection);
      expect(restored.phase, cp.phase);
      expect(restored.deadlineEpochMs, cp.deadlineEpochMs);
      expect(restored.violations, cp.violations);
      expect(restored.secondsPerQuestion, cp.secondsPerQuestion);
    });

    test('resume works after questions are deleted from pool', () {
      final cp = _checkpointWithSnapshots();
      final restored = ExamCheckpoint.fromJson(
        jsonDecode(jsonEncode(cp.toJson())) as Map<String, dynamic>,
      );

      // Even if the original questions are no longer in the pool,
      // the snapshots should restore them.
      expect(restored.sectionQuestions[0][0].id, '1');
      expect(restored.sectionQuestions[0][0].questionText, 'Question 1?');
    });

    test('resume restores per-question timing', () {
      final cp = ExamCheckpoint(
        attemptId: 'test',
        configJson: ExamConfig.practice(
          questionCount: 4,
          durationMinutes: 10,
        ).toJson(),
        sectionQuestionIds: [
          ['1', '2'],
          ['3', '4'],
        ],
        sectionQuestions: [
          [_q('1', 'Physics', 'A'), _q('2', 'Physics', 'B')],
          [_q('3', 'Chemistry', 'C'), _q('4', 'Chemistry', 'D')],
        ],
        answersByIndex: const {0: 'A', 1: 'B', 2: 'C', 3: 'D'},
        flagged: const [],
        visited: const [0, 1, 2, 3],
        currentIndex: 0,
        currentSection: 0,
        phase: 'taking',
        deadlineEpochMs: DateTime.now()
            .add(const Duration(minutes: 10))
            .millisecondsSinceEpoch,
        startedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        savedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        secondsPerQuestion: const {0: 30, 1: 45, 2: 60, 3: 15},
      );

      final restored = ExamCheckpoint.fromJson(
        jsonDecode(jsonEncode(cp.toJson())) as Map<String, dynamic>,
      );

      expect(restored.secondsPerQuestion[0], 30);
      expect(restored.secondsPerQuestion[1], 45);
      expect(restored.secondsPerQuestion[2], 60);
      expect(restored.secondsPerQuestion[3], 15);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Idempotent Submission Tests
  // ─────────────────────────────────────────────────────────────

  group('Idempotent Submission', () {
    test('same attempt ID produces same result', () {
      final questions = [_q('1', 'Physics', 'A'), _q('2', 'Physics', 'B')];
      final config = ExamConfig.practice(questionCount: 2, durationMinutes: 5);
      final sectionQuestions = [
        [questions[0], questions[1]],
      ];
      final answers = {0: 'A', 1: 'B'};

      // Grade twice with same inputs — should produce identical results.
      final score1 = ExamEngineService.grade(
        config: config,
        sectionQuestions: sectionQuestions,
        answersByIndex: answers,
      );
      final score2 = ExamEngineService.grade(
        config: config,
        sectionQuestions: sectionQuestions,
        answersByIndex: answers,
      );

      expect(score1.correct, score2.correct);
      expect(score1.incorrect, score2.incorrect);
      expect(score1.rawScore, score2.rawScore);
      expect(score1.maxScore, score2.maxScore);
    });

    test('grading is deterministic for same inputs', () {
      final questions = [
        _q('1', 'Physics', 'A'),
        _q('2', 'Physics', 'B'),
        _q('3', 'Chemistry', 'C'),
      ];
      final config = ExamConfig.practice(questionCount: 3, durationMinutes: 5);
      final sectionQuestions = [
        [questions[0], questions[1], questions[2]],
      ];
      final answers = {0: 'A', 1: 'X', 2: 'C'};

      final score = ExamEngineService.grade(
        config: config,
        sectionQuestions: sectionQuestions,
        answersByIndex: answers,
      );

      expect(score.correct, 2);
      expect(score.incorrect, 1);
      expect(score.rawScore, 7); // +4 -1 +4
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Checkpoint Version Tests
  // ─────────────────────────────────────────────────────────────

  group('Checkpoint Versioning', () {
    test('current version is 3', () {
      expect(ExamCheckpoint.kCurrentCheckpointVersion, 3);
    });

    test('v1 checkpoints are still readable', () {
      final v1Json = {
        'attemptId': 'v1-attempt',
        'config': ExamConfig.practice(
          questionCount: 2,
          durationMinutes: 5,
        ).toJson(),
        'sectionQuestionIds': [
          ['1'],
          ['2'],
        ],
        'answers': {'0': 'A'},
        'flagged': <int>[],
        'visited': [0],
        'currentIndex': 0,
        'currentSection': 0,
        'phase': 'taking',
        'deadlineEpochMs': 1893499200000,
        'startedAtEpochMs': 1893495600000,
        'savedAtEpochMs': 1893495700000,
        'version': 1,
      };

      final restored = ExamCheckpoint.fromJson(v1Json);
      expect(restored.attemptId, 'v1-attempt');
      expect(restored.version, 1);
      expect(restored.sectionQuestions, isEmpty);
    });

    test('v2 checkpoints are still readable', () {
      final v2Json = {
        'attemptId': 'v2-attempt',
        'config': ExamConfig.practice(
          questionCount: 2,
          durationMinutes: 5,
        ).toJson(),
        'sectionQuestionIds': [
          ['1'],
          ['2'],
        ],
        'answers': {'0': 'A'},
        'flagged': <int>[],
        'visited': [0],
        'currentIndex': 0,
        'currentSection': 0,
        'phase': 'taking',
        'deadlineEpochMs': 1893499200000,
        'startedAtEpochMs': 1893495600000,
        'savedAtEpochMs': 1893495700000,
        'violations': 2,
        'version': 2,
      };

      final restored = ExamCheckpoint.fromJson(v2Json);
      expect(restored.attemptId, 'v2-attempt');
      expect(restored.version, 2);
      expect(restored.violations, 2);
      expect(restored.sectionQuestions, isEmpty);
    });

    test('v3 checkpoints include snapshots', () {
      final cp = _checkpointWithSnapshots();
      expect(cp.version, 3);
      expect(cp.sectionQuestions.isNotEmpty, true);
    });
  });
}
