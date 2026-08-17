import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/question_model.dart';
import '../models/subject_model.dart';
import '../models/user_progress_model.dart';
import '../models/flashcard_model.dart';
import '../models/mark_booster_model.dart';
import '../models/spaced_repetition_model.dart';
import '../models/user_preferences_model.dart';
import '../constants/neet_sample_data.dart';
import '../config/app_config.dart';
import '../database/drift_database.dart' as db;
import '../database/question_repository.dart';
import 'package:drift/drift.dart' show Value;
import '../services/ml_service.dart';
import '../services/gemini_chat_service.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/content_sync_service.dart';
import '../services/mark_booster_service.dart';
import '../services/spaced_repetition_service.dart';

final mlServiceProvider = Provider<MLService>((ref) {
  final service = MLService();
  service.initializeModels();
  return service;
});

// ============= DATABASE PROVIDER =============
final databaseProvider = Provider<db.AppDatabase>((ref) => db.AppDatabase());

// ============= CONTENT CATALOG SYNC =============
final contentSyncServiceProvider = Provider<ContentSyncService>((ref) {
  final database = ref.watch(databaseProvider);
  final supabaseClient = AppConfig.isCloudAuthConfigured
      ? supabase.Supabase.instance.client
      : null;
  return ContentSyncService(database, supabaseClient);
});

/// Runs a content-catalog pull. Consumers that cache question filters should
/// invalidate them after awaiting this provider.
final contentSyncProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(contentSyncServiceProvider);
  await service.syncCatalog();
});

// ============= AUTH PROVIDERS =============
final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final database = ref.watch(databaseProvider);
  final emailService = ref.watch(emailServiceProvider);
  return AuthService(database, emailService);
});

final cloudSyncServiceProvider = Provider<CloudSyncService?>((ref) {
  if (!AppConfig.isCloudAuthConfigured) return null;
  final database = ref.watch(databaseProvider);
  return CloudSyncService(database, supabase.Supabase.instance.client);
});

enum AuthStatus {
  initial,
  loading,
  authenticating,
  awaitingOtp,
  awaiting2FA,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final db.User? user;
  final AuthStatus status;
  final String? error;
  final String? pendingPhone;
  final String? pendingEmail;
  final bool isGuest;

  AuthState({
    this.user,
    this.status = AuthStatus.initial,
    this.error,
    this.pendingPhone,
    this.pendingEmail,
    this.isGuest = false,
  });

  bool get isLoggedIn => user != null || isGuest;

  AuthState copyWith({
    db.User? user,
    AuthStatus? status,
    String? error,
    String? pendingPhone,
    String? pendingEmail,
    bool? isGuest,
  }) {
    return AuthState(
      user: user ?? this.user,
      status: status ?? this.status,
      error: error,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final db.AppDatabase _db;
  final Ref _ref;

  AuthNotifier(this._authService, this._db, this._ref) : super(AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final user = await _authService.tryAutoLogin();
    if (user != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isGuest: false,
      );
      _ref.read(cloudSyncServiceProvider)?.syncAll();
      return;
    }

    if (!AppConfig.isCloudAuthConfigured) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: null,
        isGuest: true,
        error: null,
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      isGuest: false,
      user: null,
    );
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: null,
      isGuest: true,
      error: null,
    );
  }

  Future<bool> toggle2FA(bool enabled) async {
    if (state.user == null) return false;
    await _db.updateTwoFactorStatus(state.user!.id, enabled);
    final updatedUser = await _db.getUserById(state.user!.id);
    state = state.copyWith(user: updatedUser);
    return true;
  }

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(status: AuthStatus.authenticating, error: null);
    final result = await _authService.sendOtp(email);
    if (result.success) {
      state = state.copyWith(
        status: AuthStatus.awaitingOtp,
        pendingEmail: email,
        pendingPhone: email,
        isGuest: false,
      );
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      error: result.message,
      isGuest: false,
    );
    return false;
  }

  Future<bool> verifyOtp(String code) async {
    final email = state.pendingEmail ?? state.pendingPhone;
    if (email == null) return false;

    state = state.copyWith(status: AuthStatus.authenticating, error: null);
    final result = await _authService.verifyOtp(email, code);
    if (result.success) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isGuest: false,
        error: null,
      );
      _ref.read(cloudSyncServiceProvider)?.syncAll();
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.awaitingOtp,
      error: result.message,
    );
    return false;
  }

  Future<bool> verify2FA(String code) async {
    final email = state.pendingEmail;
    if (email == null) return false;

    state = state.copyWith(status: AuthStatus.authenticating, error: null);
    final result = await _authService.verify2FA(email, code);
    if (result.success) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isGuest: false,
      );
      _ref.read(cloudSyncServiceProvider)?.syncAll();
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.awaiting2FA,
      error: result.message,
    );
    return false;
  }

  Future<void> resend2FA() async {
    final email = state.pendingEmail;
    if (email == null) return;

    state = state.copyWith(status: AuthStatus.authenticating, error: null);
    final result = await _authService.send2FAEmail(email);
    if (result.success) {
      state = state.copyWith(status: AuthStatus.awaiting2FA, error: null);
    } else {
      state = state.copyWith(
        status: AuthStatus.awaiting2FA,
        error: result.message,
      );
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating, error: null);
    final result = await _authService.register(
      email: email,
      username: username,
      password: password,
      fullName: fullName,
    );

    if (result.success) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isGuest: false,
      );
      _ref.read(cloudSyncServiceProvider)?.syncAll();
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      error: result.message,
    );
    return false;
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.authenticating, error: null);
    final result = await _authService.login(email: email, password: password);

    if (result.success) {
      if (result.message == '2FA_REQUIRED') {
        final emailResult = await _authService.send2FAEmail(email);
        if (emailResult.success) {
          state = state.copyWith(status: AuthStatus.awaiting2FA, pendingEmail: email);
          return true;
        } else {
          state = state.copyWith(status: AuthStatus.unauthenticated, error: emailResult.message);
          return false;
        }
      }
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isGuest: false,
      );
      _ref.read(cloudSyncServiceProvider)?.syncAll();
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      error: result.message,
    );
    return false;
  }

  Future<bool> resetPassword(String email) async {
    final result = await _authService.resetPassword(email);
    state = state.copyWith(error: result.message);
    return result.success;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final db = ref.watch(databaseProvider);
  return AuthNotifier(authService, db, ref);
});

