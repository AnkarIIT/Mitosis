import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import '../database/drift_database.dart' as db;
import '../database/question_repository.dart';
import '../models/question_model.dart';
import '../services/question_history_service.dart';
import '../services/mastery_service.dart';

/// NEET high-yield chapter weights based on PYQ analysis (questions per year).
/// Higher weight = more likely to appear in NEET, so we boost these chapters.
/// Keys are "Subject:Chapter" to avoid collisions (e.g., Biomolecules appears in both Bio & Chem).
const Map<String, int> _neetChapterWeights = {
  // Biology - High yield (10-12 questions/year)
  'Biology:Human Physiology': 12,
  'Biology:Plant Physiology': 10,
  'Biology:Genetics and Evolution': 10,
  'Biology:Ecology': 9,
  'Biology:Cell Biology': 8,
  'Biology:Biotechnology': 7,
  'Biology:Human Reproduction': 7,
  'Biology:Plant Reproduction': 6,
  'Biology:Microbes in Human Welfare': 5,
  'Biology:Biomolecules': 8,
  
  // Physics - High yield (8-10 questions/year)
  'Physics:Mechanics': 10,
  'Physics:Electrodynamics': 9,
  'Physics:Modern Physics': 8,
  'Physics:Optics': 7,
  'Physics:Thermodynamics': 7,
  'Physics:Waves': 6,
  'Physics:SHM': 5,
  'Physics:Semiconductors': 6,
  'Physics:Communication Systems': 4,
  
  // Chemistry - High yield (8-10 questions/year)
  'Chemistry:Chemical Bonding': 10,
  'Chemistry:Coordination Compounds': 8,
  'Chemistry:p-Block Elements': 8,
  'Chemistry:d- and f-Block Elements': 7,
  'Chemistry:Organic Chemistry - Basic Principles': 9,
  'Chemistry:Hydrocarbons': 8,
  'Chemistry:Alcohols, Phenols, Ethers': 7,
  'Chemistry:Aldehydes, Ketones, Carboxylic Acids': 7,
  'Chemistry:Biomolecules': 6,
  'Chemistry:Polymers': 5,
  'Chemistry:Chemistry in Everyday Life': 4,
  'Chemistry:Electrochemistry': 7,
  'Chemistry:Chemical Kinetics': 6,
  'Chemistry:Surface Chemistry': 5,
  'Chemistry:Solutions': 6,
  'Chemistry:Solid State': 5,
  'Chemistry:Thermodynamics': 7,
  'Chemistry:Equilibrium': 7,
};

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

  /// Enable chapter frequency weighting based on NEET PYQ analysis.
  /// High-yield chapters get boosted probability.
  final bool useChapterWeights;

  /// Enable concept deduplication - avoid same concept questions in one DPP.
  final bool deduplicateConcepts;

  /// Enable adaptive difficulty - increase difficulty if student performs well.
  final bool adaptiveDifficulty;

  /// Student's recent accuracy (0.0-1.0) for adaptive difficulty.
  final double? recentAccuracy;

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
    this.useChapterWeights = true,
    this.deduplicateConcepts = true,
    this.adaptiveDifficulty = false,
    this.recentAccuracy,
  });

  /// Legacy single-subject constructor for backward compatibility.
  factory DppConfig.single({
    required String subject,
    String? chapterId,
    String? topicId,
    int totalQuestions = 20,
    int durationMinutes = 20,
    bool includeWeakTopics = true,
    bool useChapterWeights = true,
    bool deduplicateConcepts = true,
  }) {
    return DppConfig(
      subjects: [subject],
      chapterId: chapterId,
      topicId: topicId,
      totalQuestions: totalQuestions,
      durationMinutes: durationMinutes,
      includeWeakTopics: includeWeakTopics,
      useChapterWeights: useChapterWeights,
      deduplicateConcepts: deduplicateConcepts,
    );
  }

  /// NEET 2025 pattern multi-subject DPP factory.
  /// Creates a balanced paper: Physics 45, Chemistry 45, Botany 45, Zoology 45.
  factory DppConfig.neetPattern({
    int totalQuestions = 180,
    int durationMinutes = 180,
    bool includeWeakTopics = true,
    bool useChapterWeights = true,
    bool deduplicateConcepts = true,
  }) {
    return DppConfig(
      subjects: const ['Physics', 'Chemistry', 'Botany', 'Zoology'],
      totalQuestions: totalQuestions,
      durationMinutes: durationMinutes,
      includeWeakTopics: includeWeakTopics,
      useChapterWeights: useChapterWeights,
      deduplicateConcepts: deduplicateConcepts,
      subjectWeights: const {
        'Physics': 45,
        'Chemistry': 45,
        'Botany': 45,
        'Zoology': 45,
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
    bool useChapterWeights = true,
    bool deduplicateConcepts = true,
  }) {
    return DppConfig(
      subjects: subjects,
      totalQuestions: totalQuestions,
      durationMinutes: durationMinutes,
      includeWeakTopics: includeWeakTopics,
      useChapterWeights: useChapterWeights,
      deduplicateConcepts: deduplicateConcepts,
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
  }) : answersByIndex = answersByIndex ?? {},
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

  DppEngine(
    this._db,
    this._questionRepo,
    this._history,
    this._mastery, {
    Random? random,
  }) : _random = random ?? Random();

  /// Cooldown days per difficulty level.
  static const Map<String, int> _cooldownDays = {
    'Easy': 1,
    'Medium': 3,
    'Hard': 7,
  };

  /// Normalizes difficulty string to standard values.
  static String _normalizeDifficulty(String difficulty) {
    final d = difficulty.trim().toLowerCase();
    if (d == 'easy' || d == 'simple') return 'Easy';
    if (d == 'medium' || d == 'moderate' || d == 'avg' || d == 'average') {
      return 'Medium';
    }
    if (d == 'hard' || d == 'difficult' || d == 'tough') return 'Hard';
    return 'Medium'; // default fallback
  }

  /// Returns topic IDs sorted by ascending mastery (weakest first) for the
  /// given subjects, using the [MasteryService].
  Future<List<String>> _getWeakTopicIds(List<String> subjects) async {
    return _mastery.weakTopicIds(subjects, limit: 20);
  }

  /// Generates a DPP for today. If one already exists for the given config,
  /// returns the existing set (unless [forceRefresh] is true).
  Future<DppResult> generate(
    DppConfig config, {
    bool forceRefresh = false,
  }) async {
    final primarySubject = config.subjects.first;
    final existing = await _db.getTodayDppSet(primarySubject);
    if (existing != null && !forceRefresh) {
      final savedQuestions = await _db.getDppQuestions(existing.id);
      if (savedQuestions.isNotEmpty) {
        final questions = savedQuestions
            .map(
              (q) => Question(
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
              ),
            )
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
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final base = db.DppSetsCompanion.insert(
      date: dateStr,
      subject: primarySubject,
      totalQuestions: config.totalQuestions,
      durationMinutes: Value(config.durationMinutes),
    );
    final companion = base.copyWith(
      chapterId: config.chapterId == null
          ? const Value.absent()
          : Value<String?>(config.chapterId!),
      topicId: config.topicId == null
          ? const Value.absent()
          : Value<String?>(config.topicId!),
    );
    final setId = await _db.insertDppSet(companion);

    final dppQuestions = selected
        .map(
          (q) => db.DppQuestionsCompanion.insert(
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
          ),
        )
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

  Future<List<Question>> _buildPool(
    DppConfig config,
    Set<String> excludedIds,
  ) async {
    final all = await _questionRepo.getAllQuestionsFromDb();
    var pool = all.where((q) => config.subjects.contains(q.subject)).toList();

    // Exclude recently seen questions (full history).
    if (excludedIds.isNotEmpty) {
      pool = pool.where((q) => !excludedIds.contains(q.id)).toList();
    }

    // Exclude questions in cooldown period based on difficulty.
    final cooldownIds = await _getCooldownQuestionIds(config.subjects);
    if (cooldownIds.isNotEmpty) {
      pool = pool.where((q) => !cooldownIds.contains(q.id)).toList();
    }

    // If too few unseen questions remain, relax the exclusion to avoid
    // an empty pool (but keep cooldown).
    if (pool.length < config.totalQuestions ~/ 2) {
      pool = all.where((q) => config.subjects.contains(q.subject)).toList();
      if (excludedIds.isNotEmpty) {
        pool = pool.where((q) => !excludedIds.contains(q.id)).toList();
      }
      if (cooldownIds.isNotEmpty) {
        pool = pool.where((q) => !cooldownIds.contains(q.id)).toList();
      }
    }

    // Apply chapter frequency weighting (NEET PYQ-based boost).
    if (config.useChapterWeights) {
      pool = _applyChapterWeights(pool);
    }

    // Bias toward weak topics when configured.
    if (config.includeWeakTopics) {
      final weakTopicIds = await _getWeakTopicIds(config.subjects);
      if (weakTopicIds.isNotEmpty) {
        final weak = pool
            .where((q) => weakTopicIds.contains(q.topicId))
            .toList();
        final others = pool
            .where((q) => !weakTopicIds.contains(q.topicId))
            .toList();
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

  /// Applies NEET chapter frequency weights to boost high-yield chapters.
  /// Questions from high-yield chapters get duplicated in the pool to increase
  /// their selection probability proportionally.
  List<Question> _applyChapterWeights(List<Question> pool) {
    final weightedPool = <Question>[];
    for (final q in pool) {
      // Key is just chapter name (matching _neetChapterWeights map keys)
      final weight = _neetChapterWeights[q.chapter] ?? 1;
      // Add the question multiple times based on weight (capped at 3x for performance)
      final copies = weight.clamp(1, 3);
      for (int i = 0; i < copies; i++) {
        weightedPool.add(q);
      }
    }
    return weightedPool;
  }

  /// Gets question IDs that are in cooldown period based on their difficulty.
  /// Easy: 1 day, Medium: 3 days, Hard: 7 days since last attempt.
  Future<Set<String>> _getCooldownQuestionIds(List<String> subjects) async {
    final attempts = await _db.getAllQuizAttempts();
    final cooldownIds = <String>{};
    final now = DateTime.now();

    // Build a map of questionId -> difficulty from the questions table
    final questionDifficulties = <String, String>{};
    for (final subject in subjects) {
      final questions = await _questionRepo.getQuestionsBySubject(subject);
      for (final q in questions) {
        questionDifficulties[q.id] = q.difficulty;
      }
    }

    for (final attempt in attempts) {
      if (!subjects.contains(attempt.subject)) continue;
      final raw = attempt.questionIds;
      if (raw == null || raw.isEmpty) continue;
      try {
        final list = (jsonDecode(raw) as List).cast<String>();
        final daysSinceAttempt = now.difference(attempt.attemptedAt).inDays;

        for (final qId in list) {
          final difficulty = questionDifficulties[qId] ?? 'Medium';
          final normalizedDiff = _normalizeDifficulty(difficulty);
          final cooldownDays = _cooldownDays[normalizedDiff] ?? 3;
          
          if (daysSinceAttempt < cooldownDays) {
            cooldownIds.add(qId);
          }
        }
      } on FormatException {
        // ignore malformed JSON
      }
    }
    return cooldownIds;
  }

  List<Question> _sample(List<Question> pool, int count, DppConfig config) {
    if (pool.isEmpty) return [];

    // If subject weights are specified, sample per subject
    if (config.subjectWeights != null && config.subjectWeights!.isNotEmpty) {
      return _sampleBySubject(pool, count, config);
    }

    // Otherwise, use difficulty-based sampling
    final shuffled = List<Question>.from(pool)..shuffle(_random);
    
    // Apply adaptive difficulty if enabled and student is performing well
    int easy = count * config.easyPercent ~/ 100;
    int medium = count * config.mediumPercent ~/ 100;
    int hard = count - easy - medium;
    if (config.adaptiveDifficulty && config.recentAccuracy != null) {
      if (config.recentAccuracy! >= 0.8) {
        // Student scoring 80%+ - shift toward harder questions
        easy = (easy * 0.5).round();
        medium = (medium * 0.7).round();
        hard = count - easy - medium;
      } else if (config.recentAccuracy! <= 0.4) {
        // Student struggling - shift toward easier questions
        hard = (hard * 0.5).round();
        medium = (medium * 0.8).round();
        easy = count - medium - hard;
      }
    }

    final buckets = <List<Question>>[
      shuffled
          .where((q) => _normalizeDifficulty(q.difficulty) == 'Easy')
          .toList(),
      shuffled
          .where((q) => _normalizeDifficulty(q.difficulty) == 'Medium')
          .toList(),
      shuffled
          .where((q) => _normalizeDifficulty(q.difficulty) == 'Hard')
          .toList(),
    ];

    final picked = <Question>[];
    final usedConcepts = <String>{};
    final targets = [easy, medium, hard];
    
    for (int i = 0; i < 3; i++) {
      buckets[i].shuffle(_random);
      var taken = 0;
      for (final q in buckets[i]) {
        if (taken >= targets[i]) break;
        // Concept deduplication: skip if we already have a question with same concept
        if (config.deduplicateConcepts && _hasConceptOverlap(q, usedConcepts)) {
          continue;
        }
        picked.add(q);
        _addQuestionConcepts(q, usedConcepts);
        taken++;
      }
    }

    // Backfill if we're short.
    if (picked.length < count) {
      final remaining = pool.where((q) => !picked.contains(q)).toList();
      remaining.shuffle(_random);
      for (final q in remaining) {
        if (picked.length >= count) break;
        if (config.deduplicateConcepts && _hasConceptOverlap(q, usedConcepts)) {
          continue;
        }
        picked.add(q);
        _addQuestionConcepts(q, usedConcepts);
      }
    }

    return picked.take(count).toList();
  }

  /// Checks if a question shares concepts with already picked questions.
  /// Uses tags field as proxy for concepts.
  bool _hasConceptOverlap(Question q, Set<String> usedConcepts) {
    final questionConcepts = q.tags.map((t) => t.toLowerCase()).toSet();
    return questionConcepts.any((c) => usedConcepts.contains(c));
  }

  /// Adds question's concepts to the used set.
  void _addQuestionConcepts(Question q, Set<String> usedConcepts) {
    for (final tag in q.tags) {
      usedConcepts.add(tag.toLowerCase());
    }
  }

  List<Question> _sampleBySubject(
    List<Question> pool,
    int totalCount,
    DppConfig config,
  ) {
    final weights = config.subjectWeights!;
    final picked = <Question>[];
    final usedConcepts = <String>{};
    final subjectPools = <String, List<Question>>{};
    final subjectPickedCount = <String, int>{};

    // Group pool by subject
    for (final subject in config.subjects) {
      subjectPools[subject] = pool.where((q) => q.subject == subject).toList();
      subjectPickedCount[subject] = 0;
    }

    // Calculate target count per subject based on weights
    final totalWeight = weights.values.fold(0, (sum, w) => sum + w);
    final targets = <String, int>{};
    var allocated = 0;
    for (int i = 0; i < config.subjects.length; i++) {
      final subject = config.subjects[i];
      final weight =
          weights[subject] ?? (totalWeight ~/ config.subjects.length);
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
      
      // Apply adaptive difficulty per subject
      int easy = target * config.easyPercent ~/ 100;
      int medium = target * config.mediumPercent ~/ 100;
      int hard = target - easy - medium;
      if (config.adaptiveDifficulty && config.recentAccuracy != null) {
        if (config.recentAccuracy! >= 0.8) {
          easy = (easy * 0.5).round();
          medium = (medium * 0.7).round();
          hard = target - easy - medium;
        } else if (config.recentAccuracy! <= 0.4) {
          hard = (hard * 0.5).round();
          medium = (medium * 0.8).round();
          easy = target - medium - hard;
        }
      }

      final buckets = <List<Question>>[
        shuffled
            .where((q) => _normalizeDifficulty(q.difficulty) == 'Easy')
            .toList(),
        shuffled
            .where((q) => _normalizeDifficulty(q.difficulty) == 'Medium')
            .toList(),
        shuffled
            .where((q) => _normalizeDifficulty(q.difficulty) == 'Hard')
            .toList(),
      ];

      final targetsPerDiff = [easy, medium, hard];
      for (int i = 0; i < 3; i++) {
        buckets[i].shuffle(_random);
        var taken = 0;
        for (final q in buckets[i]) {
          if (taken >= targetsPerDiff[i]) break;
          // Concept deduplication
          if (config.deduplicateConcepts && _hasConceptOverlap(q, usedConcepts)) {
            continue;
          }
          picked.add(q);
          _addQuestionConcepts(q, usedConcepts);
          taken++;
        }
      }

      // Backfill if short for this subject
      final currentSubjectCount = subjectPickedCount[subject] ?? 0;
      if (currentSubjectCount < target) {
        final remaining = subjectPool
            .where((q) => !picked.contains(q))
            .toList();
        remaining.shuffle(_random);
        final needed = target - currentSubjectCount;
        var backfillTaken = 0;
        for (final q in remaining) {
          if (backfillTaken >= needed) break;
          if (config.deduplicateConcepts && _hasConceptOverlap(q, usedConcepts)) {
            continue;
          }
          picked.add(q);
          _addQuestionConcepts(q, usedConcepts);
          backfillTaken++;
        }
        subjectPickedCount[subject] = currentSubjectCount + backfillTaken;
      }
    }

    // If still short overall, backfill from all subjects
    if (picked.length < totalCount) {
      final remaining = pool.where((q) => !picked.contains(q)).toList();
      remaining.shuffle(_random);
      for (final q in remaining) {
        if (picked.length >= totalCount) break;
        if (config.deduplicateConcepts && _hasConceptOverlap(q, usedConcepts)) {
          continue;
        }
        picked.add(q);
        _addQuestionConcepts(q, usedConcepts);
      }
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
    return raw
        .split('|||')
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e.trim())
        .toList();
  }
}
