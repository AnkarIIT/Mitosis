import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../database/drift_database.dart' as db;
import '../services/quiz_session_service.dart';
import 'core_providers.dart';
import 'content_providers.dart';
import 'service_providers.dart';

// ============= QUIZ STATE =============
enum QuizMode { practice, exam, revision, speed }

class QuizState {
  final List<Question> questions;
  final int currentIndex;
  final Map<int, String> selectedAnswers;
  final Map<int, bool> answerResults;
  final int score;
  final int incorrectCount;
  final int timeElapsedSeconds;
  final bool isCompleted;
  final Map<int, int> timeSpentPerQuestion;
  final Set<int> flaggedQuestions;
  final Set<int> visitedQuestions;
  final int seed;
  final QuizMode quizMode;
  final int timeLimitSeconds;

  QuizState({
    required this.questions,
    this.currentIndex = 0,
    this.selectedAnswers = const {},
    this.answerResults = const {},
    this.score = 0,
    this.incorrectCount = 0,
    this.timeElapsedSeconds = 0,
    this.isCompleted = false,
    this.timeSpentPerQuestion = const {},
    this.flaggedQuestions = const {},
    this.visitedQuestions = const {},
    this.seed = 0,
    this.quizMode = QuizMode.practice,
    this.timeLimitSeconds = 0,
  });

  QuizState copyWith({
    List<Question>? questions,
    int? currentIndex,
    Map<int, String>? selectedAnswers,
    Map<int, bool>? answerResults,
    int? score,
    int? incorrectCount,
    int? timeElapsedSeconds,
    bool? isCompleted,
    Map<int, int>? timeSpentPerQuestion,
    Set<int>? flaggedQuestions,
    Set<int>? visitedQuestions,
    int? seed,
    QuizMode? quizMode,
    int? timeLimitSeconds,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      answerResults: answerResults ?? this.answerResults,
      score: score ?? this.score,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      timeElapsedSeconds: timeElapsedSeconds ?? this.timeElapsedSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      timeSpentPerQuestion: timeSpentPerQuestion ?? this.timeSpentPerQuestion,
      flaggedQuestions: flaggedQuestions ?? this.flaggedQuestions,
      visitedQuestions: visitedQuestions ?? this.visitedQuestions,
      seed: seed ?? this.seed,
      quizMode: quizMode ?? this.quizMode,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
    );
  }

  double get accuracy {
    if (selectedAnswers.isEmpty) return 0.0;
    return (score / selectedAnswers.length) * 100;
  }

  int get remaining => questions.length - selectedAnswers.length;

  bool get hasTimeLimit => timeLimitSeconds > 0;
  int get remainingTime => (timeLimitSeconds - timeElapsedSeconds).clamp(0, timeLimitSeconds);
  bool get isTimeUp => hasTimeLimit && remainingTime <= 0;
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier(this._sessionService) : super(QuizState(questions: const []));
  final QuizSessionService _sessionService;
  Timer? _autoSaveTimer;
  String? _currentSessionId;
  String _topicId = '';
  String _subject = '';
  String _testType = 'topic';
  String _quizMode = 'practice';
  int _timeLimitSeconds = 0;

  void initializeQuiz(List<Question> questions, {
    int? seed,
    String? sessionId,
    String? topicId,
    String? subject,
    String? testType,
    QuizMode? quizMode,
    int? timeLimitSeconds,
  }) {
    _currentSessionId = sessionId;
    if (topicId != null) _topicId = topicId;
    if (subject != null) _subject = subject;
    if (testType != null) _testType = testType;
    if (quizMode != null) _quizMode = quizMode.name;
    if (timeLimitSeconds != null) _timeLimitSeconds = timeLimitSeconds;

    final random = Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    final randomizedQuestions = questions.map((q) {
      final shuffledOptions = List<String>.from(q.options)..shuffle(random);
      return Question(
        id: q.id,
        subject: q.subject,
        chapter: q.chapter,
        topic: q.topic,
        topicId: q.topicId,
        questionText: q.questionText,
        options: shuffledOptions,
        correctAnswer: q.correctAnswer,
        explanation: q.explanation,
        ncertReference: q.ncertReference,
        year: q.year,
        difficulty: q.difficulty,
        tags: q.tags,
        imageUrl: q.imageUrl,
        type: q.type,
      );
    }).toList();
    state = QuizState(
      questions: randomizedQuestions,
      seed: seed ?? random.nextInt(1 << 30),
      quizMode: quizMode ?? QuizMode.practice,
      timeLimitSeconds: timeLimitSeconds ?? 0,
    );
    _startAutoSave();
  }

