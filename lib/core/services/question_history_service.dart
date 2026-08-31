import 'dart:convert';
import '../database/drift_database.dart' as db;

class QuestionHistoryService {
  final db.AppDatabase _db;

  QuestionHistoryService(this._db);

  /// Returns distinct question IDs seen in the last [maxAttempts] attempts,
  /// optionally filtered by [subject].
  Future<Set<String>> getRecentSeenQuestionIds({
    int maxAttempts = 20,
    String? subject,
  }) async {
    final attempts = await _db.getRecentQuizAttempts(maxAttempts);
    final ids = <String>{};
    for (final attempt in attempts) {
      if (subject != null && attempt.subject != subject) continue;
      final raw = attempt.questionIds;
      if (raw == null || raw.isEmpty) continue;
      try {
        final list = (jsonDecode(raw) as List).cast<String>();
        ids.addAll(list);
      } on FormatException {
        // ignore malformed JSON
      }
    }
    return ids;
  }

  /// Records the ordered list of question IDs for an attempt.
  Future<void> recordAttemptQuestionIds(
    int attemptId,
    List<String> questionIds,
  ) async {
    await _db.updateQuizAttemptQuestionIds(attemptId, jsonEncode(questionIds));
  }
}
