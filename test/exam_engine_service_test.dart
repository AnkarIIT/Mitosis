import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/services/exam_engine_service.dart';

Question _q(
  String id,
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
    _q('1', 'Physics', 'p1'),
    _q('2', 'Physics', 'p1'),
    _q('3', 'Physics', 'p2'),
    _q('4', 'Chemistry', 'c1'),
    _q('5', 'Chemistry', 'c1'),
    _q('6', 'Chemistry', 'c2'),
    _q('7', 'Biology', 'b1'),
    _q('8', 'Biology', 'b2'),
    _q('9', 'Biology', 'b3'),
  ];
}

/// An optional section: 5 shown, only 3 graded ("attempt any 3 of 5").
ExamConfig _optionalConfig() {
  return ExamConfig(
    mode: ExamMode.neet,
    testType: 'mock',
    topicId: 'mock_test',
    subjectLabel: 'NEET',
    totalDurationSeconds: 600,
    sectionLock: false,
    breaksEnabled: false,
    breakDurationSeconds: 0,
    breakAfterSectionIndex: -1,
    marksPerCorrect: 4,
    marksPerWrong: -1,
    isFullLengthMock: false,
    sections: [
      ExamSection(
        index: 0,
        name: 'Optional',
        sourceSubject: '',
        presentedCount: 5,
        gradedCount: 3,
      ),
    ],
  );
}

