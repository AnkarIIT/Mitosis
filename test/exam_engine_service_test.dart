import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/services/exam_engine_service.dart';

Question _q(
  int id,
  String subject,
  String topicId, {
  String correct = 'Option B',
  List<String> options = const ['Option A', 'Option B', 'Option C', 'Option D'],
}) {
  return Question(
    id: id,
    subject: subject,
    chapter: 'Chapter',
    topic: 'Topic',
    topicId: topicId,
    questionText: 'Question $id',
    options: options,
    correctAnswer: correct,
    difficulty: 'Medium',
    tags: const [],
    type: 'mcq',
  );
}

List<Question> _pool() {
  return [
    _q(1, 'Physics', 'p1'),
    _q(2, 'Physics', 'p1'),
    _q(3, 'Physics', 'p2'),
    _q(4, 'Chemistry', 'c1'),
    _q(5, 'Chemistry', 'c1'),
    _q(6, 'Chemistry', 'c2'),
    _q(7, 'Biology', 'b1'),
    _q(8, 'Biology', 'b2'),
    _q(9, 'Biology', 'b3'),
  ];
}

void main() {
  group('ExamConfig', () {
    test('neet config uses 4 sections and 200 minutes', () {
      final config = ExamConfig.neet();
      expect(config.mode, ExamMode.neet);
      expect(config.sections.length, 4);
      expect(config.sections.map((s) => s.name).toList(),
          ['Physics', 'Chemistry', 'Botany', 'Zoology']);
      expect(config.totalDurationSeconds, 200 * 60);
      expect(config.marksPerCorrect, 4);
      expect(config.marksPerWrong, -1);
      expect(config.sectionLock, isTrue);
      expect(config.breaksEnabled, isTrue);
      expect(config.breakAfterSectionIndex, 1);
      expect(config.totalQuestionSlots, 180);
    });

    test('practice config has single unlocked section', () {
      final config = ExamConfig.practice(
        questionCount: 50,
        durationMinutes: 30,
      );
      expect(config.mode, ExamMode.practice);
      expect(config.sectionLock, isFalse);
      expect(config.breaksEnabled, isFalse);
      expect(config.totalDurationSeconds, 1800);
      expect(config.totalQuestionSlots, 50);
    });
  });

  group('ExamEngineService', () {
    test('sampleQuestions caps at pool size', () {
      final pool = _pool();
      expect(ExamEngineService.sampleQuestions(pool, 100, seed: 1).length, 9);
      expect(ExamEngineService.sampleQuestions(pool, 4, seed: 2).length, 4);
    });

    test('allocateQuestions splits Biology into Botany and Zoology', () {
      final config = ExamConfig.neet(
        physicsCount: 2,
        chemistryCount: 2,
        botanyCount: 2,
        zoologyCount: 2,
      );
      final sections = ExamEngineService.allocateQuestions(_pool(), config, seed: 3);
      expect(sections[0].length, 2);
      expect(sections[1].length, 2);
      expect(sections[2].length, 2);
      expect(sections[3].length, 1);
      expect(sections[0].every((q) => q.subject == 'Physics'), isTrue);
      expect(sections[1].every((q) => q.subject == 'Chemistry'), isTrue);
      expect(sections[2].every((q) => q.subject == 'Biology'), isTrue);
      expect(sections[3].every((q) => q.subject == 'Biology'), isTrue);
      final flattened = ExamEngineService.flattenAllocated(sections);
      final unique = flattened.map((q) => q.id).toSet();
      expect(unique.length, flattened.length, reason: 'no duplicate questions');
    });

    test('allocateQuestions handles shortfall gracefully', () {
      final config = ExamConfig.neet(); // asks for 45 per section
      final sections = ExamEngineService.allocateQuestions(_pool(), config, seed: 4);
      expect(sections[0].length, lessThanOrEqualTo(45));
      expect(sections[0].length, 3);
      expect(sections[1].length, 3);
      expect(sections[2].length, 3);
      expect(sections[3].length, 0);
    });

    test('grade applies +4, -1, and 0 marking', () {
      final questions = _pool().take(3).toList();
      final config = ExamConfig.practice(
        questionCount: 3,
        durationMinutes: 10,
      );
      final score = ExamEngineService.grade(
        config: config,
        questions: questions,
        answersByIndex: {
          0: 'Option B', // correct
          1: 'Option A', // wrong
          // 2 unanswered
        },
      );
      expect(score.correct, 1);
      expect(score.incorrect, 1);
      expect(score.unanswered, 1);
      expect(score.attempted, 2);
      expect(score.rawScore, 3);
      expect(score.maxScore, 12);
      expect(score.accuracy, 50.0);
    });

    test('grade treats empty string as unanswered', () {
      final questions = _pool().take(1).toList();
      final config = ExamConfig.practice(
        questionCount: 1,
        durationMinutes: 10,
      );
      final score = ExamEngineService.grade(
        config: config,
        questions: questions,
        answersByIndex: {0: ''},
      );
      expect(score.unanswered, 1);
      expect(score.rawScore, 0);
    });
  });
}
