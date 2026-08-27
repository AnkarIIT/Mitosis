import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
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
    answersByIndex: const {0: 'Option A', 1: null, 2: 'Option C'},
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
          ['1']
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
  });
}
