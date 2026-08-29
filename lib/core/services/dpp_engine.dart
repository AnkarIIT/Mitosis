import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import '../database/drift_database.dart' as db;
import '../database/question_repository.dart';
import '../models/question_model.dart';
import '../services/question_history_service.dart';
import '../services/mastery_service.dart';

/// Configuration for a single Daily Practice Paper (DPP).
class DppConfig {
  /// Subjects to include. Use a list of 1–3 subjects for a mixed DPP, or a
  /// single subject for a subject-specific drill.
  final List<String> subjects;
  final String? chapterId;
  final String? topicId;
  final int totalQuestions;
  final int durationMinutes;
  final int easyPercent;
  final int mediumPercent;
  final int hardPercent;
  final bool includeWeakTopics;

  /// Subject weights for multi-subject DPP. Keys are subject names, values are
  /// proportional weights (e.g., {'Physics': 45, 'Chemistry': 45, 'Biology': 90}).
  /// If null, defaults to equal distribution across subjects.
  final Map<String, int>? subjectWeights;

  const DppConfig({
    this.subjects = const ['Physics', 'Chemistry', 'Biology'],
    this.chapterId,
    this.topicId,
    this.totalQuestions = 20,
    this.durationMinutes = 20,
    this.easyPercent = 30,
    this.mediumPercent = 50,
    this.hardPercent = 20,
    this.includeWeakTopics = true,
    this.subjectWeights,
  });

  /// Legacy single-subject constructor for backward compatibility.
  factory DppConfig.single({
    required String subject,
    String? chapterId,
    String? topicId,
    int totalQuestions = 20,
    int durationMinutes = 20,
    bool includeWeakTopics = true,
  }) {
    return DppConfig(
      subjects: [subject],
      chapterId: chapterId,
      topicId: topicId,
      totalQuestions: totalQuestions,
      durationMinutes: durationMinutes,
      includeWeakTopics: includeWeakTopics,
    );
  }

  /// NEET 2025 pattern multi-subject DPP factory.
  /// Creates a balanced paper: Physics 45, Chemistry 45, Biology 90 (Botany 45 + Zoology 45).
  factory DppConfig.neetPattern({
    int totalQuestions = 180,
    int durationMinutes = 180,
    bool includeWeakTopics = true,
  }) {
    return DppConfig(
      subjects: const ['Physics', 'Chemistry', 'Biology'],
      totalQuestions: totalQuestions,
      durationMinutes: durationMinutes,
      includeWeakTopics: includeWeakTopics,
      subjectWeights: const {
        'Physics': 45,
        'Chemistry': 45,
        'Biology': 90,
      },
    );
  }

  /// Mixed subject DPP with custom weights.
  factory DppConfig.mixed({
    required List<String> subjects,
    required Map<String, int> weights,
    int totalQuestions = 60,
    int durationMinutes = 60,
    bool includeWeakTopics = true,
  }) {
    return DppConfig(
      subjects: subjects,
      totalQuestions: totalQuestions,
      durationMinutes: durationMinutes,
      includeWeakTopics: includeWeakTopics,
      subjectWeights: weights,
    );
  }

  int get subjectCount => subjects.length;
}

/// Result of a generated DPP set.
class DppResult {
  final db.DppSet set;
  final List<Question> questions;
  final Map<String, List<Question>> questionsBySubject;

  DppResult({
    required this.set,
    required this.questions,
    required this.questionsBySubject,
  });
}

/// Tracks the live state of an in-progress DPP attempt.
class DppAttemptState {
  final DppResult result;
  final Map<int, String?> answersByIndex;
  final Map<int, int> secondsPerQuestion;
  final DateTime startedAt;
  final int durationSeconds;
  int get elapsedSeconds => DateTime.now().difference(startedAt).inSeconds;
  int get remainingSeconds => durationSeconds - elapsedSeconds;

  DppAttemptState({
    required this.result,
    required this.durationSeconds,
    Map<int, String?>? answersByIndex,
    Map<int, int>? secondsPerQuestion,
  })  : answersByIndex = answersByIndex ?? {},
        secondsPerQuestion = secondsPerQuestion ?? {},
        startedAt = DateTime.now();
}

/// Generates Daily Practice Papers (DPP) by sampling from the local question
/// bank, excluding recently seen questions, and biasing toward weak topics when
/// configured.
class DppEngine {
  final db.AppDatabase _db;
  final QuestionRepository _questionRepo;
  final QuestionHistoryService _history;
  final MasteryService _mastery;
  final Random _random;

  DppEngine(this._db, this._questionRepo, this._history, this._mastery, {Random? random})
      : _random = random ?? Random();

