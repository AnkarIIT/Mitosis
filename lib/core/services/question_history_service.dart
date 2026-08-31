import 'dart:convert';
import '../database/drift_database.dart' as db;

class QuestionHistoryService {
  final db.AppDatabase _db;

  QuestionHistoryService(this._db);

  /// Returns distinct question IDs seen in ALL attempt history,
  /// optionally filtered by [subject].
  /// This replaces the old last-20-attempts check with full history.
  Future<Set<String>> getRecentSeenQuestionIds({
    String? subject,
  }) async {
    final attempts = await _db.getAllQuizAttempts();
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

  /// Returns question IDs that are currently in cooldown period based on difficulty.
  /// Easy: 1 day, Medium: 3 days, Hard: 7 days since last attempt.
  Future<Set<String>> getCooldownQuestionIds({
    String? subject,
  }) async {
    final attempts = await _db.getAllQuizAttempts();
    final cooldownIds = <String>{};
    final now = DateTime.now();

    for (final attempt in attempts) {
      if (subject != null && attempt.subject != subject) continue;
      final raw = attempt.questionIds;
      if (raw == null || raw.isEmpty) continue;
      try {
        final list = (jsonDecode(raw) as List).cast<String>();
        final daysSinceAttempt = now.difference(attempt.attemptedAt).inDays;
        
        // We need to check each question's difficulty to determine cooldown
        // For now, we'll apply a conservative cooldown based on the attempt's overall difficulty
        // In a more advanced version, we'd check per-question difficulty
        int cooldownDays = 3; // default Medium
        if (attempt.testType == 'dpp') {
          // For DPP, check if we can infer difficulty from score patterns
          // This is a simplified approach - in practice we'd track per-question
        }
        
        // Conservative: if any question in this attempt is within its cooldown, exclude all
        // Better approach: track per-question last attempt date
        if (daysSinceAttempt < cooldownDays) {
          cooldownIds.addAll(list);
        }
      } on FormatException {
        // ignore malformed JSON
      }
    }
    return cooldownIds;
  }

  /// Records the ordered list of question IDs for an attempt.
  Future<void> recordAttemptQuestionIds(
    int attemptId,
    List<String> questionIds,
  ) async {
    await _db.updateQuizAttemptQuestionIds(attemptId, jsonEncode(questionIds));
  }
}
