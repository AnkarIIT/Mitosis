import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/services/exam_checkpoint_service.dart';
import 'package:neet_mitos/core/services/exam_engine_service.dart';

ExamCheckpoint _sample({int? deadlineEpochMs}) {
  return ExamCheckpoint(
    attemptId: 'attempt-123',
    configJson: ExamConfig.neet().toJson(),
    sectionQuestionIds: const [
      ['1', '2'],
      ['3'],
      [],
      [],
    ],
    sectionQuestions: [
      [
        Question(
          id: '1',
          subject: 'Physics',
          chapter: 'Mechanics',
          topic: 'Newton\'s Laws',
          topicId: 'phy_01',
          questionText: 'What is Newton\'s first law?',
          options: ['Inertia', 'F=ma', 'Action-Reaction', 'Gravity'],
          correctAnswer: 'Inertia',
          difficulty: 'Easy',
          tags: ['physics', 'mechanics'],
          type: 'mcq',
        ),
        Question(
          id: '2',
          subject: 'Physics',
          chapter: 'Mechanics',
          topic: 'Friction',
          topicId: 'phy_02',
          questionText: 'Friction opposes:',
          options: ['Motion', 'Force', 'Gravity', 'Mass'],
          correctAnswer: 'Motion',
          difficulty: 'Easy',
          tags: ['physics', 'mechanics'],
          type: 'mcq',
        ),
      ],
      [
        Question(
          id: '3',
          subject: 'Chemistry',
          chapter: 'Organic',
          topic: 'Alkanes',
          topicId: 'chem_01',
          questionText: 'Methane formula?',
          options: ['CH4', 'C2H6', 'C3H8', 'CO2'],
          correctAnswer: 'CH4',
          difficulty: 'Easy',
          tags: ['chemistry', 'organic'],
          type: 'mcq',
        ),
      ],
      [],
      [],
    ],
    answersByIndex: const {0: 'Inertia', 1: null, 2: 'CH4'},
    flagged: const [1],
    visited: const [0, 1, 2],
    currentIndex: 2,
    currentSection: 1,
    phase: 'taking',
    deadlineEpochMs: deadlineEpochMs ?? 1893499200000, // fixed epoch
    breakDeadlineEpochMs: null,
    startedAtEpochMs: 1893495600000,
    savedAtEpochMs: 1893495700000,
  );
}

