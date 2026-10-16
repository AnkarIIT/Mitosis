import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/providers/quiz_providers.dart';
import 'package:neet_mitos/core/services/quiz_session_service.dart';

Question _question() => Question(
  id: 'q1',
  subject: 'Physics',
  chapter: 'Motion',
  topic: 'Speed',
  topicId: 'speed',
  questionText: 'Which option is correct?',
  options: ['First', 'Second', 'Third', 'Fourth'],
  correctAnswer: 'Second',
  difficulty: 'Easy',
  tags: const [],
  type: 'mcq',
);

void main() {
  test('quiz answer selection normalizes labels and indexes', () {
    final notifier = QuizNotifier(_FakeQuizSessionService());
    notifier.initializeQuiz([_question()], seed: 7);

    final correctIndex = notifier.state.questions.first.options.indexOf(
      'Second',
    );
    final correctLabel = String.fromCharCode('A'.codeUnitAt(0) + correctIndex);
    notifier.selectAnswer(0, correctLabel, 1);

    expect(notifier.state.answerResults[0], isTrue);
    expect(notifier.state.score, 1);
    expect(notifier.state.incorrectCount, 0);
  });
}

class _FakeQuizSessionService implements QuizSessionService {
  @override
  Future<void> deleteCompletedSessions() async {}

  @override
  Future<void> deleteSession(String sessionId) async {}

  @override
  Future<List<QuizSessionData>> getAllSessions() async => [];

  @override
  Future<QuizSessionData?> restoreSession(String sessionId) async => null;

  @override
  Future<void> saveSession({
    required String sessionId,
    required String topicId,
    required String subject,
    required String testType,
    required String quizMode,
    required int timeLimitSeconds,
    required int seed,
    required int currentIndex,
    required Map<int, String> selectedAnswers,
    required Map<int, bool> answerResults,
    required Map<int, int> timeSpentPerQuestion,
    required Set<int> flaggedQuestions,
    required Set<int> visitedQuestions,
    required int score,
    required int incorrectCount,
    required int elapsedSeconds,
    required bool isCompleted,
    required List<String> questionIds,
    List<Question>? questions,
  }) async {}
}
