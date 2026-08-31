import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../database/drift_database.dart' as db;
import 'core_providers.dart';
import 'content_providers.dart';

// ============= QUIZ STATE =============
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
    );
  }

  double get accuracy {
    if (selectedAnswers.isEmpty) return 0.0;
    return (score / selectedAnswers.length) * 100;
  }

  int get remaining => questions.length - selectedAnswers.length;
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(QuizState(questions: const []));

  void initializeQuiz(List<Question> questions, {int? seed}) {
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
    );
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
  return QuizNotifier();
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
