import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/question_model.dart';
import '../models/subject_model.dart';
import '../models/user_progress_model.dart';
import '../constants/neet_sample_data.dart';
import '../database/drift_database.dart' as db;
import '../database/question_repository.dart';
import 'package:drift/drift.dart' show Value;
import '../services/gemini_chat_service.dart';

// ============= SUBJECT & CONTENT PROVIDERS =============

// Get all subjects with their chapters and topics
final subjectsProvider = Provider<List<Subject>>((ref) {
  return subjects;
});

// Get a specific subject by ID
final subjectByIdProvider = Provider.family<Subject?, String>((ref, subjectId) {
  final allSubjects = ref.watch(subjectsProvider);
  try {
    return allSubjects.firstWhere((s) => s.id == subjectId);
  } catch (e) {
    return null;
  }
});

// Get chapters for a subject
final chaptersProvider = Provider.family<List<Chapter>, String>((
  ref,
  subjectId,
) {
  final subject = ref.watch(subjectByIdProvider(subjectId));
  return subject?.chapters ?? [];
});

// Get topics for a chapter
final topicsProvider = Provider.family<List<Topic>, String>((ref, chapterId) {
  final allSubjects = ref.watch(subjectsProvider);
  for (var subject in allSubjects) {
    for (var chapter in subject.chapters) {
      if (chapter.id == chapterId) {
        return chapter.topics;
      }
    }
  }
  return [];
});

// ============= QUESTION PROVIDERS =============

// Get all questions
final allQuestionsProvider = Provider<List<Question>>((ref) {
  return getAllQuestions();
});

// Get questions for a specific topic
final questionsForTopicProvider = Provider.family<List<Question>, String>((
  ref,
  topicId,
) {
  return getQuestionsForTopic(topicId);
});

// Get questions for a subject
final questionsForSubjectProvider = Provider.family<List<Question>, String>((
  ref,
  subject,
) {
  final allQuestions = ref.watch(allQuestionsProvider);
  return allQuestions.where((q) => q.subject == subject).toList();
});

// ============= QUIZ STATE PROVIDERS =============

class QuizState {
  final List<Question> questions;
  final int currentIndex;
  final Map<int, String> selectedAnswers;
  final int score;
  final int timeElapsedSeconds;
  final bool isCompleted;

  QuizState({
    required this.questions,
    this.currentIndex = 0,
    this.selectedAnswers = const {},
    this.score = 0,
    this.timeElapsedSeconds = 0,
    this.isCompleted = false,
  });

