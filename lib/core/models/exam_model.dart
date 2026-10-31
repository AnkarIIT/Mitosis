import 'question_model.dart';

enum QuestionStatus {
  unanswered,
  attempted,
  markedReview,
  attemptedReview,
}

enum ExamSection {
  physics,
  chemistry,
  biology,
}

class ExamQuestion {
  final Question question;
  QuestionStatus status;
  String? selectedAnswer;
  bool isMarkedForReview;

  ExamQuestion({
    required this.question,
    this.status = QuestionStatus.unanswered,
    this.selectedAnswer,
    this.isMarkedForReview = false,
  });

  void updateStatus(String? answer) {
    selectedAnswer = answer;
    status = isMarkedForReview
        ? QuestionStatus.attemptedReview
        : QuestionStatus.attempted;
  }

  void toggleReview() {
    isMarkedForReview = !isMarkedForReview;
    if (selectedAnswer != null) {
      status = isMarkedForReview
          ? QuestionStatus.attemptedReview
          : QuestionStatus.attempted;
    } else {
      status = isMarkedForReview
          ? QuestionStatus.markedReview
          : QuestionStatus.unanswered;
    }
  }
}

class ExamSession {
  final String id;
  final String title;
  final List<ExamQuestion> questions;
  final Map<ExamSection, List<ExamQuestion>> sectionedQuestions;
  final Duration totalDuration;
  late Duration remainingTime;
  final DateTime startTime;
  DateTime? endTime;
  ExamSection currentSection;
  int currentQuestionIndex;
  bool isSubmitted;

  ExamSession({
    required this.id,
    required this.title,
    required this.questions,
    required this.sectionedQuestions,
    required this.totalDuration,
    DateTime? startTime,
    this.currentSection = ExamSection.biology,
    this.currentQuestionIndex = 0,
    this.isSubmitted = false,
  }) : startTime = startTime ?? DateTime.now() {
    remainingTime = totalDuration;
  }

  Map<String, dynamic> getStats() {
    int attempted = 0;
    int correct = 0;
    int markedReview = 0;
    int unanswered = 0;

    for (var q in questions) {
      if (q.status == QuestionStatus.attempted ||
          q.status == QuestionStatus.attemptedReview) {
        attempted++;
        if (q.selectedAnswer == q.question.correctAnswer) {
          correct++;
        }
      }
      if (q.isMarkedForReview) markedReview++;
      if (q.status == QuestionStatus.unanswered) unanswered++;
    }

    return {
      'attempted': attempted,
      'correct': correct,
      'incorrect': attempted - correct,
      'markedReview': markedReview,
      'unanswered': unanswered,
      'score': correct * 4,
      'totalQuestions': questions.length,
    };
  }

  void submitExam() {
    endTime = DateTime.now();
    isSubmitted = true;
  }
}
