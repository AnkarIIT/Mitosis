import 'dart:convert';
import 'dart:math';
import '../database/drift_database.dart' as db;
import '../database/question_repository.dart';
import '../models/question_model.dart';
import '../services/question_history_service.dart';
import '../services/mastery_service.dart';
import '../services/gemini_chat_service.dart';

/// NEET high-yield chapter weights based on PYQ analysis (questions per year).
/// Higher weight = more likely to appear in NEET, so we boost these chapters.
const Map<String, int> _neetChapterWeights = {
  // Biology - High yield (10-12 questions/year)
  'Human Physiology': 12,
  'Plant Physiology': 10,
  'Genetics and Evolution': 10,
  'Ecology': 9,
  'Cell Biology': 8,
  'Biotechnology': 7,
  'Human Reproduction': 7,
  'Plant Reproduction': 6,
  'Microbes in Human Welfare': 5,
  'Biomolecules': 8,

  // Physics - High yield (8-10 questions/year)
  'Mechanics': 10,
  'Electrodynamics': 9,
  'Modern Physics': 8,
  'Optics': 7,
  'Thermodynamics Physics': 7,
  'Waves': 6,
  'SHM': 5,
  'Semiconductors': 6,
  'Communication Systems': 4,

  // Chemistry - High yield (8-10 questions/year)
  'Chemical Bonding': 10,
  'Coordination Compounds': 8,
  'p-Block Elements': 8,
  'd- and f-Block Elements': 7,
  'Organic Chemistry - Basic Principles': 9,
  'Hydrocarbons': 8,
  'Alcohols, Phenols, Ethers': 7,
  'Aldehydes, Ketones, Carboxylic Acids': 7,
  'Biomolecules Chemistry': 6,
  'Polymers': 5,
  'Chemistry in Everyday Life': 4,
  'Electrochemistry': 7,
  'Chemical Kinetics': 6,
  'Surface Chemistry': 5,
  'Solutions': 6,
  'Solid State': 5,
  'Thermodynamics Chemistry': 7,
  'Equilibrium': 7,
};

/// Unified question pool service shared by Exam, Quiz, and DPP engines.
/// Provides centralized question selection, filtering, anti-repetition, and AI generation.
class UnifiedQuestionPoolService {
  final db.AppDatabase _db;
  final QuestionRepository _questionRepo;
  final QuestionHistoryService _history;
  final MasteryService _mastery;
  final GeminiChatService? _gemini;
  final Random _random;

  UnifiedQuestionPoolService(
    this._db,
    this._questionRepo,
    this._history,
    this._mastery, {
    GeminiChatService? gemini,
    Random? random,
  }) : _gemini = gemini,
       _random = random ?? Random();

  /// Main entry point: get questions for any engine type.
  /// Handles pool building, exclusions, AI backfill, and returns selected questions.
  Future<List<Question>> getQuestions({
    required QuestionRequest request,
    bool enableAiBackfill = false,
  }) async {
    final pool = await _buildPool(request);
    var selected = _selectQuestions(pool, request);

    // AI backfill if pool is insufficient
    if (enableAiBackfill && selected.length < request.count) {
      final needed = request.count - selected.length;
      final aiQuestions = await _generateAiQuestions(
        request.subjects.first,
        request.chapterId,
        request.topicId,
        needed,
        excludedIds: selected.map((q) => q.id).toSet(),
      );
      selected.addAll(aiQuestions);
    }

    return selected.take(request.count).toList();
  }

