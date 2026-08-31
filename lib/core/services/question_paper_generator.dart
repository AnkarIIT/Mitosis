import 'dart:math';
import '../models/question_model.dart';
import '../models/question_paper_model.dart';
import '../constants/neet_sample_data.dart';

class QuestionPaperGenerator {
  final Random _random = Random();

  /// Generate a custom question paper
  Future<QuestionPaper> generatePaper({
    required List<String> selectedSubjects,
    required PaperStandard standard,
    bool removeYearMarking = true,
    List<Question>? questionPool,
    Map<String, int>? chapterQuotas,
  }) async {
    try {
      final config = PaperConfig.getConfig(standard);

      // Get all PYQ questions for selected subjects (from provided pool or full set)
      final allPYQs = _getPYQsForSubjects(selectedSubjects, questionPool);

      if (allPYQs.isEmpty) {
        throw Exception('No questions available for selected subjects');
      }

      // Validate / cap question count (tolerant for small sample datasets)
      final targetCount = config.questionCount;
      final actualCount = allPYQs.length < targetCount
          ? allPYQs.length
          : targetCount;

      // Select random questions without repetition (balanced difficulty)
      final selectedQuestions = _selectRandomQuestions(
        allPYQs,
        actualCount,
        chapterQuotas: chapterQuotas,
      );

      // Shuffle questions
      selectedQuestions.shuffle(_random);

      // Remove year marking if requested (clean NCERT refs for practice)
      final processedQuestions = removeYearMarking
          ? _removeYearMarking(selectedQuestions)
          : selectedQuestions;

      // Create question paper (with actual count)
      final paper = QuestionPaper(
        id: _generatePaperId(),
        title: _generateTitle(
          selectedSubjects,
          standard,
          actualCount != targetCount,
        ),
        description: _generateDescription(
          selectedSubjects,
          standard,
          actualCount,
        ),
        subjects: selectedSubjects,
        questions: processedQuestions,
        standard: standard,
        createdAt: DateTime.now(),
        timeLimit: config.timeLimit,
        showYearMarking: !removeYearMarking,
      );

      return paper;
    } catch (e) {
      // ignore: avoid_print
      print('Error generating paper: $e');
      rethrow;
    }
  }

  /// Get all questions for selected subjects (optionally from a provided pool)
  List<Question> _getPYQsForSubjects(
    List<String> subjects, [
    List<Question>? pool,
  ]) {
    final source = pool ?? getAllQuestions();
    final allQuestions = <Question>[];

    for (var subject in subjects) {
      final subjectQuestions = source
          .where((q) => q.subject == subject)
          .toList();
      allQuestions.addAll(subjectQuestions);
    }

    return allQuestions;
  }

  /// Select random questions without repetition, targeting ~40% Easy / 40% Medium / 20% Hard
  /// Optionally enforces [chapterQuotas] which limits the max questions per chapter.
  List<Question> _selectRandomQuestions(
    List<Question> availableQuestions,
    int count, {
    Map<String, int>? chapterQuotas,
  }) {
    final selected = <Question>[];
    final usedIds = <String>{};
    // Track how many questions we've taken per chapter.
    final chapterCounts = <String, int>{};

    // Bucket by difficulty
    final easy = availableQuestions
        .where((q) => q.difficulty == 'Easy')
        .toList();
    final medium = availableQuestions
        .where((q) => q.difficulty == 'Medium')
        .toList();
    final hard = availableQuestions
        .where((q) => q.difficulty == 'Hard')
        .toList();

    // Target distribution: Easy 40%, Medium 40%, Hard 20%
    // Floor easy/medium so the buckets can never overshoot `count`, then give
    // any remainder to hard and top up from the general pool below.
    final easyCount = (count * 0.4).floor();
    final mediumCount = (count * 0.4).floor();
    var hardCount = count - easyCount - mediumCount;
    if (hardCount < 0) hardCount = 0;

    // Add from buckets (no dups within)
    _addRandomQuestions(
      selected,
      usedIds,
      easy,
      easyCount,
      chapterQuotas: chapterQuotas,
      chapterCounts: chapterCounts,
    );
    _addRandomQuestions(
      selected,
      usedIds,
      medium,
      mediumCount,
      chapterQuotas: chapterQuotas,
      chapterCounts: chapterCounts,
    );
    _addRandomQuestions(
      selected,
      usedIds,
      hard,
      hardCount,
      chapterQuotas: chapterQuotas,
      chapterCounts: chapterCounts,
    );

    // Fallback: fill any remaining from unused (handles low counts per bucket)
    while (selected.length < count) {
      final remaining = availableQuestions
          .where((q) => !usedIds.contains(q.id))
          .toList();

      if (remaining.isEmpty) break;

      // Filter remaining by chapter quotas
      final filteredRemaining = chapterQuotas != null
          ? remaining.where((q) {
              final current = chapterCounts[q.chapter] ?? 0;
              final quota = chapterQuotas[q.chapter];
              return quota == null || current < quota;
            }).toList()
          : remaining;

      if (filteredRemaining.isEmpty) break;

      final question = filteredRemaining[_random.nextInt(filteredRemaining.length)];
      selected.add(question);
      usedIds.add(question.id);
      chapterCounts[question.chapter] = (chapterCounts[question.chapter] ?? 0) + 1;
    }

    // Guard: never return more than the requested count.
    if (selected.length > count) {
      selected.removeRange(count, selected.length);
    }

    return selected;
  }