  Future<void> restoreSession(QuizSessionData session) async {
    _currentSessionId = session.sessionId;
    _topicId = session.topicId;
    _subject = session.subject;
    _testType = session.testType;
    _quizMode = session.quizMode;
    _timeLimitSeconds = session.timeLimitSeconds;

    final random = Random(session.seed);
    List<Question> questions;
    if (session.questions != null) {
      questions = session.questions!.map((q) {
        final shuffledOptions = List<String>.from(q.options)..shuffle(random);
        return Question(
          id: q.id,
          subject: q.subject,
          chapter: q.chapter,
          topic: q.topic,
          topicId: q.topicId,
          questionText: q.questionText,
          options: shuffledOptions,
          correctAnswer: q.correctAnswer,
          explanation: q.explanation,
          ncertReference: q.ncertReference,
          year: q.year,
          difficulty: q.difficulty,
          tags: q.tags,
          imageUrl: q.imageUrl,
          type: q.type,
        );
      }).toList();
    } else {
      // Fallback: questions not stored, would need to reload
      questions = [];
    }

    state = QuizState(
      questions: questions,
      currentIndex: session.currentIndex,
      selectedAnswers: session.selectedAnswers,
      answerResults: session.answerResults,
      score: session.score,
      incorrectCount: session.incorrectCount,
      timeElapsedSeconds: session.elapsedSeconds,
      isCompleted: session.isCompleted,
      timeSpentPerQuestion: session.timeSpentPerQuestion,
      flaggedQuestions: session.flaggedQuestions,
      visitedQuestions: session.visitedQuestions,
      seed: session.seed,
      quizMode: QuizMode.values.firstWhere(
        (m) => m.name == session.quizMode,
        orElse: () => QuizMode.practice,
      ),
      timeLimitSeconds: session.timeLimitSeconds,
    );
    _startAutoSave();
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!state.isCompleted && state.questions.isNotEmpty) {
        _saveSession();
      }
    });
  }

  Future<void> _saveSession() async {
    if (_currentSessionId == null || state.questions.isEmpty) return;
    try {
      await _sessionService.saveSession(
        sessionId: _currentSessionId!,
        topicId: _topicId,
        subject: _subject,
        testType: _testType,
        quizMode: _quizMode,
        timeLimitSeconds: _timeLimitSeconds,
        seed: state.seed,
        currentIndex: state.currentIndex,
        selectedAnswers: state.selectedAnswers,
        answerResults: state.answerResults,
        timeSpentPerQuestion: state.timeSpentPerQuestion,
        flaggedQuestions: state.flaggedQuestions,
        visitedQuestions: state.visitedQuestions,
        score: state.score,
        incorrectCount: state.incorrectCount,
        elapsedSeconds: state.timeElapsedSeconds,
        isCompleted: state.isCompleted,
        questionIds: state.questions.map((q) => q.id).toList(),
        questions: state.questions,
      );
    } catch (e) {
      debugPrint('❌ Auto-save failed: $e');
    }
  }

  Future<void> saveAndComplete() async {
    _autoSaveTimer?.cancel();
    await _saveSession();
    if (_currentSessionId != null) {
      await _sessionService.deleteSession(_currentSessionId!);
      _currentSessionId = null;
    }
  }

  void selectAnswer(
    int questionIndex,
    String answer,
    int timeSpent, {
    bool? isCorrect,
  }) {
    if (state.isCompleted) return;
    if (questionIndex < 0 || questionIndex >= state.questions.length) return;

    final question = state.questions[questionIndex];
    final markedCorrect = isCorrect ?? (answer == question.correctAnswer);

    int score = state.score;
    int incorrectCount = state.incorrectCount;
    final results = Map<int, bool>.from(state.answerResults);

    final alreadyAnswered = results.containsKey(questionIndex);
    if (alreadyAnswered) {
      if (results[questionIndex] == true) {
        score = score > 0 ? score - 1 : 0;
      } else {
        incorrectCount = incorrectCount > 0 ? incorrectCount - 1 : 0;
      }
    }

    results[questionIndex] = markedCorrect;
    if (markedCorrect) {
      score += 1;
    } else {
      incorrectCount += 1;
    }

    final newTimeSpent = Map<int, int>.from(state.timeSpentPerQuestion);
    newTimeSpent[questionIndex] = timeSpent;

    final visited = Set<int>.from(state.visitedQuestions)..add(questionIndex);

    state = state.copyWith(
      selectedAnswers: {...state.selectedAnswers, questionIndex: answer},
      answerResults: results,
      score: score,
      incorrectCount: incorrectCount,
      timeSpentPerQuestion: newTimeSpent,
      visitedQuestions: visited,
    );
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      final visited = Set<int>.from(state.visitedQuestions)
        ..add(state.currentIndex + 1);
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        visitedQuestions: visited,
      );
    } else {
      state = state.copyWith(isCompleted: true);
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      final visited = Set<int>.from(state.visitedQuestions)..add(index);
      state = state.copyWith(currentIndex: index, visitedQuestions: visited);
    }
  }

  void toggleFlag(int questionIndex) {
    if (questionIndex < 0 || questionIndex >= state.questions.length) return;
    final flagged = Set<int>.from(state.flaggedQuestions);
    if (flagged.contains(questionIndex)) {
      flagged.remove(questionIndex);
    } else {
      flagged.add(questionIndex);
    }
    state = state.copyWith(flaggedQuestions: flagged);
  }

  void markForReviewAndNext() {
    toggleFlag(state.currentIndex);
    nextQuestion();
  }

  void completeQuiz() {
    state = state.copyWith(isCompleted: true);
  }

  void updateTimeElapsed(int seconds) {
    state = state.copyWith(timeElapsedSeconds: seconds);
  }

  void resetQuiz() {
    state = QuizState(questions: const []);
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  final sessionService = ref.watch(quizSessionServiceProvider);
  return QuizNotifier(sessionService);
});