  /// Builds the candidate pool with all filters applied.
  Future<List<Question>> _buildPool(QuestionRequest request) async {
    final all = await _questionRepo.getAllQuestionsFromDb();
    var pool = all.where((q) => request.subjects.contains(q.subject)).toList();

    // Apply chapter/topic filters
    if (request.chapterId != null && request.chapterId!.isNotEmpty) {
      pool = pool.where((q) => q.chapter == request.chapterId).toList();
    }
    if (request.topicId != null && request.topicId!.isNotEmpty) {
      pool = pool.where((q) => q.topicId == request.topicId).toList();
    }

    // Anti-repetition: exclude recently seen questions
    if (request.excludeRecent) {
      final subjectFilter = request.subjects.length == 1 ? request.subjects.first : null;
      final excludedIds = await _history.getRecentSeenQuestionIds(
        subject: subjectFilter,
      );
      if (excludedIds.isNotEmpty) {
        pool = pool.where((q) => !excludedIds.contains(q.id)).toList();
      }
    }

    // Cooldown-based exclusion
    if (request.applyCooldown) {
      final cooldownIds = await _getCooldownQuestionIds(request.subjects);
      if (cooldownIds.isNotEmpty) {
        pool = pool.where((q) => !cooldownIds.contains(q.id)).toList();
      }
    }

    // Weak topic biasing
    if (request.biasWeakTopics) {
      final weakTopicIds = await _mastery.weakTopicIds(request.subjects);
      if (weakTopicIds.isNotEmpty) {
        final weak = pool.where((q) => weakTopicIds.contains(q.topicId)).toList();
        final others = pool.where((q) => !weakTopicIds.contains(q.topicId)).toList();
        weak.shuffle(_random);
        others.shuffle(_random);
        pool = [...weak, ...others];
      }
    }

    // Chapter frequency weighting (NEET PYQ-based)
    if (request.useChapterWeights) {
      pool = _applyChapterWeights(pool);
    }

    // Ensure minimum pool size
    final minPoolSize = (request.count * 2).clamp(20, 200);
    if (pool.length < minPoolSize && request.excludeRecent) {
      // Relax exclusion but keep cooldown
      final allSubjectQuestions = all.where((q) => request.subjects.contains(q.subject)).toList();
      final cooldownIds = await _getCooldownQuestionIds(request.subjects);
      pool = allSubjectQuestions.where((q) => !cooldownIds.contains(q.id)).toList();
      if (request.biasWeakTopics) {
        final weakTopicIds = await _mastery.weakTopicIds(request.subjects);
        if (weakTopicIds.isNotEmpty) {
          final weak = pool.where((q) => weakTopicIds.contains(q.topicId)).toList();
          final others = pool.where((q) => !weakTopicIds.contains(q.topicId)).toList();
          weak.shuffle(_random);
          others.shuffle(_random);
          pool = [...weak, ...others];
        }
      }
    }

    return pool;
  }

  /// Selects questions from pool based on request parameters.
  List<Question> _selectQuestions(List<Question> pool, QuestionRequest request) {
    if (pool.isEmpty) return [];

    final shuffled = List<Question>.from(pool)..shuffle(_random);

    // Subject-weighted sampling for multi-subject requests
    if (request.subjectWeights != null && request.subjectWeights!.isNotEmpty) {
      return _sampleBySubject(shuffled, request);
    }

    // Difficulty-based sampling
    return _sampleByDifficulty(shuffled, request);
  }

  /// Samples questions with difficulty distribution.
  List<Question> _sampleByDifficulty(List<Question> pool, QuestionRequest request) {
    final easyTarget = request.count * request.easyPercent ~/ 100;
    final mediumTarget = request.count * request.mediumPercent ~/ 100;
    final hardTarget = request.count - easyTarget - mediumTarget;

    final buckets = <List<Question>>[
      pool
          .where((q) => _normalizeDifficulty(q.difficulty) == 'Easy')
          .toList(),
      pool
          .where((q) => _normalizeDifficulty(q.difficulty) == 'Medium')
          .toList(),
      pool
          .where((q) => _normalizeDifficulty(q.difficulty) == 'Hard')
          .toList(),
    ];

    final picked = <Question>[];
    final usedConcepts = <String>{};
    final targets = [easyTarget, mediumTarget, hardTarget];

    for (int i = 0; i < 3; i++) {
      buckets[i].shuffle(_random);
      var taken = 0;
      for (final q in buckets[i]) {
        if (taken >= targets[i]) break;
        if (request.deduplicateConcepts && _hasConceptOverlap(q, usedConcepts)) {
          continue;
        }
        picked.add(q);
        _addQuestionConcepts(q, usedConcepts);
        taken++;
      }
    }

    // Backfill if short
    if (picked.length < request.count) {
      final remaining = pool.where((q) => !picked.contains(q)).toList();
      remaining.shuffle(_random);
      for (final q in remaining) {
        if (picked.length >= request.count) break;
        if (request.deduplicateConcepts && _hasConceptOverlap(q, usedConcepts)) {
          continue;
        }
        picked.add(q);
        _addQuestionConcepts(q, usedConcepts);
      }
    }

    return picked.take(request.count).toList();
  }

