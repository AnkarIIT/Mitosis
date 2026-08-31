import 'package:drift/drift.dart';
import '../database/drift_database.dart' as db;

/// Service for tracking DPP streaks and analytics.
class DppStreakService {
  final db.AppDatabase _db;

  DppStreakService(this._db);

  /// Gets the current DPP streak for a subject.
  /// A streak is consecutive days with a completed DPP.
  Future<int> getCurrentStreak(String subject) async {
    final sets = await _db.getDppSets();
    final subjectSets = sets
        .where((s) => s.subject == subject && s.isCompleted)
        .toList();
    
    if (subjectSets.isEmpty) return 0;

    // Sort by date descending
    subjectSets.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime expectedDate = DateTime.now();
    // Check if today's DPP is completed
    final todayStr = _dateStr(expectedDate);
    final todayCompleted = subjectSets.any((s) => s.date == todayStr && s.isCompleted);
    
    if (!todayCompleted) {
      // Check yesterday
      expectedDate = expectedDate.subtract(const Duration(days: 1));
    }

    for (final set in subjectSets) {
      final setDate = DateTime.parse(set.date);
      if (_isSameDay(setDate, expectedDate)) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (setDate.isBefore(expectedDate)) {
        break;
      }
    }

    return streak;
  }

  /// Gets the longest DPP streak for a subject.
  Future<int> getLongestStreak(String subject) async {
    final sets = await _db.getDppSets();
    final subjectSets = sets
        .where((s) => s.subject == subject && s.isCompleted)
        .toList();
    
    if (subjectSets.isEmpty) return 0;

    subjectSets.sort((a, b) => a.date.compareTo(b.date));

    int longest = 1;
    int current = 1;
    DateTime? prevDate;

    for (final set in subjectSets) {
      final date = DateTime.parse(set.date);
      if (prevDate != null) {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          current++;
          longest = longest > current ? longest : current;
        } else if (diff > 1) {
          current = 1;
        }
      }
      prevDate = date;
    }

