enum StudyMode {
  selfStudy,
  coachingStudent,
  onlineCourse,
}

class ChatContext {
  final String userBatch;
  final String currentChapter;
  final List<String> weakTopics;
  final int daysToExam;
  final int questionsSolved;
  final double accuracy;
  final StudyMode studyMode;

  ChatContext({
    required this.userBatch,
    required this.currentChapter,
    required this.weakTopics,
    required this.daysToExam,
    required this.questionsSolved,
    required this.accuracy,
    required this.studyMode,
  });
}