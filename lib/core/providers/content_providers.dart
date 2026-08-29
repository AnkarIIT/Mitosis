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
import 'core_providers.dart';

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

// ============= QUESTIONS =============
final recentlySeenQuestionIdsProvider = FutureProvider.family<Set<String>, String?>((ref, subject) async {
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

final questionsForTopicProvider = FutureProvider.family<List<Question>, String>((
  ref,
  topicId,
) async {
  final repository = ref.watch(questionRepositoryProvider);
  final all = await repository.getQuestionsByTopicId(topicId);
  final seen = await ref.watch(recentlySeenQuestionIdsProvider(null).future);
  final unseen = seen.isEmpty ? all : all.where((q) => !seen.contains(q.id)).toList();
  // Sample to avoid exhausting the full topic pool in one quiz.
  final max = unseen.length > 20 ? 20 : unseen.length;
  final random = Random(DateTime.now().millisecondsSinceEpoch);
  unseen.shuffle(random);
  return unseen.take(max).toList();
});

final questionsForSubjectProvider = FutureProvider.family<List<Question>, String>((
  ref,
  subject,
) async {
  final allQuestions = await ref.watch(allQuestionsProvider.future);
  return allQuestions.where((q) => q.subject == subject).toList();
});

// ============= CONTENT CATALOG SYNC =============
final contentSyncServiceProvider = Provider<ContentSyncService?>((ref) {
  if (!AppConfig.enableCloudAuth || !AppConfig.isCloudAuthConfigured) return null;
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
  return DppEngine(database, questionRepo, history);
});

final todayDppProvider = FutureProvider.family<DppResult?, String>((ref, subject) async {
  final engine = ref.watch(dppEngineProvider);
  return await engine.generate(DppConfig.single(subject: subject));
});
