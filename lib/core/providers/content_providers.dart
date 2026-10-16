import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/question_model.dart';
import '../models/subject_model.dart' as subject_model;
import '../models/study_resource.dart';
import '../models/learning_recommendation.dart';
import '../models/study_resource_content.dart';
import '../services/ncert_book_catalog.dart';
import '../services/chapter_service.dart';
import '../models/flashcard_model.dart';
import '../models/chapter_model.dart';
import '../constants/neet_sample_data.dart';
import '../config/app_config.dart';
import '../database/question_repository.dart';
import '../services/content_sync_service.dart';
import '../services/question_history_service.dart';
import '../services/dpp_engine.dart';
import '../services/mastery_service.dart';
import '../services/unified_question_pool_service.dart';
import 'core_providers.dart';

import 'current_user_provider.dart';
import '../database/drift_database.dart' as db;

// ============= SUBJECT & CONTENT =============
final subjectsProvider = Provider<List<subject_model.Subject>>((ref) {
  return subjects;
});

final subjectByIdProvider = Provider.family<subject_model.Subject?, String>((
  ref,
  subjectId,
) {
  final allSubjects = ref.watch(subjectsProvider);
  try {
    return allSubjects.firstWhere((s) => s.id == subjectId);
  } catch (e) {
    return null;
  }
});

// NOTE ON `Chapter`:
// There are two unrelated classes with this name in the codebase:
//   * models/subject_model.dart — legacy catalog chapter (`name`, `subjectId`,
//     `topics`), reachable through `Subject.chapters`.
//   * models/chapter_model.dart  — new lesson-based chapter (`title`,
//     `lessons`, `summaryQuiz`) used by the chapter feature and ChapterService.
// `chapter_model.dart` is imported unprefixed, so bare `Chapter` resolves to
// the NEW model. Every provider below that walks the legacy `Subject.chapters`
// tree must therefore spell the type out as `subject_model.Chapter`.
final chaptersProvider = Provider.family<List<subject_model.Chapter>, String>((
  ref,
  subjectId,
) {
  final subject = ref.watch(subjectByIdProvider(subjectId));
  return subject?.chapters ?? <subject_model.Chapter>[];
});

final topicsProvider = Provider.family<List<subject_model.Topic>, String>((
  ref,
  chapterId,
) {
  final allSubjects = ref.watch(subjectsProvider);
  for (var subject in allSubjects) {
    for (var chapter in subject.chapters) {
      if (chapter.id == chapterId) {
        return chapter.topics;
      }
    }
  }
  return <subject_model.Topic>[];
});

final chapterByIdProvider = Provider.family<subject_model.Chapter?, String>((
  ref,
  chapterId,
) {
  for (final subject in ref.watch(subjectsProvider)) {
    for (final chapter in subject.chapters) {
      if (chapter.id == chapterId) return chapter;
    }
  }
  return null;
});

/// Read-only catalog of learning resources. User progress/bookmarks belong in
/// separate user-scoped tables; the catalog itself is shared content.
final studyResourcesProvider = Provider<List<StudyResource>>((ref) {
  final resources = <StudyResource>[];
  for (final entry in NcertBookCatalog.allEntries) {
    resources.add(
      StudyResource(
        id: entry.assetPath,
        title: 'NCERT: ${entry.chapterTitle}',
        subject: entry.subject,
        classLevel: entry.classLevel,
        chapterId: _chapterIdForEntry(entry),
        chapterTitle: entry.chapterTitle,
        type: StudyResourceType.ncertPdf,
        source: 'NCERT',
        assetPath: entry.assetPath,
        offlineAvailable: true,
      ),
    );
  }
  for (final subject in subjects) {
    for (final chapter in subject.chapters) {
      if (chapter.topics.isEmpty) continue;
      resources.add(
        StudyResource(
          id: 'notes_${chapter.id}',
          title: 'Mitosis Notes: ${chapter.name}',
          subject: subject.name,
          classLevel: chapter.classLevel ?? 'NEET',
          chapterId: chapter.id,
          chapterTitle: chapter.name,
          type: StudyResourceType.mitosisNotes,
          source: 'Mitosis',
          offlineAvailable: true,
        ),
      );
      resources.add(
        StudyResource(
          id: 'revision_${chapter.id}',
          title: 'One-page revision: ${chapter.name}',
          subject: subject.name,
          classLevel: chapter.classLevel ?? 'NEET',
          chapterId: chapter.id,
          chapterTitle: chapter.name,
          type: StudyResourceType.revisionSheet,
          source: 'Mitosis',
          offlineAvailable: true,
        ),
      );
      resources.add(
        StudyResource(
          id: 'formula_${chapter.id}',
          title:
              '${subject.name == 'Biology' ? 'Fact' : 'Formula'} sheet: ${chapter.name}',
          subject: subject.name,
          classLevel: chapter.classLevel ?? 'NEET',
          chapterId: chapter.id,
          chapterTitle: chapter.name,
          type: StudyResourceType.formulaSheet,
          source: 'Mitosis',
          offlineAvailable: true,
        ),
      );
      resources.add(
        StudyResource(
          id: 'pyq_${chapter.id}',
          title: 'PYQ practice: ${chapter.name}',
          subject: subject.name,
          classLevel: chapter.classLevel ?? 'NEET',
          chapterId: chapter.id,
          chapterTitle: chapter.name,
          type: StudyResourceType.pyqSet,
          source: 'Mitosis',
          offlineAvailable: true,
        ),
      );
      resources.add(
        StudyResource(
          id: 'diagrams_${chapter.id}',
          title: 'Diagram and flow revision: ${chapter.name}',
          subject: subject.name,
          classLevel: chapter.classLevel ?? 'NEET',
          chapterId: chapter.id,
          chapterTitle: chapter.name,
          type: StudyResourceType.diagramSheet,
          source: 'Mitosis',
          offlineAvailable: true,
        ),
      );
    }
  }
  return resources;
});

