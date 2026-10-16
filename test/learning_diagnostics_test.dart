import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/learning_diagnostics.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/models/user_progress_model.dart';
import 'package:neet_mitos/core/services/mistake_classifier.dart';
import 'package:neet_mitos/core/services/retention_service.dart';

void main() {
  final question = Question(
    id: 'q1',
    subject: 'Physics',
    chapter: 'Units',
    topic: 'Dimensions',
    topicId: 'phys_ch2_t1',
    questionText: 'Calculate the dimensional formula of force.',
    options: const ['MLT-2', 'ML2T-2'],
    correctAnswer: 'MLT-2',
    explanation: 'Use the definition of force.',
    difficulty: 'Medium',
    tags: const ['calculation'],
    type: 'mcq',
  );

  test('classifier identifies calculation and speed mistakes', () {
    const classifier = MistakeClassifier();
    expect(
      classifier
          .classify(
            question: question,
            selectedAnswer: 'ML2T-2',
            timeSeconds: 30,
          )
          .type,
      MistakeType.calculation,
    );
    expect(
      classifier
          .classify(question: question, selectedAnswer: null, timeSeconds: 30)
          .type,
      MistakeType.speed,
    );
  });

  test('retention schedules 3, 7 and 14 day checks', () {
    const service = RetentionService();
    final last = DateTime(2026, 1, 1);
    final checks = service.scheduleFor(
      'bio_ch1_t1',
      last,
      now: DateTime(2026, 1, 8),
    );
    expect(checks.map((check) => check.intervalDays), [3, 7, 14]);
    expect(checks[0].isDue, isTrue);
    expect(checks[2].isDue, isFalse);
  });

  test('retention mastery decays gradually after inactivity', () {
    const service = RetentionService();
    final progress = TopicProgress(
      topicId: 'bio_ch1_t1',
      questionsAttempted: 20,
      questionsCorrect: 16,
      averageTimeSeconds: 30,
      lastAttempted: DateTime(2026, 1, 1),
    );
    final adjusted = service.retentionAdjustedMastery(
      progress,
      now: DateTime(2026, 1, 31),
    );
    expect(adjusted, lessThan(progress.accuracy));
    expect(adjusted, greaterThan(50));
  });
}