// ============= SUBJECT & CONTENT PROVIDERS =============
final subjectsProvider = Provider<List<Subject>>((ref) {
  return subjects;
});

final subjectByIdProvider = Provider.family<Subject?, String>((ref, subjectId) {
  final allSubjects = ref.watch(subjectsProvider);
  try {
    return allSubjects.firstWhere((s) => s.id == subjectId);
  } catch (e) {
    return null;
  }
});

final chaptersProvider = Provider.family<List<Chapter>, String>((
  ref,
  subjectId,
) {
  final subject = ref.watch(subjectByIdProvider(subjectId));
  return subject?.chapters ?? [];
});

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

// ============= FLASHCARD PROVIDERS =============
final flashcardsFromDbProvider = FutureProvider<List<Flashcard>>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.getAllFlashcards();
  if (rows.isEmpty) return sampleFlashcards;
  return rows.map((r) => Flashcard(
    id: r.id,
    front: r.front,
    back: r.back,
    subject: r.subject,
    topicId: r.topicId,
    imageUrl: r.imageUrl,
    chapterId: r.chapterId,
    ncertReference: r.ncertReference,
    sourcePage: r.sourcePage,
    difficulty: r.difficulty,
    isGenerated: r.isGenerated,
    box: r.box,
    easeFactor: r.easeFactor,
    intervalDays: r.intervalDays,
    repetitions: r.repetitions,
    lapses: r.lapses,
    dueAt: r.dueAt,
    lastReviewedAt: r.lastReviewedAt,
  )).toList();
});

final flashcardsProvider = Provider<List<Flashcard>>((ref) {
  return ref.watch(flashcardsFromDbProvider).valueOrNull ?? sampleFlashcards;
});

final dueFlashcardsProvider = FutureProvider<List<Flashcard>>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.getDueFlashcards(DateTime.now());
  return rows.map((r) => Flashcard(
    id: r.id,
    front: r.front,
    back: r.back,
    subject: r.subject,
    topicId: r.topicId,
    imageUrl: r.imageUrl,
    chapterId: r.chapterId,
    ncertReference: r.ncertReference,
    sourcePage: r.sourcePage,
    difficulty: r.difficulty,
    isGenerated: r.isGenerated,
    box: r.box,
    easeFactor: r.easeFactor,
    intervalDays: r.intervalDays,
    repetitions: r.repetitions,
    lapses: r.lapses,
    dueAt: r.dueAt,
    lastReviewedAt: r.lastReviewedAt,
  )).toList();
});