    return longest;
  }

  /// Gets DPP analytics for a subject.
  Future<DppAnalytics> getAnalytics(String subject) async {
    final sets = await _db.getDppSets();
    final subjectSets = sets.where((s) => s.subject == subject).toList();
    
    if (subjectSets.isEmpty) {
      return DppAnalytics(
        subject: subject,
        totalAttempts: 0,
        completedCount: 0,
        totalQuestions: 0,
        correctCount: 0,
        averageAccuracy: 0.0,
        averageTimeMinutes: 0.0,
        currentStreak: 0,
        longestStreak: 0,
        weeklyData: {},
        subjectBreakdown: {},
      );
    }

    subjectSets.sort((a, b) => a.date.compareTo(b.date));

    int completedCount = 0;
    int totalQuestions = 0;
    int correctCount = 0;
    int totalTimeSeconds = 0;

    final weeklyData = <DateTime, DppWeeklyData>{};
    final subjectBreakdown = <String, DppSubjectBreakdown>{};
    DateTime? prevDate;

    for (final set in subjectSets) {
      if (set.isCompleted) {
        completedCount++;
        totalQuestions += set.totalQuestions as int;
        correctCount += set.correctCount as int;
        totalTimeSeconds += set.timeSpentSeconds as int;

        final date = DateTime.parse(set.date);
        final weekStart = _weekStart(date);
        
        weeklyData.putIfAbsent(weekStart, () => DppWeeklyData(
          weekStart: weekStart,
          attempts: 0,
          completed: 0,
          totalQuestions: 0,
          correctCount: 0,
          totalTimeSeconds: 0,
        ));
        final weekData = weeklyData[weekStart]!;
        weekData.attempts++;
        weekData.completed++;
        weekData.totalQuestions += set.totalQuestions as int;
        weekData.correctCount += set.correctCount as int;
        weekData.totalTimeSeconds += set.timeSpentSeconds as int;

        // Per-subject breakdown (for multi-subject DPPs)
        final questions = await _db.getDppQuestions(set.id);
        for (final q in questions) {
          final subj = q.subject;
          subjectBreakdown.putIfAbsent(subj, () => DppSubjectBreakdown(
            subject: subj,
            attempts: 0,
            correct: 0,
            total: 0,
          ));
          subjectBreakdown[subj]!.attempts++;
          subjectBreakdown[subj]!.total++;
          // We'd need to check if this specific question was answered correctly
          // For now, we'll estimate based on overall accuracy
        }
        
        if (prevDate != null) {
          final diff = date.difference(prevDate).inDays;
          // Track streaks
        }
        prevDate = date;
      } else {
        // For non-completed sets, still track date for streak calculation
        if (prevDate != null) {
          final date = DateTime.parse(set.date);
          final diff = date.difference(prevDate).inDays;
          // Track streaks
        }
        prevDate = DateTime.parse(set.date);
      }
    }

    final currentStreak = await getCurrentStreak(subject);
    final longestStreak = await getLongestStreak(subject);

    // Calculate per-subject breakdown accuracy
    for (final breakdown in subjectBreakdown.values) {
      if (breakdown.total > 0 && completedCount > 0) {
        breakdown.correct = (breakdown.total * correctCount / totalQuestions).round();
      }
    }

    return DppAnalytics(
      subject: subject,
      totalAttempts: subjectSets.length,
      completedCount: completedCount,
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      averageAccuracy: completedCount > 0 ? (correctCount / totalQuestions * 100) : 0.0,
      averageTimeMinutes: completedCount > 0 ? (totalTimeSeconds / completedCount / 60) : 0.0,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      weeklyData: weeklyData.map((k, v) => MapEntry(k, v)),
      subjectBreakdown: subjectBreakdown.map((k, v) => MapEntry(k, v)),
    );
  }

  /// Gets all DPP analytics across subjects.
  Future<Map<String, DppAnalytics>> getAllAnalytics() async {
    final sets = await _db.getDppSets();
    final subjects = sets.map((s) => s.subject).toSet();
    
    final analytics = <String, DppAnalytics>{};
    for (final subject in subjects) {
      analytics[subject] = await getAnalytics(subject);
    }
    return analytics;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateStr(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  DateTime _weekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
}

/// DPP Analytics data class.
class DppAnalytics {
  final String subject;
  final int totalAttempts;
  final int completedCount;
  final int totalQuestions;
  final int correctCount;
  final double averageAccuracy;
  final double averageTimeMinutes;
  final int currentStreak;
  final int longestStreak;
  final Map<DateTime, DppWeeklyData> weeklyData;
  final Map<String, DppSubjectBreakdown> subjectBreakdown;

  const DppAnalytics({
    required this.subject,
    required this.totalAttempts,
    required this.completedCount,
    required this.totalQuestions,
    required this.correctCount,
    required this.averageAccuracy,
    required this.averageTimeMinutes,
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyData,
    required this.subjectBreakdown,
  });
}

/// Weekly DPP data.
class DppWeeklyData {
  final DateTime weekStart;
  int attempts;
  int completed;
  int totalQuestions;
  int correctCount;
  int totalTimeSeconds;

  DppWeeklyData({
    required this.weekStart,
    required this.attempts,
    required this.completed,
    required this.totalQuestions,
    required this.correctCount,
    required this.totalTimeSeconds,
  });

  double get accuracy => totalQuestions > 0 ? (correctCount / totalQuestions * 100) : 0.0;
  double get avgTimeMinutes => completed > 0 ? (totalTimeSeconds / completed / 60) : 0.0;
}

/// Per-subject breakdown for multi-subject DPPs.
class DppSubjectBreakdown {
  final String subject;
  int attempts;
  int correct;
  int total;

  DppSubjectBreakdown({
    required this.subject,
    required this.attempts,
    required this.correct,
    required this.total,
  });

  double get accuracy => total > 0 ? (correct / total * 100) : 0.0;
}