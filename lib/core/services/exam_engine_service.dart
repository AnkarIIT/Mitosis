import 'dart:math';
import '../models/question_model.dart';

enum ExamMode { neet, practice }

class ExamSection {
  final int index;
  final String name;
  final String sourceSubject;
  final int questionCount;

  const ExamSection({
    required this.index,
    required this.name,
    required this.sourceSubject,
    required this.questionCount,
  });
}

class ExamConfig {
  final ExamMode mode;
  final String testType;
  final String topicId;
  final String subjectLabel;
  final int totalDurationSeconds;
  final bool sectionLock;
  final bool breaksEnabled;
  final int breakDurationSeconds;
  final int breakAfterSectionIndex;
  final int marksPerCorrect;
  final int marksPerWrong;
  final List<ExamSection> sections;

  const ExamConfig({
    required this.mode,
    required this.testType,
    required this.topicId,
    required this.subjectLabel,
    required this.totalDurationSeconds,
    required this.sectionLock,
    required this.breaksEnabled,
    required this.breakDurationSeconds,
    required this.breakAfterSectionIndex,
    required this.marksPerCorrect,
    required this.marksPerWrong,
    required this.sections,
  });

  int get totalQuestionSlots => sections.fold(0, (s, x) => s + x.questionCount);

  int get marksPerCorrectTotal => totalQuestionSlots * marksPerCorrect;

  static ExamConfig neet({
    int physicsCount = 45,
    int chemistryCount = 45,
    int botanyCount = 45,
    int zoologyCount = 45,
    int durationMinutes = 200,
    bool sectionLock = true,
    bool breaksEnabled = true,
    int breakMinutes = 5,
  }) {
    return ExamConfig(
      mode: ExamMode.neet,
      testType: 'mock',
      topicId: 'mock_test',
      subjectLabel: 'NEET',
      totalDurationSeconds: durationMinutes * 60,
      sectionLock: sectionLock,
      breaksEnabled: breaksEnabled,
      breakDurationSeconds: breakMinutes * 60,
      breakAfterSectionIndex: 1,
      marksPerCorrect: 4,
      marksPerWrong: -1,
      sections: [
        ExamSection(
          index: 0,
          name: 'Physics',
          sourceSubject: 'Physics',
          questionCount: physicsCount,
        ),
        ExamSection(
          index: 1,
          name: 'Chemistry',
          sourceSubject: 'Chemistry',
          questionCount: chemistryCount,
        ),
        ExamSection(
          index: 2,
          name: 'Botany',
          sourceSubject: 'Biology',
          questionCount: botanyCount,
        ),
        ExamSection(
          index: 3,
          name: 'Zoology',
          sourceSubject: 'Biology',
          questionCount: zoologyCount,
        ),
      ],
    );
  }

  static ExamConfig practice({
    required int questionCount,
    required int durationMinutes,
    String subjectLabel = 'Practice',
    bool sectionLock = false,
  }) {
    return ExamConfig(
      mode: ExamMode.practice,
      testType: 'practice',
      topicId: 'cbt_practice',
      subjectLabel: subjectLabel,
      totalDurationSeconds: durationMinutes * 60,
      sectionLock: sectionLock,
      breaksEnabled: false,
      breakDurationSeconds: 0,
      breakAfterSectionIndex: -1,
      marksPerCorrect: 4,
      marksPerWrong: -1,
      sections: [
        ExamSection(
          index: 0,
          name: 'All Subjects',
          sourceSubject: '',
          questionCount: questionCount,
        ),
      ],
    );
  }
}

class QuestionResult {
  final Question question;
  final String? selectedAnswer;
  final int marks;

  const QuestionResult({
    required this.question,
    required this.selectedAnswer,
    required this.marks,
  });

  bool get isCorrect =>
      selectedAnswer != null && selectedAnswer == question.correctAnswer;

  bool get isIncorrect =>
      selectedAnswer != null && selectedAnswer != question.correctAnswer;

  bool get isUnanswered => selectedAnswer == null;
}

class ExamScore {
  final ExamConfig config;
  final List<QuestionResult> results;

  const ExamScore({required this.config, required this.results});

  int get correct => results.where((r) => r.isCorrect).length;

  int get incorrect => results.where((r) => r.isIncorrect).length;

  int get unanswered => results.where((r) => r.isUnanswered).length;

  int get attempted => correct + incorrect;

  int get rawScore => results.fold(0, (sum, r) => sum + r.marks);

  int get maxScore => results.length * config.marksPerCorrect;

  double get accuracy => attempted == 0 ? 0 : (correct / attempted) * 100;

  double get answeredAccuracy =>
      results.isEmpty ? 0 : (rawScore / (results.length * 4.0) * 100);

  List<QuestionResult> resultsFor(String subject) =>
      results.where((r) => r.question.subject == subject).toList();
}

class ExamEngineService {
  static List<Question> sampleQuestions(
    List<Question> pool,
    int count, {
    int? seed,
  }) {
    final shuffled = List<Question>.from(pool);
    shuffled.shuffle(Random(seed ?? DateTime.now().millisecondsSinceEpoch));
    return shuffled.take(count).toList();
  }

  static List<List<Question>> allocateQuestions(
    List<Question> pool,
    ExamConfig config, {
    int? seed,
  }) {
    final remaining = List<Question>.from(pool)
      ..shuffle(Random(seed ?? DateTime.now().millisecondsSinceEpoch));
    final allocated = List.generate(config.sections.length, (_) => <Question>[]);

    for (final section in config.sections) {
      final candidates = section.sourceSubject.isEmpty
          ? remaining
          : remaining
              .where((q) => q.subject == section.sourceSubject)
              .toList();
      final taken = candidates.take(section.questionCount).toList();
      allocated[section.index] = taken;
      remaining.removeWhere(taken.contains);
    }
    return allocated;
  }

  static List<Question> flattenAllocated(List<List<Question>> sections) =>
      [for (final section in sections) ...section];

  static ExamScore grade({
    required ExamConfig config,
    required List<Question> questions,
    required Map<int, String?> answersByIndex,
  }) {
    final results = <QuestionResult>[];
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final raw = answersByIndex[i];
      final answer = (raw == null || raw.isEmpty) ? null : raw;
      bool correct = false;
      if (answer != null) {
        correct = answer == q.correctAnswer;
      }
      results.add(
        QuestionResult(
          question: q,
          selectedAnswer: answer,
          marks: correct
              ? config.marksPerCorrect
              : (answer == null ? 0 : config.marksPerWrong),
        ),
      );
    }
    return ExamScore(config: config, results: results);
  }
}
