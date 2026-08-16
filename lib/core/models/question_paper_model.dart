import 'question_model.dart';

// Question Paper Standards
enum PaperStandard {
  mini,      // 5 questions (quick practice)
  chapter,   // 10 questions (chapter test)
  standard,  // 30 questions (mock NEET level)
  full,      // 180 questions (full NEET exam)
}

class PaperConfig {
  final PaperStandard standard;
  final int questionCount;
  final String displayName;
  final String description;
  final Duration? timeLimit;

  PaperConfig({
    required this.standard,
    required this.questionCount,
    required this.displayName,
    required this.description,
    this.timeLimit,
  });

  static final Map<PaperStandard, PaperConfig> configs = {
    PaperStandard.mini: PaperConfig(
      standard: PaperStandard.mini,
      questionCount: 5,
      displayName: 'Quick Practice',
      description: '5 questions - Perfect for quick review',
      timeLimit: Duration(minutes: 10),
    ),
    PaperStandard.chapter: PaperConfig(
      standard: PaperStandard.chapter,
      questionCount: 10,
      displayName: 'Chapter Test',
      description: '10 questions - Master one chapter',
      timeLimit: Duration(minutes: 20),
    ),
    PaperStandard.standard: PaperConfig(
      standard: PaperStandard.standard,
      questionCount: 30,
      displayName: 'Mock Test',
      description: '30 questions - Like real exam',
      timeLimit: Duration(minutes: 60),
    ),
    PaperStandard.full: PaperConfig(
      standard: PaperStandard.full,
      questionCount: 180,
      displayName: 'Full NEET Paper',
      description: '180 questions - Complete exam experience',
      timeLimit: Duration(minutes: 180),
    ),
  };

  static PaperConfig getConfig(PaperStandard standard) {
    return configs[standard] ??
        configs[PaperStandard.standard]!;
  }
}

class QuestionPaper {
  final String id;
  final String title;
  final String description;
  final List<String> subjects;
  final List<Question> questions;
  final PaperStandard standard;
  final DateTime createdAt;
  final Duration? timeLimit;
  final bool showYearMarking;

  QuestionPaper({
    required this.id,
    required this.title,
    required this.description,
    required this.subjects,
    required this.questions,
    required this.standard,
    required this.createdAt,
    this.timeLimit,
    this.showYearMarking = false,
  });

  // Getters
  int get totalQuestions => questions.length;

  Map<String, int> get subjectDistribution {
    final distribution = <String, int>{};
    for (var question in questions) {
      distribution[question.subject] =
          (distribution[question.subject] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> get difficultyDistribution {
    final distribution = <String, int>{};
    for (var question in questions) {
      distribution[question.difficulty] =
          (distribution[question.difficulty] ?? 0) + 1;
    }
    return distribution;
  }

  // Shuffle questions (preserves order but randomizes question number)
  List<Question> getShuffledQuestions() {
    final shuffled = [...questions];
    shuffled.shuffle();
    return shuffled;
  }
}
