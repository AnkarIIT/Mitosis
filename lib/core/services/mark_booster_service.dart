import 'dart:math';

import '../models/mark_booster_model.dart';
import '../models/question_model.dart';
import '../models/user_progress_model.dart';
/// Builds personalized re-attempt drills from the Mark Booster diagnosis.
///
/// Priority order:
/// 1. Unresolved Error Book questions (highest value — you got them wrong).
/// 2. Questions from weak topics, interleaved across the weakest chapters.
/// 3. Random same-bank filler to reach the requested size.
class MarkBoosterService {
  /// A topic is considered mastered once its accuracy reaches this threshold.
  static const double masteryThreshold = 60;

  /// Progress (0.0–1.0) of a weak topic toward the mastery threshold.
  static double masteryProgress(double accuracy) =>
      (accuracy / masteryThreshold).clamp(0.0, 1.0);

  /// Whether the topic has crossed the mastery threshold with enough
  /// attempts to be meaningful.
  static bool isTopicMastered(int questionsAttempted, double accuracy) =>
      questionsAttempted >= 5 && accuracy >= masteryThreshold;

  static List<Question> buildDrill({
    required MarkBoosterDiagnosis diagnosis,
    required List<Question> allQuestions,
    required int size,
    Random? random,
  }) {
    final rng = random ?? Random();

    final priority = <Question>[];
    final priorityIds = <String>{};

    void addQuestion(Question q) {
      if (priorityIds.add(q.id)) {
        priority.add(q);
      }
    }

    for (final q in diagnosis.errorBookQuestions) {
      addQuestion(q);
    }

    for (final weak in diagnosis.weakTopics) {
      final pool = allQuestions.where((q) => q.topicId == weak.topic.id).toList()
        ..shuffle(rng);
      for (final q in pool.take(3)) {
        addQuestion(q);
      }
    }

    final selected = <Question>[];
    final selectedIds = <String>{};

    for (final q in priority) {
      if (selected.length >= size) break;
      if (selectedIds.add(q.id)) {
        selected.add(q);
      }
    }

    if (selected.length < size) {
      final extras = allQuestions
          .where((q) => !selectedIds.contains(q.id))
          .toList()
        ..shuffle(rng);
      for (final q in extras) {
        if (selected.length >= size) break;
        selected.add(q);
      }
    }

    return selected;
  }

  /// Re-maps a stored error book entry back to its [Question], or null if
  /// the question is no longer in the bank.
  static Question? resolveErrorBookEntry(
    String questionId,
    List<Question> allQuestions,
  ) {
    for (final q in allQuestions) {
      if (q.id == questionId) return q;
    }
    return null;
  }

  /// Aggregates per-topic correctness from a completed quiz state.
  ///
  /// Used so multi-topic attempts (e.g. Mark Booster drills) credit each
  /// question's own topic instead of a single umbrella topic.
  static Map<String, ({int correct, int total})> aggregateTopicResults({
    required List<Question> questions,
    required Map<int, bool> answerResults,
  }) {
    final map = <String, ({int correct, int total})>{};
    for (var i = 0; i < questions.length; i++) {
      final stat = map[questions[i].topicId] ?? (correct: 0, total: 0);
      final isCorrect = answerResults[i] ?? false;
      map[questions[i].topicId] = (
        correct: stat.correct + (isCorrect ? 1 : 0),
        total: stat.total + 1,
      );
    }
    return map;
  }

  /// Recent Mark Booster drill sessions, newest first.
  static List<QuizAttempt> extractBoosterSessions(
    List<QuizAttempt> attempts, {
    int limit = 8,
  }) {
    final sessions = attempts
        .where((a) => a.testType == 'booster')
        .toList()
      ..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
    return sessions.take(limit).toList();
  }
}
