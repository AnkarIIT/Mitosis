import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement_model.dart';
import '../providers/user_providers.dart';

class AchievementService {
  static const String _earnedKey = 'achievements_earned';

  /// Evaluate which achievements are earned for the current user stats.
  static List<Achievement> evaluateEarned(UserProgressState progress) {
    final stats = <String, dynamic>{
      'totalAttempted': progress.totalQuestionsAttempted,
      'accuracy': progress.overallAccuracy,
      'quizCount': progress.quizAttempts.length,
      'streak': progress.currentStreak,
      'fullMockCount': _fullMockCount(progress),
    };

    return Achievement.all.where((achievement) {
      final value = stats[achievement.statKey];
      if (value == null) return false;
      if (value is int) return value >= achievement.threshold;
      if (value is double) return value >= achievement.threshold.toDouble();
      return false;
    }).toList();
  }

  static int _fullMockCount(UserProgressState progress) {
    return progress.quizAttempts.where((a) => a.testType == 'mock').length;
  }

  /// Load earned achievement IDs from persistent storage.
  static Future<Set<String>> loadEarnedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_earnedKey);
      return stored != null ? stored.toSet() : <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  /// Persist earned achievement IDs.
  static Future<void> saveEarnedIds(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_earnedKey, ids.toList());
    } catch (_) {
      // ignore
    }
  }

  /// Compute newly earned achievements compared to previously saved state.
  static Future<List<Achievement>> computeNewEarnings(
    UserProgressState progress,
  ) async {
    final earned = evaluateEarned(progress);
    final previous = await loadEarnedIds();
    final newOnes = earned.where((a) => !previous.contains(a.id)).toList();

    if (newOnes.isNotEmpty) {
      final updated = previous.union(earned.map((a) => a.id).toSet());
      await saveEarnedIds(updated);
    }

    return newOnes;
  }

  /// Return all achievements with their earned/locked state.
  static List<Map<String, dynamic>> achievementBoard(UserProgressState progress) {
    final earned = evaluateEarned(progress).map((a) => a.id).toSet();
    return Achievement.all.map((a) {
      return {
        'achievement': a,
        'earned': earned.contains(a.id),
      };
    }).toList();
  }
}
