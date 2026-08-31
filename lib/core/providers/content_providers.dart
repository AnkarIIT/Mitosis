import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/question_model.dart';
import '../models/subject_model.dart';
import '../models/flashcard_model.dart';
import '../constants/neet_sample_data.dart';
import '../config/app_config.dart';
import '../database/question_repository.dart';
import '../services/content_sync_service.dart';
import '../services/question_history_service.dart';
import '../services/dpp_engine.dart';
import '../services/mastery_service.dart';
import 'core_providers.dart';
import '../database/drift_database.dart' as db;

// ============= SUBJECT & CONTENT =============
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

// ============= FLASHCARDS =============
final flashcardsFromDbProvider = FutureProvider<List<Flashcard>>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.getAllFlashcards();
  if (rows.isEmpty) return sampleFlashcards;
  return rows
      .map(
        (r) => Flashcard(
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
        ),
      )
      .toList();
});

final flashcardsProvider = Provider<List<Flashcard>>((ref) {
  return ref.watch(flashcardsFromDbProvider).valueOrNull ?? sampleFlashcards;
});

final dueFlashcardsProvider = FutureProvider<List<Flashcard>>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.getDueFlashcards(DateTime.now());
  return rows
      .map(
        (r) => Flashcard(
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
        ),
      )
      .toList();
});

final flashcardsForSubjectProvider = Provider.family<List<Flashcard>, String>((
  ref,
  subject,
) {
  final all = ref.watch(flashcardsProvider);
  return all.where((f) => f.subject == subject).toList();
});

// ============= QUESTIONS =============
final recentlySeenQuestionIdsProvider =
    FutureProvider.family<Set<String>, String?>((ref, subject) async {
      final database = ref.watch(databaseProvider);
      final history = QuestionHistoryService(database);
      return history.getRecentSeenQuestionIds(subject: subject);
    });

final allQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  final repository = ref.watch(questionRepositoryProvider);
  final all = await repository.getAllQuestionsFromDb();
  final seen = await ref.watch(recentlySeenQuestionIdsProvider(null).future);
  if (seen.isEmpty) return all;
  return all.where((q) => !seen.contains(q.id)).toList();
});

final questionsForTopicProvider = FutureProvider.family<List<Question>, String>(
  (ref, topicId) async {
    final repository = ref.watch(questionRepositoryProvider);
    final all = await repository.getQuestionsByTopicId(topicId);
    final seen = await ref.watch(recentlySeenQuestionIdsProvider(null).future);
    final unseen = seen.isEmpty
        ? all
        : all.where((q) => !seen.contains(q.id)).toList();
    // Sample to avoid exhausting the full topic pool in one quiz.
    final max = unseen.length > 20 ? 20 : unseen.length;
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    unseen.shuffle(random);
    return unseen.take(max).toList();
  },
);

final questionsForSubjectProvider =
    FutureProvider.family<List<Question>, String>((ref, subject) async {
      final allQuestions = await ref.watch(allQuestionsProvider.future);
      return allQuestions.where((q) => q.subject == subject).toList();
    });

// ============= CONTENT CATALOG SYNC =============
final contentSyncServiceProvider = Provider<ContentSyncService?>((ref) {
  if (!AppConfig.enableCloudAuth || !AppConfig.isCloudAuthConfigured) {
    return null;
  }
  try {
    final database = ref.watch(databaseProvider);
    return ContentSyncService(database, supabase.Supabase.instance.client);
  } catch (e) {
    developer.log('Supabase not initialized: $e');
    return null;
  }
});

final contentSyncProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(contentSyncServiceProvider);
  if (service == null) return;
  await service.syncCatalog();
});

// ============= DPP (DAILY PRACTICE PAPER) =============

final dppEngineProvider = Provider<DppEngine>((ref) {
  final database = ref.watch(databaseProvider);
  final questionRepo = QuestionRepository(database);
  final history = QuestionHistoryService(database);
  final mastery = MasteryService(
    database,
    questionRepo.getAllQuestionsFromDb(),
  );
  return DppEngine(database, questionRepo, history, mastery);
});

final todayDppProvider = FutureProvider.family<DppResult?, String>((
  ref,
  subject,
) async {
  final engine = ref.watch(dppEngineProvider);
  return await engine.generate(DppConfig.single(subject: subject));
});

// ============= DPP ANALYTICS =============

final dppStreakProvider = FutureProvider<int>((ref) async {
  final database = ref.watch(databaseProvider);
  return await _computeDppStreak(database);
});

final dppWeeklyAccuracyProvider = FutureProvider<Map<DateTime, double>>((
  ref,
) async {
  final database = ref.watch(databaseProvider);
  return await _computeWeeklyAccuracy(database);
});

Future<int> _computeDppStreak(db.AppDatabase database) async {
  try {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final rows = await database.getDppSets();
    final allSets = List.from(rows);

    final byDate = <DateTime, dynamic>{};
    for (final s in allSets) {
      final parts = (s as dynamic).date.split('-');
      if (parts.length != 3) continue;
      final d = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final existing = byDate[d];
      if (existing == null ||
          (s as dynamic).updatedAt.isAfter((existing as dynamic).updatedAt)) {
        byDate[d] = s;
      }
    }

    int streak = 0;
    DateTime check = today;
    while (true) {
      final key = DateTime(check.year, check.month, check.day);
      final daySet = byDate[key];
      if (daySet != null && (daySet as dynamic).isCompleted) {
        streak += 1;
        check = key.subtract(const Duration(days: 1));
      } else if (key == today) {
        check = key.subtract(const Duration(days: 1));
        continue;
      } else {
        break;
      }
    }

    return streak;
  } catch (e) {
    return 0;
  }
}

Future<Map<DateTime, double>> _computeWeeklyAccuracy(
  db.AppDatabase database,
) async {
  try {
    final now = DateTime.now();
    final result = <DateTime, double>{};

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final sets = await (database.select(
        database.dppSets,
      )..where((t) => t.date.equals(dateStr))).get();

      if (sets.isEmpty) {
        result[DateTime(day.year, day.month, day.day)] = 0.0;
        continue;
      }

      int totalCorrect = 0;
      int totalQuestions = 0;
      for (final s in sets) {
        if (!(s as dynamic).isCompleted) continue;
        totalCorrect += (s as dynamic).correctCount as int;
        totalQuestions += (s as dynamic).totalQuestions as int;
      }

      final accuracy = totalQuestions == 0
          ? 0.0
          : (totalCorrect / totalQuestions) * 100;
      result[DateTime(day.year, day.month, day.day)] = accuracy;
    }

    return result;
  } catch (e) {
    return {};
  }
}