void main() {
  group('ExamConfig', () {
    test('neet() default is the modern flat 180q / 180min mock', () {
      final config = ExamConfig.neet();
      expect(config.mode, ExamMode.neet);
      expect(config.sections.length, 4);
      expect(config.sections.map((s) => s.name).toList(), [
        'Physics',
        'Chemistry',
        'Botany',
        'Zoology',
      ]);
      expect(config.totalDurationSeconds, 180 * 60);
      expect(config.marksPerCorrect, 4);
      expect(config.marksPerWrong, -1);
      // Modern default: free navigation, no break, full-length mock.
      expect(config.sectionLock, isFalse);
      expect(config.breaksEnabled, isFalse);
      expect(config.breakAfterSectionIndex, -1);
      expect(config.isFullLengthMock, isTrue);
      expect(config.totalQuestionSlots, 180);
      expect(config.totalGraded, 180); // all compulsory
    });

    test('neetWithOptionalB() expresses compulsory + optional N-of-M', () {
      final config = ExamConfig.neetWithOptionalB();
      // 4 subjects × (Section A + Section B) = 8 sections.
      expect(config.sections.length, 8);
      final optional = config.sections.where((s) => s.isOptional).toList();
      expect(optional.length, 4);
      expect(optional.every((s) => s.gradedCount < s.presentedCount), isTrue);
      expect(config.isFullLengthMock, isTrue);
    });

    test('practice config has single unlocked section', () {
      final config = ExamConfig.practice(
        questionCount: 50,
        durationMinutes: 30,
      );
      expect(config.mode, ExamMode.practice);
      expect(config.sectionLock, isFalse);
      expect(config.breaksEnabled, isFalse);
      expect(config.isFullLengthMock, isFalse);
      expect(config.totalDurationSeconds, 1800);
      expect(config.totalQuestionSlots, 50);
    });

    test('ExamConfig JSON round-trips (incl. optional sections)', () {
      final config = ExamConfig.neetWithOptionalB();
      final restored = ExamConfig.fromJson(config.toJson());
      expect(restored.sections.length, config.sections.length);
      expect(restored.totalGraded, config.totalGraded);
      expect(restored.totalPresented, config.totalPresented);
      expect(restored.isFullLengthMock, config.isFullLengthMock);
      expect(restored.sections.first.name, config.sections.first.name);
      expect(restored.sections[1].gradedCount, config.sections[1].gradedCount);
    });
  });

  group('ExamEngineService.validatePool', () {
    test('drops uneven / mis-keyed questions', () {
      final good = _q('g', 'Physics', 'p');
      final badCorrect = _q('b', 'Physics', 'p', correct: 'Not An Option');
      final tooFewOptions = _q(
        'f',
        'Physics',
        'p',
        correct: 'A',
        options: ['A'],
      );
      final emptyText = Question(
        id: 'e',
        subject: 'Physics',
        chapter: 'c',
        topic: 't',
        topicId: 'p',
        questionText: '   ',
        options: const ['Option A', 'Option B'],
        correctAnswer: 'Option A',
        difficulty: 'Medium',
        tags: const [],
        type: 'mcq',
      );
      final clean = ExamEngineService.validatePool([
        good,
        badCorrect,
        tooFewOptions,
        emptyText,
      ]);
      expect(clean.map((q) => q.id).toList(), ['g']);
    });

    test('accepts a correct answer that only differs by whitespace', () {
      final q = _q('w', 'Physics', 'p', correct: ' Option B ');
      expect(ExamEngineService.validatePool([q]).length, 1);
    });
  });

  group('ExamEngineService.isAnswerCorrect', () {
    test('trims both sides and handles null', () {
      final q = _q('x', 'Physics', 'p', correct: 'Option B');
      expect(ExamEngineService.isAnswerCorrect(' Option B ', q), isTrue);
      expect(ExamEngineService.isAnswerCorrect('Option C', q), isFalse);
      expect(ExamEngineService.isAnswerCorrect(null, q), isFalse);
    });
  });

  group('ExamEngineService.allocateQuestions', () {
    test('sampleQuestions caps at pool size', () {
      final pool = _pool();
      expect(ExamEngineService.sampleQuestions(pool, 100, seed: 1).length, 9);
      expect(ExamEngineService.sampleQuestions(pool, 4, seed: 2).length, 4);
    });

    test('splits Biology into Botany and Zoology without duplicates', () {
      final config = ExamConfig.neet(
        physicsCount: 2,
        chemistryCount: 2,
        botanyCount: 2,
        zoologyCount: 2,
      );
      final sections = ExamEngineService.allocateQuestions(
        _pool(),
        config,
        seed: 3,
      );
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

    test('handles shortfall gracefully', () {
      final config = ExamConfig.neet(); // asks for 45 per section
      final sections = ExamEngineService.allocateQuestions(
        _pool(),
        config,
        seed: 4,
      );
      expect(sections[0].length, 3);
      expect(sections[1].length, 3);
      expect(sections[2].length, 3);
      expect(sections[3].length, 0);
    });
  });

  group('ExamEngineService.grade', () {
    test('applies +4, -1, and 0 marking on a compulsory section', () {
      final questions = _pool().take(3).toList();
      final config = ExamConfig.practice(questionCount: 3, durationMinutes: 10);
      final score = ExamEngineService.grade(
        config: config,
        sectionQuestions: [questions],
        answersByIndex: {
          0: 'Option B', // correct
          1: 'Option A', // wrong
          // 2 unanswered
        },
      );
      expect(score.correct, 1);
      expect(score.incorrect, 1);
      expect(score.unanswered, 1);
      expect(score.discarded, 0);
      expect(score.attempted, 2);
      expect(score.rawScore, 3);
      expect(score.maxScore, 12);
      expect(score.accuracy, 50.0);
    });

    test('treats empty string as unanswered', () {
      final questions = _pool().take(1).toList();
      final config = ExamConfig.practice(questionCount: 1, durationMinutes: 10);
      final score = ExamEngineService.grade(
        config: config,
        sectionQuestions: [questions],
        answersByIndex: {0: ''},
      );
      expect(score.unanswered, 1);
      expect(score.rawScore, 0);
    });

    test('optional N-of-M counts first N answered, discards the extras', () {
      final questions = _pool().take(5).toList(); // all correct = 'Option B'
      final score = ExamEngineService.grade(
        config: _optionalConfig(),
        sectionQuestions: [questions],
        answersByIndex: {
          0: 'Option B',
          1: 'Option B',
          2: 'Option B',
          3: 'Option B', // beyond graded cap of 3
          4: 'Option B', // beyond graded cap of 3
        },
      );
      expect(score.correct, 3);
      expect(score.discarded, 2);
      expect(score.incorrect, 0);
      expect(score.rawScore, 12); // 3 × 4, extras give 0
      expect(score.maxScore, 12); // min(gradedCount=3, allocated=5) × 4
    });

    test('answers beyond the graded cap are NOT penalised', () {
      final questions = _pool().take(5).toList();
      final score = ExamEngineService.grade(
        config: _optionalConfig(),
        sectionQuestions: [questions],
        answersByIndex: {
          0: 'Option B', // correct, counted
          1: 'Option B', // correct, counted
          2: 'Option B', // correct, counted
          3: 'Option A', // wrong, but beyond cap → discarded, no -1
          4: 'Option A', // wrong, but beyond cap → discarded, no -1
        },
      );
      expect(score.rawScore, 12, reason: 'over-limit wrongs must not subtract');
      expect(score.incorrect, 0);
      expect(score.discarded, 2);
    });

    test('wrong answers WITHIN the graded cap still cost -1', () {
      final questions = _pool().take(5).toList();
      final score = ExamEngineService.grade(
        config: _optionalConfig(),
        sectionQuestions: [questions],
        answersByIndex: {
          0: 'Option B', // correct  +4
          1: 'Option A', // wrong    -1  (within cap)
          2: 'Option B', // correct  +4
        },
      );
      expect(score.rawScore, 7); // 4 - 1 + 4
      expect(score.incorrect, 1);
      expect(score.discarded, 0);
    });

    test('per-result section index is tracked for breakdowns', () {
      final config = ExamConfig.neet(
        physicsCount: 1,
        chemistryCount: 1,
        botanyCount: 0,
        zoologyCount: 0,
      );
      final score = ExamEngineService.grade(
        config: config,
        sectionQuestions: [
          [_q('a', 'Physics', 'p')],
          [_q('b', 'Chemistry', 'c')],
          [],
          [],
        ],
        answersByIndex: {0: 'Option B', 1: 'Option B'},
      );
      expect(score.sectionIndexByResult, [0, 1]);
      expect(score.resultsForSection(0).length, 1);
      expect(score.resultsForSection(1).length, 1);
    });
  });
}