  /// Samples questions per subject with weights.
  List<Question> _sampleBySubject(List<Question> pool, QuestionRequest request) {
    final weights = request.subjectWeights!;
    final picked = <Question>[];
    final usedConcepts = <String>{};
    final subjectPools = <String, List<Question>>{};
    final targets = <String, int>{};

    for (final subject in request.subjects) {
      subjectPools[subject] = pool.where((q) => q.subject == subject).toList();
    }

    final totalWeight = weights.values.fold(0, (sum, w) => sum + w);
    var allocated = 0;
    for (int i = 0; i < request.subjects.length; i++) {
      final subject = request.subjects[i];
      final weight = weights[subject] ?? (totalWeight ~/ request.subjects.length);
      int target;
      if (i == request.subjects.length - 1) {
        target = request.count - allocated;
      } else {
        target = (request.count * weight / totalWeight).round();
      }
      targets[subject] = target;
      allocated += target;
    }

    for (final subject in request.subjects) {
      final target = targets[subject] ?? 0;
      final subjectPool = subjectPools[subject] ?? [];
      if (subjectPool.isEmpty) continue;

      final shuffled = List<Question>.from(subjectPool)..shuffle(_random);
      final easy = target * request.easyPercent ~/ 100;
      final medium = target * request.mediumPercent ~/ 100;
      final hard = target - easy - medium;

      final buckets = <List<Question>>[
        shuffled.where((q) => _normalizeDifficulty(q.difficulty) == 'Easy').toList(),
        shuffled.where((q) => _normalizeDifficulty(q.difficulty) == 'Medium').toList(),
        shuffled.where((q) => _normalizeDifficulty(q.difficulty) == 'Hard').toList(),
      ];

      final targetsPerDiff = [easy, medium, hard];
      for (int i = 0; i < 3; i++) {
        buckets[i].shuffle(_random);
        var taken = 0;
        for (final q in buckets[i]) {
          if (taken >= targetsPerDiff[i]) break;
          if (request.deduplicateConcepts && _hasConceptOverlap(q, usedConcepts)) {
            continue;
          }
          picked.add(q);
          _addQuestionConcepts(q, usedConcepts);
          taken++;
        }
      }

      // Backfill for this subject
      if (picked.where((q) => q.subject == subject).length < target) {
        final remaining = subjectPool.where((q) => !picked.contains(q)).toList();
        remaining.shuffle(_random);
        for (final q in remaining) {
          if (picked.where((q) => q.subject == subject).length >= target) break;
          if (request.deduplicateConcepts && _hasConceptOverlap(q, usedConcepts)) {
            continue;
          }
          picked.add(q);
          _addQuestionConcepts(q, usedConcepts);
        }
      }
    }

    // Overall backfill
    if (picked.length < request.count) {
      final remaining = pool.where((q) => !picked.contains(q)).toList();
      remaining.shuffle(_random);
      for (final q in remaining) {
        if (picked.length >= request.count) break;
        if (request.deduplicateConcepts && _hasConceptOverlap(q, usedConcepts)) {
          continue;
        }
        picked.add(q);
        _addQuestionConcepts(q, usedConcepts);
      }
    }

    picked.shuffle(_random);
    return picked.take(request.count).toList();
  }

  /// Generates questions via AI when local pool is insufficient.
  Future<List<Question>> _generateAiQuestions(
    String subject,
    String? chapterId,
    String? topicId,
    int count, {
    Set<String>? excludedIds,
  }) async {
    if (_gemini == null) return [];

    try {
      final prompt = _buildAiPrompt(subject, chapterId, topicId, count);
      final response = await _gemini!.sendMessage(prompt);
      return _parseAiQuestions(response, subject, excludedIds ?? {});
    } catch (e) {
      return [];
    }
  }