void main() {
  group('ExamCheckpoint', () {
    test('JSON round-trips through encode/decode', () {
      final cp = _sample();
      final restored = ExamCheckpoint.fromJson(
        jsonDecode(jsonEncode(cp.toJson())) as Map<String, dynamic>,
      );

      expect(restored.attemptId, cp.attemptId);
      expect(restored.sectionQuestionIds, cp.sectionQuestionIds);
      expect(restored.answersByIndex, cp.answersByIndex);
      expect(restored.answersByIndex[1], isNull); // null answer preserved
      expect(restored.flagged, cp.flagged);
      expect(restored.visited, cp.visited);
      expect(restored.currentIndex, cp.currentIndex);
      expect(restored.currentSection, cp.currentSection);
      expect(restored.phase, cp.phase);
      expect(restored.deadlineEpochMs, cp.deadlineEpochMs);
      expect(restored.breakDeadlineEpochMs, isNull);
      expect(restored.startedAtEpochMs, cp.startedAtEpochMs);
      expect(restored.savedAtEpochMs, cp.savedAtEpochMs);
    });

    test('config getter rebuilds the ExamConfig', () {
      final cp = _sample();
      final config = cp.config;
      expect(config.mode, ExamMode.neet);
      expect(config.sections.length, 4);
      expect(config.totalDurationSeconds, 180 * 60);
      expect(config.isFullLengthMock, isTrue);
    });

    test('remainingSecondsAt is wall-clock and clamped at 0', () {
      final deadline = DateTime(2030, 1, 1, 12, 0, 0);
      final cp = _sample(deadlineEpochMs: deadline.millisecondsSinceEpoch);

      expect(
        cp.remainingSecondsAt(deadline.subtract(const Duration(minutes: 5))),
        300,
      );
      expect(
        cp.remainingSecondsAt(deadline.subtract(const Duration(seconds: 1))),
        1,
      );
      // Past the deadline → never negative.
      expect(
        cp.remainingSecondsAt(deadline.add(const Duration(seconds: 30))),
        0,
      );
    });

    test('breakDeadlineEpochMs survives a round-trip when set', () {
      final cp = ExamCheckpoint(
        attemptId: 'a',
        configJson: ExamConfig.practice(
          questionCount: 5,
          durationMinutes: 10,
        ).toJson(),
        sectionQuestionIds: const [
          ['1'],
        ],
        sectionQuestions: [
          [
            Question(
              id: '1',
              subject: 'Physics',
              chapter: 'Ch1',
              topic: 'T1',
              topicId: 't1',
              questionText: 'Q1?',
              options: ['A', 'B'],
              correctAnswer: 'A',
              difficulty: 'Easy',
              tags: ['test'],
              type: 'mcq',
            ),
          ],
        ],
        answersByIndex: const {},
        flagged: const [],
        visited: const [0],
        currentIndex: 0,
        currentSection: 0,
        phase: 'break_',
        deadlineEpochMs: 1893499200000,
        breakDeadlineEpochMs: 1893495800000,
        startedAtEpochMs: 1893495600000,
        savedAtEpochMs: 1893495700000,
      );
      final restored = ExamCheckpoint.fromJson(
        jsonDecode(jsonEncode(cp.toJson())) as Map<String, dynamic>,
      );
      expect(restored.breakDeadlineEpochMs, 1893495800000);
      expect(restored.phase, 'break_');
    });

    test('violations default to 0 when absent (backward compatible)', () {
      final cp = _sample();
      expect(cp.violations, 0);
    });

    test('violations survive a JSON round-trip', () {
      final cp = ExamCheckpoint(
        attemptId: 'a',
        configJson: ExamConfig.neet().toJson(),
        sectionQuestionIds: const [
          ['1'],
        ],
        sectionQuestions: [
          [
            Question(
              id: '1',
              subject: 'Physics',
              chapter: 'Ch1',
              topic: 'T1',
              topicId: 't1',
              questionText: 'Q1?',
              options: ['A', 'B'],
              correctAnswer: 'A',
              difficulty: 'Easy',
              tags: ['test'],
              type: 'mcq',
            ),
          ],
        ],
        answersByIndex: const {},
        flagged: const [],
        visited: const [0],
        currentIndex: 0,
        currentSection: 0,
        phase: 'taking',
        deadlineEpochMs: 1893499200000,
        startedAtEpochMs: 1893495600000,
        savedAtEpochMs: 1893495700000,
        violations: 3,
      );
      final restored = ExamCheckpoint.fromJson(
        jsonDecode(jsonEncode(cp.toJson())) as Map<String, dynamic>,
      );
      expect(restored.violations, 3);
    });

    test('question snapshots survive a JSON round-trip', () {
      final cp = _sample();
      final restored = ExamCheckpoint.fromJson(
        jsonDecode(jsonEncode(cp.toJson())) as Map<String, dynamic>,
      );

      expect(restored.sectionQuestions.length, 4);
      expect(restored.sectionQuestions[0].length, 2);
      expect(restored.sectionQuestions[0][0].id, '1');
      expect(
        restored.sectionQuestions[0][0].questionText,
        'What is Newton\'s first law?',
      );
      expect(restored.sectionQuestions[0][0].options.length, 4);
      expect(restored.sectionQuestions[0][0].correctAnswer, 'Inertia');
      expect(restored.sectionQuestions[1][0].id, '3');
      expect(restored.sectionQuestions[1][0].subject, 'Chemistry');
    });

    test('v1/v2 checkpoints without snapshots still parse', () {
      // Simulate an old checkpoint without sectionQuestions field.
      final oldJson = {
        'attemptId': 'old-attempt',
        'config': ExamConfig.neet().toJson(),
        'sectionQuestionIds': [
          ['1', '2'],
          ['3'],
          [],
          [],
        ],
        'answers': {'0': 'Inertia', '1': null, '2': 'CH4'},
        'flagged': [1],
        'visited': [0, 1, 2],
        'currentIndex': 2,
        'currentSection': 1,
        'phase': 'taking',
        'deadlineEpochMs': 1893499200000,
        'startedAtEpochMs': 1893495600000,
        'savedAtEpochMs': 1893495700000,
        'version': 2,
      };

      final restored = ExamCheckpoint.fromJson(oldJson);
      expect(restored.attemptId, 'old-attempt');
      expect(restored.sectionQuestions, isEmpty);
      expect(restored.sectionQuestionIds.length, 4);
      expect(restored.answersByIndex[0], 'Inertia');
    });

    test('checkpoint version is 3', () {
      final cp = _sample();
      expect(cp.version, 3);
    });
  });
}