  /// Add up to `count` random unused questions from source list,
  /// optionally respecting [chapterQuotas] and updating [chapterCounts].
  void _addRandomQuestions(
    List<Question> selected,
    Set<String> usedIds,
    List<Question> source,
    int count, {
    Map<String, int>? chapterQuotas,
    Map<String, int>? chapterCounts,
  }) {
    var available = source.where((q) => !usedIds.contains(q.id)).toList();

    // Filter by chapter quotas if provided
    if (chapterQuotas != null && chapterCounts != null) {
      available = available.where((q) {
        final current = chapterCounts[q.chapter] ?? 0;
        final quota = chapterQuotas[q.chapter];
        return quota == null || current < quota;
      }).toList();
    }

    for (int i = 0; i < count && available.isNotEmpty; i++) {
      final question = available[_random.nextInt(available.length)];
      selected.add(question);
      usedIds.add(question.id);
      if (chapterCounts != null) {
        chapterCounts[question.chapter] = (chapterCounts[question.chapter] ?? 0) + 1;
      }
      available.remove(question);
    }
  }

  /// Remove year marking from ncertReference (keeps year field for internal use)
  List<Question> _removeYearMarking(List<Question> questions) {
    return questions.map((q) {
      final cleanRef = (q.ncertReference ?? q.chapter)
          .replaceAll(RegExp(r'\d{4}'), '') // Remove 4-digit years
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      return Question(
        id: q.id,
        subject: q.subject,
        chapter: q.chapter,
        topic: q.topic,
        topicId: q.topicId,
        questionText: q.questionText,
        options: q.options,
        correctAnswer: q.correctAnswer,
        explanation: q.explanation,
        ncertReference: cleanRef.isEmpty ? q.chapter : cleanRef,
        year: q.year,
        difficulty: q.difficulty,
        tags: q.tags,
        imageUrl: q.imageUrl,
        type: q.type,
      );
    }).toList();
  }

  /// Generate unique paper ID
  String _generatePaperId() {
    return 'PAPER_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate title (notes if capped due to data limits)
  String _generateTitle(
    List<String> subjects,
    PaperStandard standard, [
    bool capped = false,
  ]) {
    final config = PaperConfig.getConfig(standard);
    final subjectsStr = subjects.join(' + ');
    final base = '$subjectsStr - ${config.displayName}';
    return capped ? '$base (Sample)' : base;
  }

  /// Generate description
  String _generateDescription(
    List<String> subjects,
    PaperStandard standard,
    int actualCount,
  ) {
    final config = PaperConfig.getConfig(standard);
    final distribution = _getDistributionText(subjects.length);
    final base = '${config.description} | $distribution';
    if (actualCount < config.questionCount) {
      return '$base • Using $actualCount available questions';
    }
    return base;
  }

  /// Get distribution text
  String _getDistributionText(int subjectCount) {
    if (subjectCount == 1) {
      return 'Single Subject Test';
    } else if (subjectCount == 2) {
      return 'Dual Subject Test';
    } else {
      return 'Multi-Subject Test';
    }
  }

  /// Get statistics about the paper
  Map<String, dynamic> getPaperStats(QuestionPaper paper) {
    return {
      'totalQuestions': paper.totalQuestions,
      'subjects': paper.subjects,
      'subjectDistribution': paper.subjectDistribution,
      'difficultyDistribution': paper.difficultyDistribution,
      'estimatedDuration': paper.timeLimit?.inMinutes ?? 'N/A',
      'createdAt': paper.createdAt.toString(),
    };
  }
}