final resourcesForSubjectProvider =
    Provider.family<List<StudyResource>, String>((ref, subject) {
      return ref
          .watch(studyResourcesProvider)
          .where((resource) => resource.subject == subject)
          .toList(growable: false);
    });

final resourcesForChapterProvider =
    Provider.family<List<StudyResource>, String>((ref, chapterId) {
      return ref
          .watch(studyResourcesProvider)
          .where((resource) => resource.chapterId == chapterId)
          .toList(growable: false);
    });

final resourceProgressProvider =
    FutureProvider<Map<String, db.ResourceProgressData>>((ref) async {
      final userId = ref.watch(currentLocalUserIdProvider);
      if (userId == null) return const {};
      final rows = await ref
          .watch(databaseProvider)
          .getResourceProgress(userId: userId);
      return {for (final row in rows) row.resourceId: row};
    });

final studyResourceContentProvider = Provider.family<StudyResourceContent, String>((
  ref,
  chapterId,
) {
  final authored = studyResourceContent[chapterId];
  if (authored != null) return authored;

  final chapter = ref.watch(chapterByIdProvider(chapterId));
  final points =
      chapter?.topics
          .expand((topic) => topic.keyPoints ?? const <String>[])
          .toList(growable: false) ??
      const <String>[];
  final overview =
      chapter?.description ??
      'Chapter revision content is being expanded by the Mitosis content team.';
  return StudyResourceContent(
    chapterId: chapterId,
    overview: overview,
    keyFacts: points,
    revisionRules: const [
      'Read the matching NCERT chapter and mark every missed practice question.',
      'Revise this sheet before attempting the chapter quiz again.',
    ],
  );
});

String? _chapterIdForEntry(NcertBookEntry entry) {
  for (final subject in subjects) {
    for (final chapter in subject.chapters) {
      if (NcertBookCatalog.entryFor(chapter)?.assetPath == entry.assetPath) {
        return chapter.id;
      }
    }
  }
  return null;
}