// ============= BOOKMARKS =============
class BookmarksNotifier extends StateNotifier<List<db.Bookmark>> {
  final db.AppDatabase _db;

  BookmarksNotifier(this._db) : super(const []) {
    loadBookmarks();
  }

  Future<void> loadBookmarks() async {
    try {
      final list = await _db.getAllBookmarks();
      state = list;
    } catch (e) {
      debugPrint('❌ Error loading bookmarks: $e');
    }
  }

  Future<void> toggleBookmark({
    required String questionId,
    required String subject,
    required String topicId,
  }) async {
    final exists = state.any((b) => b.questionId == questionId);
    try {
      if (exists) {
        await _db.removeBookmark(questionId);
      } else {
        await _db.insertBookmark(
          db.BookmarksCompanion.insert(
            questionId: questionId,
            subject: subject,
            topicId: topicId,
            bookmarkedAt: DateTime.now(),
          ),
        );
      }
      await loadBookmarks();
    } catch (e) {
      debugPrint('❌ Error toggling bookmark: $e');
    }
  }

  bool isBookmarked(String questionId) {
    return state.any((b) => b.questionId == questionId);
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, List<db.Bookmark>>((ref) {
      final database = ref.watch(databaseProvider);
      return BookmarksNotifier(database);
    });

// ============= ERROR BOOK =============
final errorBookProvider = FutureProvider<List<Question>>((ref) async {
  final dbInstance = ref.watch(databaseProvider);
  final entries = await dbInstance.getErrorBookEntries();
  final allQuestions = await ref.watch(allQuestionsProvider.future);
  final List<Question> errorQuestions = [];
  for (var entry in entries) {
    if (!entry.isResolved) {
      try {
        final question = allQuestions.firstWhere(
          (q) => q.id == entry.questionId,
        );
        errorQuestions.add(question);
      } catch (e) {
        debugPrint('⚠️ Question ${entry.questionId} not found for Error Book');
      }
    }
  }
  return errorQuestions;
});
