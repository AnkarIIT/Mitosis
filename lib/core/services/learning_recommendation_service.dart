import '../models/learning_recommendation.dart';
import '../models/subject_model.dart';
import '../models/user_progress_model.dart';
import 'retention_service.dart';

class LearningRecommendationService {
  const LearningRecommendationService();

  List<LearningRecommendation> build({
    required List<Subject> subjects,
    required Map<String, TopicProgress> progress,
    required List<QuizAttempt> attempts,
    int limit = 3,
  }) {
    const retention = RetentionService();
    final topics = [
      for (final subject in subjects)
        for (final chapter in subject.chapters)
          for (final topic in chapter.topics)
            (topic: topic, chapterId: chapter.id, subject: subject.name),
    ];

    final recommendations = topics.map((entry) {
      final topicProgress = progress[entry.topic.id];
      final topicAttempts =
          attempts
              .where((attempt) => attempt.topicId == entry.topic.id)
              .toList()
            ..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
      final mastery = topicProgress == null
          ? 0.0
          : retention.retentionAdjustedMastery(
              topicProgress,
              now: DateTime.now(),
            );
      final diagnosis = _diagnosis(topicProgress, topicAttempts);
      final actions = _actions(topicProgress, topicAttempts);

      return LearningRecommendation(
        topicId: entry.topic.id,
        topicName: entry.topic.name,
        subject: entry.subject,
        chapterId: entry.chapterId,
        mastery: mastery,
        diagnosis: diagnosis,
        primaryAction: actions.first,
        actions: actions,
      );
    }).toList();

    recommendations.sort((a, b) {
      final aUnassessed = a.diagnosis == 'Not assessed yet';
      final bUnassessed = b.diagnosis == 'Not assessed yet';
      if (aUnassessed != bUnassessed) return aUnassessed ? 1 : -1;
      final masteryOrder = a.mastery.compareTo(b.mastery);
      if (masteryOrder != 0) return masteryOrder;
      return a.topicName.compareTo(b.topicName);
    });
    return recommendations.take(limit).toList(growable: false);
  }

  String _diagnosis(TopicProgress? progress, List<QuizAttempt> attempts) {
    if (progress == null || progress.questionsAttempted == 0) {
      return 'Not assessed yet';
    }
    if (progress.accuracy < 50) return 'Concept accuracy is low';
    if (progress.averageTimeSeconds > 75) {
      return 'Accuracy is acceptable, but solving speed is low';
    }
    if (attempts.length >= 2 &&
        attempts.first.accuracy < attempts[1].accuracy - 10) {
      return 'Recent performance is falling';
    }
    return 'Ready for a focused retest';
  }

  List<LearningActionType> _actions(
    TopicProgress? progress,
    List<QuizAttempt> attempts,
  ) {
    if (progress == null || progress.questionsAttempted == 0) {
      return const [LearningActionType.assess, LearningActionType.practice];
    }
    if (progress.accuracy < 50) {
      return const [
        LearningActionType.revise,
        LearningActionType.practice,
        LearningActionType.retest,
      ];
    }
    if (progress.averageTimeSeconds > 75) {
      return const [LearningActionType.speedDrill, LearningActionType.retest];
    }
    return const [LearningActionType.retest, LearningActionType.practice];
  }
}
