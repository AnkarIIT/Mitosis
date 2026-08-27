import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/services/exam_engine_service.dart';
import 'package:neet_mitos/core/services/test_analytics_service.dart';

Question _q(
  String id,
  String subject,
  String topicId,
  String topic, {
  String correct = 'Option B',
}) {
  return Question(
    id: id,
    subject: subject,
    chapter: 'Chapter',
    topic: topic,
    topicId: topicId,
    questionText: 'Question $id',
    options: const ['Option A', 'Option B', 'Option C', 'Option D'],
    correctAnswer: correct,
    difficulty: 'Medium',
    tags: const [],
    type: 'mcq',
  );
}

/// Grade a flat practice attempt (single 'All Subjects' section).
ExamScore _gradePractice(
  List<Question> questions,
  Map<int, String?> answers,
) {
  final config = ExamConfig.practice(
    questionCount: questions.length,
    durationMinutes: 30,
  );
  return ExamEngineService.grade(
    config: config,
    sectionQuestions: [questions],
    answersByIndex: answers,
  );
}

void main() {
  group('TestAnalyticsService.estimatePercentile', () {
    test('returns anchors for full and zero scores', () {
      expect(TestAnalyticsService.estimatePercentile(720, 720), 99.99);
      expect(TestAnalyticsService.estimatePercentile(0, 720), 0.5);
    });

    test('interpolates between anchors', () {
      final pct = TestAnalyticsService.estimatePercentile(400, 720);
      expect(pct, closeTo(55.0, 0.01));
      final between = TestAnalyticsService.estimatePercentile(500, 720);
      expect(between, closeTo(80.0, 0.01));
    });

    test('scales practice scores to the 720 scale', () {
      // 180/360 = 360 on the 720 scale -> 44.6%
      final half = TestAnalyticsService.estimatePercentile(180, 360);
      expect(half, closeTo(44.6, 0.01));
    });

    test('air estimate is a plausible rank', () {
      final air = TestAnalyticsService.estimateAir(99.99);
      expect(air, lessThan(5000));
      final airMid = TestAnalyticsService.estimateAir(50.0);
      expect(airMid, closeTo(1200000, 100000));
    });
  });

  group('TestAnalyticsService.compute', () {
    test('breaks scores down by section name (Physics vs Chemistry)', () {
      // A section-named config is what produces per-subject grouping; a flat
      // practice test groups everything under its single section instead.
      final config = ExamConfig.neet(
        physicsCount: 2,
        chemistryCount: 1,
        botanyCount: 0,
        zoologyCount: 0,
      );
      final score = ExamEngineService.grade(
        config: config,
        sectionQuestions: [
          [
            _q('1', 'Physics', 'p1', 'Motion'),
            _q('2', 'Physics', 'p1', 'Motion'),
          ],
          [_q('3', 'Chemistry', 'c1', 'Bonding')],
          [],
          [],
        ],
        answersByIndex: {
          0: 'Option B', // correct
          1: 'Option A', // wrong
          // 2 unanswered
        },
      );
      final analytics = TestAnalyticsService.compute(
        score: score,
        secondsPerQuestion: [30, 45, 60],
      );

      expect(analytics.averageTimePerQuestion, 45.0);
      final physics = analytics.subjects['Physics']!;
      expect(physics.correct, 1);
      expect(physics.incorrect, 1);
      expect(physics.unanswered, 0);
      expect(physics.averageTimeSeconds, 37.5);
      final chemistry = analytics.subjects['Chemistry']!;
      expect(chemistry.unanswered, 1);
    });

    test('splits Biology into Botany and Zoology sections', () {
      final config = ExamConfig.neet(
        physicsCount: 0,
        chemistryCount: 0,
        botanyCount: 1,
        zoologyCount: 1,
      );
      final score = ExamEngineService.grade(
        config: config,
        sectionQuestions: [
          [],
          [],
          [_q('b', 'Biology', 'bo1', 'Cell')],
          [_q('z', 'Biology', 'zo1', 'Heart')],
        ],
        answersByIndex: {0: 'Option B', 1: 'Option B'},
      );
      final analytics = TestAnalyticsService.compute(
        score: score,
        secondsPerQuestion: [20, 20],
      );
      expect(analytics.subjects.containsKey('Botany'), isTrue);
      expect(analytics.subjects.containsKey('Zoology'), isTrue);
      expect(analytics.subjects['Botany']!.correct, 1);
      expect(analytics.subjects['Zoology']!.correct, 1);
    });

    test('rank estimate is gated to full-length mocks', () {
      final practice = _gradePractice(
        [_q('1', 'Physics', 'p', 'Motion')],
        {0: 'Option B'},
      );
      final practiceA = TestAnalyticsService.compute(
        score: practice,
        secondsPerQuestion: [10],
      );
      expect(practiceA.showRankEstimate, isFalse);
      expect(practiceA.percentileEstimate, 0.0);
      expect(practiceA.airEstimate, 0);

      final mockConfig = ExamConfig.neet(
        physicsCount: 1,
        chemistryCount: 0,
        botanyCount: 0,
        zoologyCount: 0,
      );
      final mock = ExamEngineService.grade(
        config: mockConfig,
        sectionQuestions: [
          [_q('1', 'Physics', 'p', 'Motion')],
          [],
          [],
          [],
        ],
        answersByIndex: {0: 'Option B'},
      );
      final mockA = TestAnalyticsService.compute(
        score: mock,
        secondsPerQuestion: [10],
      );
      expect(mockA.showRankEstimate, isTrue);
      expect(mockA.percentileEstimate, greaterThan(0));
    });

    test('finds and sorts weak topics below 60% accuracy', () {
      final questions = [
        _q('1', 'Physics', 'weak', 'Weak Topic'),
        _q('2', 'Physics', 'weak', 'Weak Topic'),
        _q('3', 'Physics', 'strong', 'Strong Topic'),
        _q('4', 'Physics', 'strong', 'Strong Topic'),
        _q('5', 'Physics', 'strong', 'Strong Topic'),
      ];
      final score = _gradePractice(questions, {
        0: 'Option A', // wrong
        1: 'Option B', // correct -> 50% accuracy weak
        2: 'Option B', // correct
        3: 'Option B', // correct
        4: 'Option B', // correct
      });
      final weak = TestAnalyticsService.findWeakTopics(score);
      expect(weak.length, 1);
      expect(weak.first.topicId, 'weak');
      expect(weak.first.accuracy, 50.0);
      expect(weak.first.attempted, 2);
    });

    test('unanswered questions are excluded from weak topics', () {
      final questions = [
        _q('1', 'Physics', 'skip', 'Skipped Topic'),
        _q('2', 'Physics', 'skip', 'Skipped Topic'),
      ];
      final score = _gradePractice(questions, {});
      expect(TestAnalyticsService.findWeakTopics(score), isEmpty);
    });
  });
}