// ============= FLASHCARDS =============
final flashcardsFromDbProvider = FutureProvider<List<Flashcard>>((ref) async {
  final db = ref.watch(databaseProvider);
  final userId = ref.watch(currentLocalUserIdProvider) ?? guestOwnerId;
  final rows = await db.getAllFlashcards(userId: userId);
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
  final userId = ref.watch(currentLocalUserIdProvider) ?? guestOwnerId;
  final rows = await db.getDueFlashcards(DateTime.now(), userId: userId);
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

// ============= CHAPTERS =============

final allChaptersProvider = Provider<List<Chapter>>((ref) {
  return ChapterService.allChapters;
});

final chaptersBySubjectProvider = Provider.family<List<Chapter>, String>((
  ref,
  subject,
) {
  return ChapterService.getChaptersBySubject(subject);
});

final chaptersByClassProvider = Provider.family<List<Chapter>, String>((
  ref,
  classLevel,
) {
  return ChapterService.getChaptersByClass(classLevel);
});

final chapterProvider = FutureProvider.family<Chapter?, String>((
  ref,
  chapterId,
) async {
  return ChapterService.getChapter(chapterId);
});

// Chapter progress provider (per-user)
final chapterProgressProvider = FutureProvider.family<ChapterProgress?, String>(
  (ref, chapterId) async {
    final db = ref.watch(databaseProvider);
    final userId = ref.watch(currentLocalUserIdProvider) ?? guestOwnerId;
    final tableData = await db.getChapterProgress(chapterId, userId);
    if (tableData == null) return null;
    // Convert from table data (JSON strings) to model (Set/Map)
    Set<String> completedIds = {};
    try {
      final decoded = JsonDecoder().convert(tableData.completedLessonIds);
      if (decoded is List) {
        completedIds = decoded.cast<String>().toSet();
      }
    } catch (_) {}
    Map<String, int> quickScores = {};
    try {
      final decoded = JsonDecoder().convert(tableData.quickCheckScores);
      if (decoded is Map) {
        quickScores = decoded.map((k, v) => MapEntry(k.toString(), v as int));
      }
    } catch (_) {}
    return ChapterProgress(
      chapterId: tableData.chapterId,
      userId: tableData.userId,
      currentLessonId: tableData.currentLessonId,
      completedLessonIds: completedIds,
      quickCheckScores: quickScores,
      summaryQuizScore: tableData.summaryQuizScore,
      startedAt: tableData.startedAt,
      lastAccessedAt: tableData.lastAccessedAt,
      completedAt: tableData.completedAt,
    );
  },
);

// ============= QUESTIONS =============
final recentlySeenQuestionIdsProvider =
    FutureProvider.family<Set<String>, String?>((ref, subject) async {
      final database = ref.watch(databaseProvider);
      final owner = ref.watch(currentLocalUserIdProvider) ?? guestOwnerId;
      final history = QuestionHistoryService(database, userId: owner);
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
  final owner = ref.watch(currentLocalUserIdProvider) ?? guestOwnerId;
  final history = QuestionHistoryService(database, userId: owner);
  final mastery = MasteryService(
    database,
    questionRepo.getAllQuestionsFromDb(),
    userId: owner,
  );
  final userId = owner;
  return DppEngine(database, questionRepo, history, mastery, userId: userId);
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

// ============= UNIFIED QUESTION POOL =============

final unifiedQuestionPoolServiceProvider = Provider<UnifiedQuestionPoolService>(
  (ref) {
    final repo = ref.watch(questionRepositoryProvider);
    final history = ref.watch(questionHistoryServiceProvider);
    final mastery = ref.watch(masteryServiceProvider);
    return UnifiedQuestionPoolService(repo, history, mastery);
  },
);

final questionHistoryServiceProvider = Provider<QuestionHistoryService>((ref) {
  final database = ref.watch(databaseProvider);
  final owner = ref.watch(currentLocalUserIdProvider) ?? guestOwnerId;
  return QuestionHistoryService(database, userId: owner);
});

final masteryServiceProvider = Provider<MasteryService>((ref) {
  final database = ref.watch(databaseProvider);
  final questionBank = ref.watch(allQuestionsProvider.future);
  final owner = ref.watch(currentLocalUserIdProvider) ?? guestOwnerId;
  return MasteryService(database, questionBank, userId: owner);
});

// Adaptive quiz questions with mastery-based selection and anti-repetition
final adaptiveQuizQuestionsProvider =
    FutureProvider.family<List<Question>, AdaptiveQuizRequest>((
      ref,
      request,
    ) async {
      final poolService = ref.watch(unifiedQuestionPoolServiceProvider);
      final questionRequest = QuestionRequest(
        subjects: request.subjects,
        chapterId: request.chapterId,
        topicId: request.topicId,
        count: request.count,
        easyPercent: request.easyPercent,
        mediumPercent: request.mediumPercent,
        hardPercent: request.hardPercent,
        excludeRecent: request.excludeRecent,
        applyCooldown: request.applyCooldown,
        biasWeakTopics: request.biasWeakTopics,
        useChapterWeights: request.useChapterWeights,
        deduplicateConcepts: request.deduplicateConcepts,
        subjectWeights: request.subjectWeights,
      );
      return poolService.getQuestions(request: questionRequest);
    });

class AdaptiveQuizRequest {
  final List<String> subjects;
  final String? chapterId;
  final String? topicId;
  final int count;
  final int easyPercent;
  final int mediumPercent;
  final int hardPercent;
  final bool excludeRecent;
  final bool applyCooldown;
  final bool biasWeakTopics;
  final bool useChapterWeights;
  final bool deduplicateConcepts;
  final Map<String, int>? subjectWeights;

  const AdaptiveQuizRequest({
    required this.subjects,
    this.chapterId,
    this.topicId,
    required this.count,
    this.easyPercent = 30,
    this.mediumPercent = 50,
    this.hardPercent = 20,
    this.excludeRecent = true,
    this.applyCooldown = true,
    this.biasWeakTopics = true,
    this.useChapterWeights = true,
    this.deduplicateConcepts = true,
    this.subjectWeights,
  });

  factory AdaptiveQuizRequest.fromRecommendation(
    LearningRecommendation recommendation, {
    int count = 15,
  }) {
    final speedDrill =
        recommendation.primaryAction == LearningActionType.speedDrill;
    final revision = recommendation.primaryAction == LearningActionType.revise;
    return AdaptiveQuizRequest(
      subjects: [recommendation.subject],
      chapterId: recommendation.chapterId,
      topicId: recommendation.topicId,
      count: count,
      easyPercent: speedDrill ? 45 : (revision ? 40 : 30),
      mediumPercent: speedDrill ? 45 : 45,
      hardPercent: speedDrill ? 10 : 15,
      biasWeakTopics: true,
    );
  }
}
