import '../database/drift_database.dart' as db;
import '../models/question_model.dart';

/// Computes a 0–100 mastery score per topic from local attempt history.
///
/// Sources:
/// - Spaced-repetition cards (SM-2 box ≤ 2 → low mastery)
/// - Topic progress entries (accuracy from `questionsCorrect / questionsAttempted`)
/// - Quiz/DPP attempts (recent incorrect answers)
///
/// Returns a map of `topicId → masteryScore` where 0 = weakest, 100 = strongest.
class MasteryService {
  final db.AppDatabase _db;
  final Future<List<Question>> _questionBankFuture;

  MasteryService(this._db, this._questionBankFuture);

  Future<List<Question>> get _bank async => _questionBankFuture;

  Future<Map<String, double>> computeTopicMastery() async {
    final result = <String, double>{};

    // 1. Topic progress accuracy (0–100).
    final allProgress = await _db.getAllTopicProgress();
    for (final entry in allProgress) {
      final accuracy = entry.questionsAttempted > 0
          ? entry.questionsCorrect / entry.questionsAttempted
          : 0.5;
      result[entry.topicId] = (accuracy * 100).clamp(0.0, 100.0);
    }

    // 2. Downgrade topics with spaced-repetition cards in early boxes.
    final cards = await _db.getSpacedRepetitionCards();
    for (final card in cards) {
      if (card.box <= 2) {
        final current = result[card.questionId] ?? 50.0;
        result[card.questionId] = (current * 0.7).clamp(0.0, 100.0);
      }
    }

    // 3. Ensure every topic in the question bank has at least a neutral score.
    final questions = await _bank;
    for (final q in questions) {
      result.putIfAbsent(q.topicId, () => 50.0);
    }

    return result;
  }

  /// Returns topic IDs sorted by ascending mastery (weakest first).
  Future<List<String>> weakTopicIds(List<String> subjects, {int limit = 20}) async {
    final mastery = await computeTopicMastery();
    final questions = await _bank;
    final filtered = mastery.entries
        .where((e) {
          // Keep only topics whose questions belong to the requested subjects.
          return questions
              .any((q) => q.topicId == e.key && subjects.contains(q.subject));
        })
        .toList();
    filtered.sort((a, b) => a.value.compareTo(b.value));
    return filtered.take(limit).map((e) => e.key).toList();
  }
}
