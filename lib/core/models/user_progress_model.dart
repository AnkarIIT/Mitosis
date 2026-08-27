class TopicProgress {
  final String topicId;
  final int questionsAttempted;
  final int questionsCorrect;
  final double averageTimeSeconds;
  final DateTime lastAttempted;
  final bool isCompleted;

  TopicProgress({
    required this.topicId,
    required this.questionsAttempted,
    required this.questionsCorrect,
    required this.averageTimeSeconds,
    required this.lastAttempted,
    this.isCompleted = false,
  });

  double get accuracy => questionsAttempted == 0
      ? 0
      : (questionsCorrect / questionsAttempted) * 100;

  factory TopicProgress.fromMap(Map<String, dynamic> map) {
    return TopicProgress(
      topicId: map['topicId'] as String,
      questionsAttempted: map['questionsAttempted'] as int,
      questionsCorrect: map['questionsCorrect'] as int,
      averageTimeSeconds: map['averageTimeSeconds'] as double,
      lastAttempted: map['lastAttempted'] as DateTime,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}

class UserProgress {
  final Map<String, TopicProgress> topicProgress;
  final List<QuizAttempt> quizAttempts;
  final int totalQuestionsAttempted;
  final int questionsCorrect;
  final int currentStreak;
  final DateTime? lastActivityDate;

  UserProgress({
    this.topicProgress = const {},
    this.quizAttempts = const [],
    this.totalQuestionsAttempted = 0,
    this.questionsCorrect = 0,
    this.currentStreak = 0,
    this.lastActivityDate,
  });

  UserProgress copyWith({
    Map<String, TopicProgress>? topicProgress,
    List<QuizAttempt>? quizAttempts,
    int? totalQuestionsAttempted,
    int? questionsCorrect,
    int? currentStreak,
    DateTime? lastActivityDate,
  }) {
    return UserProgress(
      topicProgress: topicProgress ?? this.topicProgress,
      quizAttempts: quizAttempts ?? this.quizAttempts,
      totalQuestionsAttempted:
          totalQuestionsAttempted ?? this.totalQuestionsAttempted,
      questionsCorrect: questionsCorrect ?? this.questionsCorrect,
      currentStreak: currentStreak ?? this.currentStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }
}

class QuizAttempt {
  final String id;
  final String topicId;
  final String subject;
  final String testType; // 'topic', 'chapter', 'subject', 'mock'
  final Map<String, int>? subjectScores; // For mock tests: { 'Biology': 45, ... }
  final int score; // Number of correct answers
  final int incorrectCount; // Number of incorrect answers
  final int totalQuestions;
  final int timeSpentSeconds;
  final DateTime attemptedAt;
  final List<String> selectedAnswers;

  /// Real ±marks persisted from the exam engine (single source of truth).
  /// Null for legacy rows recorded before these were stored.
  final int? rawScore;
  final int? maxMarks;

  QuizAttempt({
    required this.id,
    required this.topicId,
    required this.subject,
    this.testType = 'topic',
    this.subjectScores,
    required this.score,
    required this.incorrectCount,
    required this.totalQuestions,
    required this.timeSpentSeconds,
    required this.attemptedAt,
    required this.selectedAnswers,
    this.rawScore,
    this.maxMarks,
  });

  /// NEET score. Uses the persisted raw marks when available; otherwise falls
  /// back to the legacy 4×correct − incorrect derivation for old rows.
  int get neetScore => rawScore ?? (score * 4) - incorrectCount;

  /// Maximum possible score for this attempt (persisted when available).
  int get maxScore => maxMarks ?? (totalQuestions * 4);

  double get accuracy =>
      totalQuestions == 0 ? 0 : (score / totalQuestions) * 100;
}