  /// Generates a DPP for today. If one already exists for the given config,
  /// returns the existing set (unless [forceRefresh] is true).
  Future<DppResult> generate(DppConfig config, {bool forceRefresh = false}) async {
    final primarySubject = config.subjects.first;
    final existing = await _db.getTodayDppSet(primarySubject);
    if (existing != null && !forceRefresh) {
      final savedQuestions = await _db.getDppQuestions(existing.id);
      if (savedQuestions.isNotEmpty) {
        final questions = savedQuestions
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
            .toList();
        return DppResult(
          set: existing,
          questions: questions,
          questionsBySubject: _groupBySubject(questions),
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
      subject: primarySubject,
      totalQuestions: config.totalQuestions,
      durationMinutes: Value(config.durationMinutes),
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
      subject: primarySubject,
      chapterId: config.chapterId,
      topicId: config.topicId,
      totalQuestions: config.totalQuestions,
      durationMinutes: config.durationMinutes,
      correctCount: 0,
      incorrectCount: 0,
      unattemptedCount: 0,
      timeSpentSeconds: 0,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return DppResult(
      set: savedSet,
      questions: selected,
      questionsBySubject: _groupBySubject(selected),
    );
  }

  Future<List<Question>> _buildPool(DppConfig config, Set<String> excludedIds) async {
    final all = await _questionRepo.getAllQuestionsFromDb();
    var pool = all.where((q) => config.subjects.contains(q.subject)).toList();

    // Exclude recently seen questions.
    if (excludedIds.isNotEmpty) {
      pool = pool.where((q) => !excludedIds.contains(q.id)).toList();
    }

    // If too few unseen questions remain, relax the exclusion to avoid
    // an empty pool.
    if (pool.length < config.totalQuestions ~/ 2) {
      pool = all.where((q) => config.subjects.contains(q.subject)).toList();
    }

    // Bias toward weak topics when configured.
    if (config.includeWeakTopics) {
      final weakTopicIds = await _getWeakTopicIds(config.subjects);
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

  Future<Set<String>> _getWeakTopicIds(List<String> subjects) async {
    final weak = await _mastery.weakTopicIds(subjects);
    return weak.toSet();
  }

  List<Question> _sample(List<Question> pool, int count, DppConfig config) {
    if (pool.isEmpty) return [];

    // If subject weights are specified, sample per subject
    if (config.subjectWeights != null && config.subjectWeights!.isNotEmpty) {
      return _sampleBySubject(pool, count, config);
    }

    // Otherwise, use difficulty-based sampling
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

  List<Question> _sampleBySubject(List<Question> pool, int totalCount, DppConfig config) {
    final weights = config.subjectWeights!;
    final picked = <Question>[];
    final subjectPools = <String, List<Question>>{};

    // Group pool by subject
    for (final subject in config.subjects) {
      subjectPools[subject] = pool.where((q) => q.subject == subject).toList();
    }

    // Calculate target count per subject based on weights
    final totalWeight = weights.values.fold(0, (sum, w) => sum + w);
    final targets = <String, int>{};
    var allocated = 0;
    for (int i = 0; i < config.subjects.length; i++) {
      final subject = config.subjects[i];
      final weight = weights[subject] ?? (totalWeight ~/ config.subjects.length);
      int target;
      if (i == config.subjects.length - 1) {
        target = totalCount - allocated;
      } else {
        target = (totalCount * weight / totalWeight).round();
      }
      targets[subject] = target;
      allocated += target;
    }

    // Sample per subject with difficulty balance
    for (final subject in config.subjects) {
      final target = targets[subject] ?? 0;
      final subjectPool = subjectPools[subject] ?? [];

      if (subjectPool.isEmpty) continue;

      final shuffled = List<Question>.from(subjectPool)..shuffle(_random);
      final easy = target * config.easyPercent ~/ 100;
      final medium = target * config.mediumPercent ~/ 100;
      final hard = target - easy - medium;

      final buckets = <List<Question>>[
        shuffled.where((q) => q.difficulty.toLowerCase() == 'easy').toList(),
        shuffled.where((q) => q.difficulty.toLowerCase() == 'medium').toList(),
        shuffled.where((q) => q.difficulty.toLowerCase() == 'hard').toList(),
      ];

      final targetsPerDiff = [easy, medium, hard];
      for (int i = 0; i < 3; i++) {
        final take = min(targetsPerDiff[i], buckets[i].length);
        buckets[i].shuffle(_random);
        picked.addAll(buckets[i].take(take));
      }

      // Backfill if short for this subject
      if (picked.where((q) => q.subject == subject).length < target) {
        final remaining = subjectPool.where((q) => !picked.contains(q)).toList();
        remaining.shuffle(_random);
        picked.addAll(remaining.take(target - picked.where((q) => q.subject == subject).length));
      }
    }

    // If still short overall, backfill from all subjects
    if (picked.length < totalCount) {
      final remaining = pool.where((q) => !picked.contains(q)).toList();
      remaining.shuffle(_random);
      picked.addAll(remaining.take(totalCount - picked.length));
    }

    // Shuffle the final picked list to mix subjects
    picked.shuffle(_random);
    return picked.take(totalCount).toList();
  }

  static Map<String, List<Question>> _groupBySubject(List<Question> questions) {
    final map = <String, List<Question>>{};
    for (final q in questions) {
      map.putIfAbsent(q.subject, () => []).add(q);
    }
    return map;
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
