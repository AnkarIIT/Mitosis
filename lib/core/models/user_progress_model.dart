class UserProgress {
  final String topicId;
  final int questionsAttempted;
  final int questionsCorrect;
  final int timeSpentSeconds;
  final DateTime lastAttempted;
  final bool isCompleted;

  UserProgress({
    required this.topicId,
    required this.questionsAttempted,
    required this.questionsCorrect,
    required this.timeSpentSeconds,
    required this.lastAttempted,
    this.isCompleted = false,
  });

  double get accuracy => questionsAttempted == 0
      ? 0
      : (questionsCorrect / questionsAttempted) * 100;

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      topicId: map['topicId'] as String,
      questionsAttempted: map['questionsAttempted'] as int,
      questionsCorrect: map['questionsCorrect'] as int,
      timeSpentSeconds: map['timeSpentSeconds'] as int,
      lastAttempted: DateTime.parse(map['lastAttempted'] as String),
      isCompleted: map['isCompleted'] as bool,
    );
  }

  Map<String, dynamic> toMap() => {
    'topicId': topicId,
    'questionsAttempted': questionsAttempted,
    'questionsCorrect': questionsCorrect,
    'timeSpentSeconds': timeSpentSeconds,
    'lastAttempted': lastAttempted.toIso8601String(),
    'isCompleted': isCompleted,
  };
}

class QuizAttempt {
  final String id;
  final String topicId;
  final String subject;
  final String testType; // 'topic', 'chapter', 'subject', 'mock'
  final Map<String, int>? subjectScores; // For mock tests: { 'Biology': 45, ... }
  final int score;
  final int totalQuestions;
  final int timeSpentSeconds;
  final DateTime attemptedAt;
  final List<String> selectedAnswers;

  QuizAttempt({
    required this.id,
    required this.topicId,
    required this.subject,
    this.testType = 'topic',
    this.subjectScores,
    required this.score,
    required this.totalQuestions,
    required this.timeSpentSeconds,
    required this.attemptedAt,
    required this.selectedAnswers,
  });

  double get accuracy => totalQuestions == 0 ? 0 : (score / totalQuestions) * 100;
}
