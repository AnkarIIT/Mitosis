import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import '../database/drift_database.dart' as db;
import '../database/question_repository.dart';
import '../models/question_model.dart';
import '../services/question_history_service.dart';

/// Configuration for a single Daily Practice Paper (DPP).
class DppConfig {
  final String subject;
  final String? chapterId;
  final String? topicId;
  final int totalQuestions;
  final int easyPercent;
  final int mediumPercent;
  final int hardPercent;
  final bool includeWeakTopics;

  const DppConfig({
    required this.subject,
    this.chapterId,
    this.topicId,
    this.totalQuestions = 20,
    this.easyPercent = 30,
    this.mediumPercent = 50,
    this.hardPercent = 20,
    this.includeWeakTopics = true,
  });
}

/// Result of a generated DPP set.
class DppResult {
  final db.DppSet set;
  final List<Question> questions;

  DppResult({required this.set, required this.questions});
}

/// Generates Daily Practice Papers (DPP) by sampling from the local question
/// bank, excluding recently seen questions, and biasing toward weak topics when
/// configured.
class DppEngine {
  final db.AppDatabase _db;
  final QuestionRepository _questionRepo;
  final QuestionHistoryService _history;
  final Random _random;

  DppEngine(this._db, this._questionRepo, this._history, {Random? random})
      : _random = random ?? Random();

  /// Generates a DPP for today. If one already exists for the given config,
  /// returns the existing set (unless [forceRefresh] is true).
  Future<DppResult> generate(DppConfig config, {bool forceRefresh = false}) async {
    final existing = await _db.getTodayDppSet(config.subject);
    if (existing != null && !forceRefresh) {
      final savedQuestions = await _db.getDppQuestions(existing.id);
      if (savedQuestions.isNotEmpty) {
        return DppResult(
          set: existing,
          questions: savedQuestions
              .map((q) => Question(
                    id: q.questionId,
                    subject: q.subject,
                    chapter: q.chapter,
                    topic: q.topic,
                    topicId: q.topicId,
                    questionText: q.questionText,
                    options: _decodeOptions(q.options),
                    correctAnswer: q.correctAnswer,
                    explanation: q.explanation,
                    year: q.year,
                    difficulty: q.difficulty,
                    tags: const [],
                    type: 'MCQ',
                  ))
              .toList(),
        );
      }
    }

    final excludedIds = await _history.getRecentSeenQuestionIds();
    final pool = await _buildPool(config, excludedIds);
    final selected = _sample(pool, config.totalQuestions, config);

    // Persist the DPP set.
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final base = db.DppSetsCompanion.insert(
      date: dateStr,
      subject: config.subject,
      totalQuestions: config.totalQuestions,
    );
    final companion = base.copyWith(
      chapterId: config.chapterId == null ? const Value.absent() : Value<String?>(config.chapterId!),
      topicId: config.topicId == null ? const Value.absent() : Value<String?>(config.topicId!),
    );
    final setId = await _db.insertDppSet(companion);

    final dppQuestions = selected
        .map((q) => db.DppQuestionsCompanion.insert(
              dppSetId: Value<int?>(setId),
              questionId: q.id,
              subject: q.subject,
              chapter: q.chapter,
              topic: q.topic,
              topicId: q.topicId,
              difficulty: q.difficulty,
              questionText: q.questionText,
              options: jsonEncode(q.options),
              correctAnswer: q.correctAnswer,
              explanation: Value(q.explanation),
              year: Value(q.year),
            ))
        .toList();

    await _db.insertDppQuestions(dppQuestions);

    final savedSet = db.DppSet(
      id: setId,
      date: dateStr,
      subject: config.subject,
      chapterId: config.chapterId,
      topicId: config.topicId,
      totalQuestions: config.totalQuestions,
      correctCount: 0,
      incorrectCount: 0,
      unattemptedCount: 0,
      timeSpentSeconds: 0,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return DppResult(set: savedSet, questions: selected);
  }

  Future<List<Question>> _buildPool(DppConfig config, Set<String> excludedIds) async {
    final all = await _questionRepo.getAllQuestionsFromDb();
    var pool = all.where((q) => q.subject == config.subject).toList();

    // Exclude recently seen questions.
    if (excludedIds.isNotEmpty) {
      pool = pool.where((q) => !excludedIds.contains(q.id)).toList();
    }

    // If too few unseen questions remain, relax the exclusion to avoid
    // an empty pool.
    if (pool.length < config.totalQuestions ~/ 2) {
      pool = all.where((q) => q.subject == config.subject).toList();
    }

    // Bias toward weak topics when configured.
    if (config.includeWeakTopics) {
      final weakTopicIds = await _getWeakTopicIds(config.subject);
      if (weakTopicIds.isNotEmpty) {
        final weak = pool.where((q) => weakTopicIds.contains(q.topicId)).toList();
        final others = pool.where((q) => !weakTopicIds.contains(q.topicId)).toList();
        weak.shuffle(_random);
        others.shuffle(_random);
        pool = [...weak, ...others];
      }
    }

    // Filter by chapter/topic if specified.
    if (config.chapterId != null && config.chapterId!.isNotEmpty) {
      pool = pool.where((q) => q.chapter == config.chapterId).toList();
    }
    if (config.topicId != null && config.topicId!.isNotEmpty) {
      pool = pool.where((q) => q.topicId == config.topicId).toList();
    }

    return pool;
  }

  Future<Set<String>> _getWeakTopicIds(String subject) async {
    final cards = await _db.getSpacedRepetitionCards();
    final allQuestions = await _questionRepo.getAllQuestionsFromDb();
    final questionByTopicId = <String, String>{};
    for (final q in allQuestions) {
      if (q.subject == subject) {
        questionByTopicId[q.id] = q.topicId;
      }
    }

    final weak = <String>{};
    for (final card in cards) {
      final topicId = questionByTopicId[card.questionId];
      if (topicId != null && card.box <= 2) {
        weak.add(topicId);
      }
    }
    return weak;
  }

  List<Question> _sample(List<Question> pool, int count, DppConfig config) {
    if (pool.isEmpty) return [];
    final shuffled = List<Question>.from(pool)..shuffle(_random);
    final easy = count * config.easyPercent ~/ 100;
    final medium = count * config.mediumPercent ~/ 100;
    final hard = count - easy - medium;

    final buckets = <List<Question>>[
      shuffled.where((q) => q.difficulty.toLowerCase() == 'easy').toList(),
      shuffled.where((q) => q.difficulty.toLowerCase() == 'medium').toList(),
      shuffled.where((q) => q.difficulty.toLowerCase() == 'hard').toList(),
    ];

    final picked = <Question>[];
    final targets = [easy, medium, hard];
    for (int i = 0; i < 3; i++) {
      final take = min(targets[i], buckets[i].length);
      buckets[i].shuffle(_random);
      picked.addAll(buckets[i].take(take));
    }

    // Backfill if we're short.
    if (picked.length < count) {
      final remaining = pool.where((q) => !picked.contains(q)).toList();
      remaining.shuffle(_random);
      picked.addAll(remaining.take(count - picked.length));
    }

    return picked.take(count).toList();
  }

  static List<String> _decodeOptions(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } on FormatException {
      // fall through
    }
    return raw.split('|||').where((e) => e.trim().isNotEmpty).map((e) => e.trim()).toList();
  }
}
