import 'dart:convert';
import 'dart:math' show Random;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../models/subject_model.dart';
import '../models/user_progress_model.dart';
import '../database/drift_database.dart' as db;
import '../services/exam_engine_service.dart';
import '../services/mark_booster_service.dart';
import '../services/spaced_repetition_service.dart';
import 'core_providers.dart';
import 'content_providers.dart';
import 'quiz_providers.dart';
import 'spaced_providers.dart';
import 'settings_providers.dart';

// ============= USER PROGRESS =============
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
              rawScore: a.rawScore,
              maxMarks: a.maxMarks,
              seed: a.seed,
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

  int _generateSeed() {
    final random = Random();
    return random.nextInt(0x7FFFFFFF);
  }

  Future<void> recordQuizAttempt(
    QuizAttempt attempt, {
    List<Question>? questions,
    Map<int, String?>? answersByIndex,
    int? seed,
  }) async {
    state = state.copyWith(quizAttempts: [...state.quizAttempts, attempt]);

    try {
      final sourceQuestions = questions ?? _ref.read(quizProvider).questions;
      final sourceAnswers =
          answersByIndex ?? _ref.read(quizProvider).selectedAnswers;
      var srTouched = false;

      // Attempt insert + error-book + spaced-repetition writes are one atomic
      // unit, so a mid-write failure can't leave a half-recorded attempt.
      await _db.transaction<int>(() async {
        final id = await _db.insertQuizAttempt(
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
            rawScore: Value(attempt.rawScore),
            maxMarks: Value(attempt.maxMarks),
            questionIds: Value(
              jsonEncode(sourceQuestions.map((q) => q.id).toList()),
            ),
            seed: seed != null ? Value(seed) : Value(_generateSeed()),
          ),
        );

        final existingCards = await _db.getSpacedRepetitionCards();
        final srByQuestion = {
          for (final card in existingCards) card.questionId: card,
        };
        for (int i = 0; i < sourceQuestions.length; i++) {
          final q = sourceQuestions[i];
          final answer = sourceAnswers[i];
          if (answer == null) continue;
          final isCorrect = ExamEngineService.isAnswerCorrect(answer, q);
          if (isCorrect) {
            await _db.removeFromErrorBook(q.id);
          } else {
            await _db.addToErrorBook(
              db.ErrorBookCompanion.insert(
                questionId: q.id,
                addedAt: DateTime.now(),
              ),
            );
          }
          final nextCard = SpacedRepetitionService.review(
            questionId: q.id,
            card: srByQuestion[q.id],
            isCorrect: isCorrect,
          );
          await _db.upsertSpacedRepetition(nextCard);
          srTouched = true;
        }
        return id;
      });

      if (srTouched) {
        _ref.invalidate(spacedRepetitionCardsProvider);
        _ref.invalidate(dueCardsProvider);
        _ref.invalidate(spacedRepetitionSummaryProvider);
      }

      _ref.invalidate(errorBookProvider);
      _ref
          .read(dailyGoalProvider.notifier)
          .incrementProgress(attempt.totalQuestions);
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
      final lastDate = DateTime(
        lastActivity.year,
        lastActivity.month,
        lastActivity.day,
      );
      final difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        newStreak += 1;
      } else if (difference > 1) {
        newStreak = 1;
      }
    }

    state = state.copyWith(currentStreak: newStreak, lastActivityDate: now);

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
      final timeSpent = attempt.totalQuestions == 0
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
        ((existing?.averageTimeSeconds ?? 0) * prevAttempted) +
        timeSpentSeconds;
    final accuracy = newAttempted == 0
        ? 0.0
        : (newCorrect / newAttempted) * 100;

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
          timeSpentSeconds: Value(
            ((updated.averageTimeSeconds) * updated.questionsAttempted).toInt(),
          ),
          averageTimeSeconds: Value(updated.averageTimeSeconds),
          lastAttempted: DateTime.now(),
          isCompleted: Value(updated.isCompleted),
        ),
      );
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

// ============= ANALYTICS =============
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

// ============= DAILY GOAL =============
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