  QuizState copyWith({
    List<Question>? questions,
    int? currentIndex,
    Map<int, String>? selectedAnswers,
    int? score,
    int? timeElapsedSeconds,
    bool? isCompleted,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      score: score ?? this.score,
      timeElapsedSeconds: timeElapsedSeconds ?? this.timeElapsedSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  double get accuracy {
    if (selectedAnswers.isEmpty) return 0.0;
    return (score / selectedAnswers.length) * 100;
  }

  int get remaining => questions.length - selectedAnswers.length;
}

// Quiz state notifier
class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(QuizState(questions: const []));

  void initializeQuiz(List<Question> questions) {
    final random = Random(DateTime.now().microsecondsSinceEpoch);
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
      );
    }).toList();
    state = QuizState(questions: randomizedQuestions);
  }

  void selectAnswer(int questionIndex, String answer) {
    if (state.isCompleted) return;

    final isCorrect = answer == state.questions[questionIndex].correctAnswer;

    state = state.copyWith(
      selectedAnswers: {...state.selectedAnswers, questionIndex: answer},
      score: isCorrect ? state.score + 1 : state.score,
    );
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    } else {
      state = state.copyWith(isCompleted: true);
    }
  }

  void completeQuiz() {
    state = state.copyWith(isCompleted: true);
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
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

// ============= USER PROGRESS PROVIDERS (PERSISTED) =============

class UserProgressState {
  final Map<String, UserProgress> topicProgress;
  final List<QuizAttempt> quizAttempts;
  final bool isLoaded;

  UserProgressState({
    this.topicProgress = const {},
    this.quizAttempts = const [],
    this.isLoaded = false,
  });

  UserProgressState copyWith({
    Map<String, UserProgress>? topicProgress,
    List<QuizAttempt>? quizAttempts,
    bool? isLoaded,
  }) {
    return UserProgressState(
      topicProgress: topicProgress ?? this.topicProgress,
      quizAttempts: quizAttempts ?? this.quizAttempts,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  int get totalQuestionsAttempted {
    return quizAttempts.fold(0, (sum, attempt) => sum + attempt.totalQuestions);
  }

  int get totalQuestionsCorrect {
    return quizAttempts.fold(0, (sum, attempt) => sum + attempt.score);
  }

  double get overallAccuracy {
    if (totalQuestionsAttempted == 0) return 0.0;
    return (totalQuestionsCorrect / totalQuestionsAttempted) * 100;
  }

  int get topicsCompleted {
    return topicProgress.values.where((p) => p.isCompleted).length;
  }
}

class UserProgressNotifier extends StateNotifier<UserProgressState> {
  final db.AppDatabase _db;

  UserProgressNotifier(this._db) : super(UserProgressState()) {
    _loadFromDatabase();
  }

  /// Load all saved progress from the database on startup
  Future<void> _loadFromDatabase() async {
    try {
      // Load quiz attempts
      final dbAttempts = await _db.getAllQuizAttempts();
      final attempts = dbAttempts.map((a) => QuizAttempt(
        id: a.id.toString(),
        topicId: a.topicId,
        testType: a.testType,
        subjectScores: a.subjectScores != null ? (jsonDecode(a.subjectScores!) as Map).cast<String, int>() : null,
        score: a.score,
        totalQuestions: a.totalQuestions,
        timeSpentSeconds: a.timeSpentSeconds,
        attemptedAt: a.attemptedAt,
        selectedAnswers: (jsonDecode(a.selectedAnswers) as List).cast<String>(),
        subject: a.subject,
      )).toList();

      // Load topic progress
      final dbProgress = await _db.getAllTopicProgress();
      final progressMap = <String, UserProgress>{};
      for (var p in dbProgress) {
        progressMap[p.topicId] = UserProgress(
          topicId: p.topicId,
          questionsAttempted: p.questionsAttempted,
          questionsCorrect: p.questionsCorrect,
          timeSpentSeconds: p.timeSpentSeconds,
          lastAttempted: p.lastAttempted,
          isCompleted: p.isCompleted,
        );
      }

      state = UserProgressState(
        quizAttempts: attempts,
        topicProgress: progressMap,
        isLoaded: true,
      );
      debugPrint('✅ Loaded ${attempts.length} quiz attempts and ${progressMap.length} topic progress entries from database');
    } catch (e) {
      debugPrint('❌ Error loading progress from database: $e');
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> recordQuizAttempt(QuizAttempt attempt) async {
    // Update in-memory state
    state = state.copyWith(quizAttempts: [...state.quizAttempts, attempt]);

    // Persist to database
    try {
      await _db.insertQuizAttempt(db.QuizAttemptsCompanion.insert(
        topicId: attempt.topicId,
        subject: attempt.subject,
        testType: Value(attempt.testType),
        subjectScores: Value(attempt.subjectScores != null ? jsonEncode(attempt.subjectScores) : null),
        score: attempt.score,
        totalQuestions: attempt.totalQuestions,
        timeSpentSeconds: attempt.timeSpentSeconds,
        attemptedAt: attempt.attemptedAt,
        selectedAnswers: jsonEncode(attempt.selectedAnswers),
      ));
      debugPrint('✅ Quiz attempt saved to database');
    } catch (e) {
      debugPrint('❌ Error saving quiz attempt: $e');
    }

    // Only update topic progress if it's a topic-specific quiz
    if (attempt.testType == 'topic' && attempt.topicId.isNotEmpty) {
      await _updateTopicProgressFromAttempt(attempt);
    }
  }

  Future<void> _updateTopicProgressFromAttempt(QuizAttempt attempt) async {
    final existing = state.topicProgress[attempt.topicId];

    final newAttempted = (existing?.questionsAttempted ?? 0) + attempt.totalQuestions;
    final newCorrect = (existing?.questionsCorrect ?? 0) + attempt.score;
    final newTimeSpent = (existing?.timeSpentSeconds ?? 0) + attempt.timeSpentSeconds;
    final accuracy = newAttempted == 0 ? 0.0 : (newCorrect / newAttempted) * 100;

    final updatedProgress = UserProgress(
      topicId: attempt.topicId,
      questionsAttempted: newAttempted,
      questionsCorrect: newCorrect,
      timeSpentSeconds: newTimeSpent,
      lastAttempted: attempt.attemptedAt,
      isCompleted: accuracy >= 70 && newAttempted >= 5,
    );

    // Update in-memory
    final updated = {...state.topicProgress, attempt.topicId: updatedProgress};
    state = state.copyWith(topicProgress: updated);

    // Persist to database
    try {
      await _db.upsertTopicProgress(db.TopicProgressEntriesCompanion.insert(
        topicId: attempt.topicId,
        questionsAttempted: Value(newAttempted),
        questionsCorrect: Value(newCorrect),
        timeSpentSeconds: Value(newTimeSpent),
        lastAttempted: attempt.attemptedAt,
        isCompleted: Value(accuracy >= 70 && newAttempted >= 5),
      ));
    } catch (e) {
      debugPrint('❌ Error saving topic progress: $e');
    }
  }

  void updateTopicProgress(String topicId, UserProgress progress) {
    final updated = {...state.topicProgress, topicId: progress};
    state = state.copyWith(topicProgress: updated);
  }

  double getTopicAccuracy(String topicId) {
    final progress = state.topicProgress[topicId];
    return progress?.accuracy ?? 0.0;
  }

  bool isTopicCompleted(String topicId) {
    return state.topicProgress[topicId]?.isCompleted ?? false;
  }
}

final userProgressProvider =
    StateNotifierProvider<UserProgressNotifier, UserProgressState>((ref) {
      final database = ref.watch(databaseProvider);
      return UserProgressNotifier(database);
    });

// Get overall statistics
final overallStatsProvider = Provider((ref) {
  final progress = ref.watch(userProgressProvider);
  return {
    'totalAttempted': progress.totalQuestionsAttempted,
    'totalCorrect': progress.totalQuestionsCorrect,
    'accuracy': progress.overallAccuracy,
    'topicsCompleted': progress.topicsCompleted,
    'quizCount': progress.quizAttempts.length,
  };
});

// Get subject-wise statistics — FIXED: now properly filters by subject
final subjectStatsProvider = Provider.family<Map<String, dynamic>, String>((
  ref,
  subject,
) {
  final progress = ref.watch(userProgressProvider);

  // Filter attempts by subject name
  final subjectAttempts = progress.quizAttempts
      .where((attempt) => attempt.subject == subject)
      .toList();

  int correct = 0;
  int total = 0;

  for (var attempt in subjectAttempts) {
    correct += attempt.score;
    total += attempt.totalQuestions;
  }

  return {
    'subject': subject,
    'totalQuestions': total,
    'correctAnswers': correct,
    'accuracy': total == 0 ? 0.0 : (correct / total) * 100,
    'attemptCount': subjectAttempts.length,
  };
});

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
      debugPrint("❌ Error loading bookmarks: $e");
    }
  }

  Future<void> toggleBookmark({
    required int questionId,
    required String subject,
    required String topicId,
  }) async {
    final exists = state.any((b) => b.questionId == questionId);
    try {
      if (exists) {
        await _db.removeBookmark(questionId);
        debugPrint("🗑️ Bookmark removed: $questionId");
      } else {
        await _db.insertBookmark(db.BookmarksCompanion.insert(
          questionId: questionId,
          subject: subject,
          topicId: topicId,
          bookmarkedAt: DateTime.now(),
        ));
        debugPrint("📌 Bookmark added: $questionId");
      }
      await loadBookmarks();
    } catch (e) {
      debugPrint("❌ Error toggling bookmark: $e");
    }
  }

  bool isBookmarked(int questionId) {
    return state.any((b) => b.questionId == questionId);
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, List<db.Bookmark>>((ref) {
      final database = ref.watch(databaseProvider);
      return BookmarksNotifier(database);
    });

// ============= GEMINI AI PROVIDER =============

final geminiServiceProvider = Provider<GeminiChatService>((ref) {
  final service = GeminiChatService();
  service.init();
  return service;
});

// ============= ANALYTICS PROVIDERS =============

// Identify topics with accuracy < 50%
final weakTopicsProvider = Provider<List<Topic>>((ref) {
  final progress = ref.watch(userProgressProvider);
  final allSubjects = ref.watch(subjectsProvider);

  final List<Topic> weakTopics = [];

  for (var subject in allSubjects) {
    for (var chapter in subject.chapters) {
      for (var topic in chapter.topics) {
        final topicProgress = progress.topicProgress[topic.id];
        if (topicProgress != null &&
            topicProgress.questionsAttempted >= 5 &&
            topicProgress.accuracy < 50) {
          weakTopics.add(topic);
        }
      }
    }
  }

  return weakTopics;
});

// Last 10 quiz attempts with timestamps
final recentActivityProvider = Provider<List<QuizAttempt>>((ref) {
  final progress = ref.watch(userProgressProvider);
  final attempts = List<QuizAttempt>.from(progress.quizAttempts);
  attempts.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
  return attempts.take(10).toList();
});

// Tracks daily question target
final dailyGoalProvider = Provider((ref) {
  final progress = ref.watch(userProgressProvider);
  const target = 50;

  final today = DateTime.now();
  final todayAttempts = progress.quizAttempts.where((a) {
    return a.attemptedAt.year == today.year &&
        a.attemptedAt.month == today.month &&
        a.attemptedAt.day == today.day;
  });

  final completed = todayAttempts.fold(0, (sum, a) => sum + a.totalQuestions);

  return {
    'target': target,
    'completed': completed,
    'percent': (completed / target).clamp(0.0, 1.0),
  };
});