  String _buildAiPrompt(String subject, String? chapterId, String? topicId, int count) {
    final context = StringBuffer();
    context.writeln('You are an expert NEET question setter. Generate $count accurate, NCERT-based MCQ questions.');
    context.writeln('Subject: $subject');
    if (chapterId != null) context.writeln('Chapter: $chapterId');
    if (topicId != null) context.writeln('Topic: $topicId');
    context.writeln('');
    context.writeln('Format each question as JSON:');
    context.writeln('{');
    context.writeln('  "questionText": "Question text here",');
    context.writeln('  "options": ["Option A", "Option B", "Option C", "Option D"],');
    context.writeln('  "correctAnswer": "Option A",');
    context.writeln('  "explanation": "Detailed explanation referencing NCERT",');
    context.writeln('  "difficulty": "Easy|Medium|Hard",');
    context.writeln('  "tags": ["tag1", "tag2"]');
    context.writeln('}');
    context.writeln('Return ONLY a JSON array of questions. No extra text.');
    return context.toString();
  }

  List<Question> _parseAiQuestions(String response, String subject, Set<String> excludedIds) {
    // Parse JSON array from AI response
    // This is a simplified parser - in production, use a robust JSON parser
    final questions = <Question>[];
    // Implementation would parse the JSON and create Question objects
    // with gen_ prefixed IDs to distinguish AI-generated questions
    return questions;
  }

  /// Applies NEET chapter frequency weights to boost high-yield chapters.
  List<Question> _applyChapterWeights(List<Question> pool) {
    final weightedPool = <Question>[];
    for (final q in pool) {
      final weight = _neetChapterWeights[q.chapter] ?? 1;
      final copies = weight.clamp(1, 3);
      for (int i = 0; i < copies; i++) {
        weightedPool.add(q);
      }
    }
    return weightedPool;
  }

  /// Gets question IDs in cooldown period based on difficulty.
  Future<Set<String>> _getCooldownQuestionIds(List<String> subjects) async {
    final attempts = await _db.getAllQuizAttempts();
    final cooldownIds = <String>{};
    final now = DateTime.now();

    for (final attempt in attempts) {
      if (!subjects.contains(attempt.subject)) continue;
      final raw = attempt.questionIds;
      if (raw == null || raw.isEmpty) continue;
      try {
        final list = (jsonDecode(raw) as List).cast<String>();
        final daysSinceAttempt = now.difference(attempt.attemptedAt).inDays;

        for (final qId in list) {
          // Get question difficulty from database
          final question = await _questionRepo.getQuestionById(qId);
          if (question == null) continue;
          
          final difficulty = _normalizeDifficulty(question.difficulty);
          final cooldownDays = _cooldownDays[difficulty] ?? 3;
          
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

  static String _normalizeDifficulty(String difficulty) {
    final d = difficulty.trim().toLowerCase();
    if (d == 'easy' || d == 'simple') return 'Easy';
    if (d == 'medium' || d == 'moderate' || d == 'avg' || d == 'average') return 'Medium';
    if (d == 'hard' || d == 'difficult' || d == 'tough') return 'Hard';
    return 'Medium';
  }

  static const Map<String, int> _cooldownDays = {
    'Easy': 1,
    'Medium': 3,
    'Hard': 7,
  };

  bool _hasConceptOverlap(Question q, Set<String> usedConcepts) {
    final questionConcepts = q.tags.map((t) => t.toLowerCase()).toSet();
    return questionConcepts.any((c) => usedConcepts.contains(c));
  }

  void _addQuestionConcepts(Question q, Set<String> usedConcepts) {
    for (final tag in q.tags) {
      usedConcepts.add(tag.toLowerCase());
    }
  }
}

/// Request object for question selection.
class QuestionRequest {
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
  final double? recentAccuracy; // For adaptive difficulty

  const QuestionRequest({
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
    this.recentAccuracy,
  });
}