final flashcardsForSubjectProvider = Provider.family<List<Flashcard>, String>((
  ref,
  subject,
) {
  final all = ref.watch(flashcardsProvider);
  return all.where((f) => f.subject == subject).toList();
});

// ============= QUESTION PROVIDERS =============
final allQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  final repository = ref.watch(questionRepositoryProvider);
  return repository.getAllQuestionsFromDb();
});

final questionsForTopicProvider = FutureProvider.family<List<Question>, String>((
  ref,
  topicId,
) async {
  final repository = ref.watch(questionRepositoryProvider);
  return repository.getQuestionsByTopicId(topicId);
});

final questionsForSubjectProvider = FutureProvider.family<List<Question>, String>((
  ref,
  subject,
) async {
  final allQuestions = await ref.watch(allQuestionsProvider.future);
  return allQuestions.where((q) => q.subject == subject).toList();
});

// ============= QUIZ STATE PROVIDERS =============
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
        type: q.type,
      );
    }).toList();
    state = QuizState(questions: randomizedQuestions);
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

    // Reverting a previously recorded answer keeps score/incorrectCount correct
    // when the user goes back and changes their response.
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

    state = state.copyWith(
      selectedAnswers: {...state.selectedAnswers, questionIndex: answer},
      answerResults: results,
      score: score,
      incorrectCount: incorrectCount,
      timeSpentPerQuestion: newTimeSpent,
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
  final Map<String, TopicProgress> topicProgress;
  final List<QuizAttempt> quizAttempts;
  final bool isLoaded;
  final int currentStreak;
  final DateTime? lastActivityDate;

  UserProgressState({
    this.topicProgress = const {},
    this.quizAttempts = const [],
    this.isLoaded = false,
    this.currentStreak = 0,
    this.lastActivityDate,
  });

  UserProgressState copyWith({
    Map<String, TopicProgress>? topicProgress,
    List<QuizAttempt>? quizAttempts,
    bool? isLoaded,
    int? currentStreak,
    DateTime? lastActivityDate,
  }) {
    return UserProgressState(
      topicProgress: topicProgress ?? this.topicProgress,
      quizAttempts: quizAttempts ?? this.quizAttempts,
      isLoaded: isLoaded ?? this.isLoaded,
      currentStreak: currentStreak ?? this.currentStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
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
  final Ref _ref;

  UserProgressNotifier(this._db, this._ref) : super(UserProgressState()) {
    _loadFromDatabase();
  }

  Future<void> _loadFromDatabase() async {
    try {
      final dbAttempts = await _db.getAllQuizAttempts();
      final attempts = dbAttempts
          .map(
            (a) => QuizAttempt(
              id: a.id.toString(),
              topicId: a.topicId,
              testType: a.testType,
              subjectScores: a.subjectScores != null
                  ? (jsonDecode(a.subjectScores!) as Map).cast<String, int>()
                  : null,
              score: a.score,
              incorrectCount: a.incorrectCount,
              totalQuestions: a.totalQuestions,
              timeSpentSeconds: a.timeSpentSeconds,
              attemptedAt: a.attemptedAt,
              selectedAnswers: (jsonDecode(a.selectedAnswers) as List)
                  .cast<String>(),
              subject: a.subject,
            ),
          )
          .toList();

      final dbProgress = await _db.getAllTopicProgress();
      final progressMap = <String, TopicProgress>{};
      for (var p in dbProgress) {
        progressMap[p.topicId] = TopicProgress(
          topicId: p.topicId,
          questionsAttempted: p.questionsAttempted,
          questionsCorrect: p.questionsCorrect,
          averageTimeSeconds: p.averageTimeSeconds,
          lastAttempted: p.lastAttempted,
          isCompleted: p.isCompleted,
        );
      }

      int currentStreak = 0;
      DateTime? lastActivityDate;
      try {
        final dbUsers = await _db.select(_db.users).get();
        if (dbUsers.isNotEmpty) {
          final user = dbUsers.first;
          currentStreak = user.currentStreak;
          lastActivityDate = user.lastActivityDate;
        }
      } catch (e) {
        debugPrint('❌ Error loading streak info: $e');
      }

      state = UserProgressState(
        quizAttempts: attempts,
        topicProgress: progressMap,
        isLoaded: true,
        currentStreak: currentStreak,
        lastActivityDate: lastActivityDate,
      );
    } catch (e) {
      debugPrint('❌ Error loading progress from database: $e');
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> recordQuizAttempt(
    QuizAttempt attempt, {
    List<Question>? questions,
    Map<int, String?>? answersByIndex,
  }) async {
    state = state.copyWith(quizAttempts: [...state.quizAttempts, attempt]);

    try {
      await _db.insertQuizAttempt(
        db.QuizAttemptsCompanion.insert(
          topicId: attempt.topicId,
          subject: attempt.subject,
          testType: Value(attempt.testType),
          subjectScores: Value(
            attempt.subjectScores != null
                ? jsonEncode(attempt.subjectScores)
                : null,
          ),
          score: attempt.score,
          incorrectCount: Value(attempt.incorrectCount),
          totalQuestions: attempt.totalQuestions,
          timeSpentSeconds: attempt.timeSpentSeconds,
          attemptedAt: attempt.attemptedAt,
          selectedAnswers: jsonEncode(attempt.selectedAnswers),
        ),
      );

      final sourceQuestions = questions ?? _ref.read(quizProvider).questions;
      final sourceAnswers =
          answersByIndex ?? _ref.read(quizProvider).selectedAnswers;
      final existingCards = await _db.getSpacedRepetitionCards();
      final srByQuestion = {
        for (final card in existingCards) card.questionId: card,
      };
      var srTouched = false;
      for (int i = 0; i < sourceQuestions.length; i++) {
        final q = sourceQuestions[i];
        final answer = sourceAnswers[i];
        if (answer == null) continue;
        final isCorrect = answer == q.correctAnswer;
        if (isCorrect) {
          await _db.removeFromErrorBook(q.id);
        } else {
          await _db.addToErrorBook(db.ErrorBookCompanion.insert(
            questionId: q.id,
            addedAt: DateTime.now(),
          ));
        }
        final nextCard = SpacedRepetitionService.review(
          questionId: q.id,
          card: srByQuestion[q.id],
          isCorrect: isCorrect,
        );
        await _db.upsertSpacedRepetition(nextCard);
        srTouched = true;
      }
      if (srTouched) {
        _ref.invalidate(spacedRepetitionCardsProvider);
        _ref.invalidate(dueCardsProvider);
        _ref.invalidate(spacedRepetitionSummaryProvider);
      }

      _ref.invalidate(errorBookProvider);
      _ref.read(dailyGoalProvider.notifier).incrementProgress(attempt.totalQuestions);
      _ref.read(cloudSyncServiceProvider)?.syncAll();

    } catch (e) {
      debugPrint('❌ Error saving quiz attempt: $e');
    }

    if ((attempt.testType == 'topic' || attempt.testType == 'booster') &&
        attempt.topicId.isNotEmpty) {
      await _updateTopicProgressFromAttempt(attempt);
    }

    await _updateStreak();
  }

  Future<void> _updateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentStreak = state.currentStreak;
    final lastActivity = state.lastActivityDate;

    int newStreak = currentStreak;

    if (lastActivity == null) {
      newStreak = 1;
    } else {
      final lastDate = DateTime(lastActivity.year, lastActivity.month, lastActivity.day);
      final difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        newStreak += 1;
      } else if (difference > 1) {
        newStreak = 1;
      }
    }

    state = state.copyWith(
      currentStreak: newStreak,
      lastActivityDate: now,
    );

    try {
      final dbUsers = await _db.select(_db.users).get();
      if (dbUsers.isNotEmpty) {
        final userId = dbUsers.first.id;
        await (_db.update(_db.users)..where((t) => t.id.equals(userId))).write(
          db.UsersCompanion(
            currentStreak: Value(newStreak),
            lastActivityDate: Value(now),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating streak in DB: $e');
    }
  }

  Future<void> _updateTopicProgressFromAttempt(QuizAttempt attempt) async {
    // Credit each question to its own topic so mixed drills improve the
    // right chapters. Falls back to the umbrella topic only for single-topic
    // attempts if the quiz state is no longer available.
    final quizState = _ref.read(quizProvider);
    final perTopic = MarkBoosterService.aggregateTopicResults(
      questions: quizState.questions,
      answerResults: quizState.answerResults,
    );
    if (perTopic.isEmpty && attempt.testType == 'topic') {
      perTopic[attempt.topicId] = (
        correct: attempt.score,
        total: attempt.totalQuestions,
      );
    }

    for (final entry in perTopic.entries) {
      final timeSpent =
          attempt.totalQuestions == 0
              ? 0.0
              : attempt.timeSpentSeconds *
                    (entry.value.total / attempt.totalQuestions);
      await _applyTopicProgress(
        topicId: entry.key,
        correct: entry.value.correct,
        total: entry.value.total,
        timeSpentSeconds: timeSpent,
        attemptedAt: attempt.attemptedAt,
      );
    }
    _ref.read(cloudSyncServiceProvider)?.syncAll();
  }

  Future<void> _applyTopicProgress({
    required String topicId,
    required int correct,
    required int total,
    required double timeSpentSeconds,
    required DateTime attemptedAt,
  }) async {
    final existing = state.topicProgress[topicId];
    final prevAttempted = existing?.questionsAttempted ?? 0;
    final prevCorrect = existing?.questionsCorrect ?? 0;
    final newAttempted = prevAttempted + total;
    final newCorrect = prevCorrect + correct;
    final newTimeSpent =
        ((existing?.averageTimeSeconds ?? 0) * prevAttempted) + timeSpentSeconds;
    final accuracy = newAttempted == 0 ? 0.0 : (newCorrect / newAttempted) * 100;

    final updatedProgress = TopicProgress(
      topicId: topicId,
      questionsAttempted: newAttempted,
      questionsCorrect: newCorrect,
      averageTimeSeconds: newAttempted > 0 ? newTimeSpent / newAttempted : 0,
      lastAttempted: attemptedAt,
      isCompleted: accuracy >= 70 && newAttempted >= 5,
    );

    final updated = {...state.topicProgress, topicId: updatedProgress};
    state = state.copyWith(topicProgress: updated);

    try {
      await _db.upsertTopicProgress(
        db.TopicProgressEntriesCompanion.insert(
          topicId: topicId,
          questionsAttempted: Value(newAttempted),
          questionsCorrect: Value(newCorrect),
          timeSpentSeconds: Value(newTimeSpent.toInt()),
          averageTimeSeconds: Value(updatedProgress.averageTimeSeconds),
          lastAttempted: attemptedAt,
          isCompleted: Value(accuracy >= 70 && newAttempted >= 5),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error saving topic progress: $e');
    }
  }

  Future<void> recordTopicView(String topicId) async {
    final existing = state.topicProgress[topicId];

    final updated = TopicProgress(
      topicId: topicId,
      questionsAttempted: existing?.questionsAttempted ?? 0,
      questionsCorrect: existing?.questionsCorrect ?? 0,
      averageTimeSeconds: existing?.averageTimeSeconds ?? 0,
      lastAttempted: DateTime.now(),
      isCompleted: existing?.isCompleted ?? false,
    );

    final updatedMap = {...state.topicProgress, topicId: updated};
    state = state.copyWith(topicProgress: updatedMap);

    try {
      await _db.upsertTopicProgress(
        db.TopicProgressEntriesCompanion.insert(
          topicId: topicId,
          questionsAttempted: Value(updated.questionsAttempted),
          questionsCorrect: Value(updated.questionsCorrect),
          timeSpentSeconds: Value(((updated.averageTimeSeconds) * updated.questionsAttempted).toInt()),
          averageTimeSeconds: Value(updated.averageTimeSeconds),
          lastAttempted: DateTime.now(),
          isCompleted: Value(updated.isCompleted),
        ),
      );
      _ref.read(cloudSyncServiceProvider)?.syncAll();
    } catch (e) {
      debugPrint('❌ Error recording topic view: $e');
    }
  }

  void updateTopicProgress(String topicId, TopicProgress progress) {
    final updated = {...state.topicProgress, topicId: progress};
    state = state.copyWith(topicProgress: updated);
  }

  Future<void> clearAllProgress() async {
    await _db.clearAllProgress();
    state = UserProgressState(isLoaded: true);
  }
}

final userProgressProvider =
    StateNotifierProvider<UserProgressNotifier, UserProgressState>((ref) {
      final database = ref.watch(databaseProvider);
      return UserProgressNotifier(database, ref);
    });

// ============= ANALYTICS PROVIDERS =============
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

final subjectStatsProvider = Provider.family<Map<String, dynamic>, String>((
  ref,
  subject,
) {
  final progress = ref.watch(userProgressProvider);
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
  final Ref _ref;

  BookmarksNotifier(this._db, this._ref) : super(const []) {
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
      _ref.read(cloudSyncServiceProvider)?.syncAll();
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
      return BookmarksNotifier(database, ref);
    });

// ============= GEMINI AI PROVIDER =============
final geminiServiceProvider = Provider<GeminiChatService>((ref) {
  final service = GeminiChatService();
  service.init();
  return service;
});

// ============= ERROR BOOK PROVIDER =============
final errorBookProvider = FutureProvider<List<Question>>((ref) async {
  final dbInstance = ref.watch(databaseProvider);
  final entries = await dbInstance.getErrorBookEntries();
  final allQuestions = await ref.watch(allQuestionsProvider.future);
  final List<Question> errorQuestions = [];
  for (var entry in entries) {
    if (!entry.isResolved) {
      try {
        final question = allQuestions.firstWhere((q) => q.id == entry.questionId);
        errorQuestions.add(question);
      } catch (e) {
        debugPrint('⚠️ Question ${entry.questionId} not found for Error Book');
      }
    }
  }
  return errorQuestions;
});

final recentActivityProvider = Provider<List<QuizAttempt>>((ref) {
  final progress = ref.watch(userProgressProvider);
  final attempts = List<QuizAttempt>.from(progress.quizAttempts);
  attempts.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
  return attempts.take(10).toList();
});

final mockTestStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final progress = ref.watch(userProgressProvider);
  final mockAttempts = progress.quizAttempts
      .where((a) => a.testType == 'mock' || a.topicId == 'mock_test')
      .toList();
  if (mockAttempts.isEmpty) {
    return {'hasMockTests': false, 'highestScore': 0, 'averageScore': 0};
  }
  int highest = 0;
  int total = 0;
  for (var attempt in mockAttempts) {
    final score = attempt.neetScore;
    if (score > highest) highest = score;
    total += score;
  }
  return {
    'hasMockTests': true,
    'highestScore': highest,
    'averageScore': total ~/ mockAttempts.length,
    'count': mockAttempts.length,
  };
});

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

// ============= MARK BOOSTER PROVIDER =============
/// Diagnostic snapshot powering the personalized drill generator.
///
/// Flags any topic attempted 2+ times with accuracy below 60% (more
/// sensitive than the dashboard's weak-topic threshold), and classifies
/// unresolved Error Book questions by type and difficulty.
final markBoosterDiagnosisProvider =
    FutureProvider<MarkBoosterDiagnosis>((ref) async {
      final progress = ref.watch(userProgressProvider);
      final allSubjects = ref.watch(subjectsProvider);
      final allQuestions = await ref.watch(allQuestionsProvider.future);
      final errorQuestions = await ref.watch(errorBookProvider.future);

      final weakTopics = <WeakTopicDiagnosis>[];
      final masteredTopics = <MasteredTopic>[];
      for (var subject in allSubjects) {
        for (var chapter in subject.chapters) {
          for (var topic in chapter.topics) {
            final topicProgress = progress.topicProgress[topic.id];
            if (topicProgress == null) continue;
            if (MarkBoosterService.isTopicMastered(
              topicProgress.questionsAttempted,
              topicProgress.accuracy,
            )) {
              masteredTopics.add(
                MasteredTopic(
                  name: topic.name,
                  chapterName: chapter.name,
                  subjectName: subject.name,
                  accuracy: topicProgress.accuracy,
                ),
              );
            } else if (topicProgress.questionsAttempted >= 2 &&
                topicProgress.accuracy < 60) {
              final available = allQuestions
                  .where((q) => q.topicId == topic.id)
                  .length;
              weakTopics.add(
                WeakTopicDiagnosis(
                  topic: topic,
                  subjectName: subject.name,
                  chapterName: chapter.name,
                  questionsAttempted: topicProgress.questionsAttempted,
                  questionsCorrect: topicProgress.questionsCorrect,
                  questionsAvailable: available,
                ),
              );
            }
          }
        }
      }
      weakTopics.sort((a, b) => a.accuracy.compareTo(b.accuracy));

      final typeCounts = <String, int>{};
      final difficultyCounts = <String, int>{};
      for (final q in errorQuestions) {
        final type = q.type.isEmpty ? 'MCQ' : q.type;
        final difficulty = q.difficulty.isEmpty ? 'Medium' : q.difficulty;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
        difficultyCounts[difficulty] = (difficultyCounts[difficulty] ?? 0) + 1;
      }

      final totalErrors = errorQuestions.length;
      final typeWeaknesses = typeCounts.entries
          .map(
            (e) => TypeWeakness(
              type: e.key,
              errorCount: e.value,
              shareOfErrors: totalErrors == 0
                  ? 0
                  : (e.value / totalErrors) * 100,
            ),
          )
          .toList()
        ..sort((a, b) => b.errorCount.compareTo(a.errorCount));

      final difficultyWeaknesses = difficultyCounts.entries
          .map(
            (e) => DifficultyWeakness(
              difficulty: e.key,
              errorCount: e.value,
              shareOfErrors: totalErrors == 0
                  ? 0
                  : (e.value / totalErrors) * 100,
            ),
          )
          .toList()
        ..sort((a, b) => b.errorCount.compareTo(a.errorCount));

      return MarkBoosterDiagnosis(
        weakTopics: weakTopics,
        typeWeaknesses: typeWeaknesses,
        difficultyWeaknesses: difficultyWeaknesses,
        errorBookQuestions: errorQuestions,
        masteredTopics: masteredTopics,
      );
    });

class DailyGoalNotifier extends StateNotifier<Map<String, dynamic>> {
  final db.AppDatabase _db;
  final Ref _ref;

  DailyGoalNotifier(this._db, this._ref)
      : super({
          'target': 50,
          'completed': 0,
          'percent': 0.0,
          'date': DateTime.now(),
          'status': 'pending',
        }) {
    _loadTodayGoal();
  }

  int _recommendedTarget() {
    return _ref.read(userPreferencesProvider).recommendedDailyTarget;
  }

  Future<void> _loadTodayGoal() async {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    try {
      final goal = await _db.getDailyGoal(dateOnly);
      if (goal != null) {
        state = {
          'target': goal.target,
          'completed': goal.completed,
          'percent': (goal.completed / goal.target).clamp(0.0, 1.0),
          'date': goal.date,
          'status': goal.status,
        };
      } else {
        final target = _recommendedTarget();
        await _db.upsertDailyGoal(
          db.DailyGoalsCompanion(
            date: Value(dateOnly),
            target: Value(target),
            completed: const Value(0),
            status: const Value('pending'),
          ),
        );
        state = {
          'target': target,
          'completed': 0,
          'percent': 0.0,
          'date': dateOnly,
          'status': 'pending',
        };
      }
    } catch (e) {
      debugPrint('❌ Error loading daily goal: $e');
    }
  }

  Future<void> updateDailyGoal(int completed) async {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    try {
      await _db.upsertDailyGoal(
        db.DailyGoalsCompanion(
          date: Value(dateOnly),
          target: Value(state['target'] as int),
          completed: Value(completed),
          status: Value(
            completed >= (state['target'] as int) ? 'completed' : 'in_progress',
          ),
        ),
      );
      state = {
        'target': state['target'],
        'completed': completed,
        'percent': (completed / (state['target'] as int)).clamp(0.0, 1.0),
        'date': dateOnly,
        'status': completed >= (state['target'] as int)
            ? 'completed'
            : 'in_progress',
      };
    } catch (e) {
      debugPrint('❌ Error updating daily goal: $e');
    }
  }

  Future<void> incrementProgress(int count) async {
    final currentCompleted = state['completed'] as int;
    await updateDailyGoal(currentCompleted + count);
  }

  Future<void> resetGoal() async {
    await _loadTodayGoal();
  }
}

final dailyGoalProvider =
    StateNotifierProvider<DailyGoalNotifier, Map<String, dynamic>>((ref) {
      final database = ref.watch(databaseProvider);
      return DailyGoalNotifier(database, ref);
    });

// ============= SPACED REPETITION PROVIDERS =============
final spacedRepetitionCardsProvider =
    FutureProvider<List<db.SpacedRepetitionData>>(
      (ref) => ref.watch(databaseProvider).getSpacedRepetitionCards(),
    );

final spacedRepetitionSummaryProvider = FutureProvider<SpacedRepetitionSummary>(
  (ref) async {
    final cards = await ref.watch(spacedRepetitionCardsProvider.future);
    final now = DateTime.now();
    return SpacedRepetitionSummary(
      totalCards: cards.length,
      dueCount: cards.where((c) => !c.dueAt.isAfter(now)).length,
      inLearning: cards.where((c) => c.box <= 1).length,
      mastered: cards.where((c) => c.box >= 4).length,
    );
  },
);

/// Questions whose scheduling card is currently due, soonest due first.
final dueCardsProvider = FutureProvider<List<Question>>((ref) async {
  final dbInstance = ref.watch(databaseProvider);
  final due = await dbInstance.getDueSpacedRepetition(DateTime.now());
  if (due.isEmpty) return const [];
  final allQuestions = await ref.watch(allQuestionsProvider.future);
  final byId = {for (final q in allQuestions) q.id: q};
  return due
      .map((card) => byId[card.questionId])
      .whereType<Question>()
      .toList();
});

/// Helper for persisting a single spaced-repetition answer from a review
/// session (also keeps the Error Book in sync).
final spacedReviewRecorderProvider = Provider<SpacedReviewRecorder>((ref) {
  return SpacedReviewRecorder(ref);
});

class SpacedReviewRecorder {
  SpacedReviewRecorder(this._ref);
  final Ref _ref;

  Future<void> recordAnswer({
    required String questionId,
    required bool isCorrect,
  }) async {
    final dbInstance = _ref.read(databaseProvider);
    final card = await dbInstance.getSpacedRepetition(questionId);
    final next = SpacedRepetitionService.review(
      questionId: questionId,
      card: card,
      isCorrect: isCorrect,
    );
    await dbInstance.upsertSpacedRepetition(next);
    if (isCorrect) {
      await dbInstance.removeFromErrorBook(questionId);
    } else {
      await dbInstance.addToErrorBook(db.ErrorBookCompanion.insert(
        questionId: questionId,
        addedAt: DateTime.now(),
      ));
    }
    _ref.invalidate(spacedRepetitionCardsProvider);
    _ref.invalidate(dueCardsProvider);
    _ref.invalidate(spacedRepetitionSummaryProvider);
    _ref.invalidate(errorBookProvider);
  }
}

// ============= USER PREFERENCES (BATCH ONBOARDING) =============
final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
      return UserPreferencesNotifier(ref.watch(databaseProvider), ref);
    });

/// Weak topics filtered to the user's batch syllabus (Class 11 / 12 only see
/// their NCERT chapters; droppers and un-triaged users see everything).
final studyPlanTopicsProvider = Provider<List<Topic>>((ref) {
  final weak = ref.watch(weakTopicsProvider);
  final prefs = ref.watch(userPreferencesProvider);
  final subjects = ref.watch(subjectsProvider);
  return UserPreferences.filterTopicsByBatch(
    weak,
    batch: prefs.batch,
    subjects: subjects,
  );
});

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier(this._db, this._ref)
    : super(const UserPreferences()) {
    _load();
  }

  static const _batchKey = 'neet_batch';
  static const _yearKey = 'neet_target_year';
  static const _commitmentKey = 'neet_daily_commitment_minutes';
  static const _onboardedKey = 'batch_onboarding_complete';

  final db.AppDatabase _db;
  final Ref _ref;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = UserPreferences(
        batch: prefs.getString(_batchKey),
        targetYear: prefs.getInt(_yearKey),
        dailyCommitmentMinutes: prefs.getInt(_commitmentKey),
        isOnboarded: prefs.getBool(_onboardedKey) ?? false,
      );
    } catch (e) {
      debugPrint('❌ Error loading user preferences: $e');
    }
  }

  Future<void> save({
    required String? batch,
    required int? targetYear,
    required int? dailyCommitmentMinutes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (batch != null) await prefs.setString(_batchKey, batch);
      if (targetYear != null) await prefs.setInt(_yearKey, targetYear);
      if (dailyCommitmentMinutes != null) {
        await prefs.setInt(_commitmentKey, dailyCommitmentMinutes);
      }
      await prefs.setBool(_onboardedKey, true);

      // Write-through to the users table when a local profile exists.
      final user = _ref.read(authProvider).user;
      if (user != null) {
        await _db.updateUserPreferences(
          user.id,
          batch: batch,
          targetYear: targetYear,
          dailyCommitmentMinutes: dailyCommitmentMinutes,
        );
      }

      state = state.copyWith(
        batch: batch ?? state.batch,
        targetYear: targetYear ?? state.targetYear,
        dailyCommitmentMinutes:
            dailyCommitmentMinutes ?? state.dailyCommitmentMinutes,
        isOnboarded: true,
      );
    } catch (e) {
      debugPrint('❌ Error saving user preferences: $e');
    }
  }
}

// ============= THEME PROVIDER =============
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }
  static const _themeKey = 'theme_mode';
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null) {
      state = ThemeMode.values[themeIndex];
    }
  }
  Future<void> toggleTheme(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, state.index);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// ============= PREMIUM HOME TOGGLE =============
class PremiumHomeNotifier extends StateNotifier<bool> {
  PremiumHomeNotifier() : super(false) {
    _load();
  }

  static const _key = 'use_premium_home';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

final usePremiumHomeProvider =
    StateNotifierProvider<PremiumHomeNotifier, bool>((ref) {
      return PremiumHomeNotifier();
    });
