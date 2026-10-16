import '../models/learning_diagnostics.dart';
import '../models/user_progress_model.dart';

class RetentionService {
  const RetentionService();

  List<RetentionCheck> scheduleFor(
    String topicId,
    DateTime lastAttempted, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    return [3, 7, 14]
        .map(
          (days) => RetentionCheck(
            topicId: topicId,
            dueAt: lastAttempted.add(Duration(days: days)),
            intervalDays: days,
            isDue: !lastAttempted.add(Duration(days: days)).isAfter(current),
          ),
        )
        .toList(growable: false);
  }

  double retentionAdjustedMastery(
    TopicProgress progress, {
    required DateTime now,
  }) {
    if (progress.questionsAttempted == 0) return 0;
    final daysSinceAttempt =
        now.difference(progress.lastAttempted).inHours / 24;
    final decay = (daysSinceAttempt / 30).clamp(0.0, 0.35);
    return (progress.accuracy * (1 - decay)).clamp(0.0, 100.0);
  }
}
