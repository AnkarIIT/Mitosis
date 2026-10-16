import '../models/learning_recommendation.dart';
import '../models/study_plan.dart';

class StudyPlanService {
  const StudyPlanService();

  DailyStudyPlan build({
    required List<LearningRecommendation> recommendations,
    int commitmentMinutes = 60,
    DateTime? date,
  }) {
    final day = date ?? DateTime.now();
    final budget = commitmentMinutes.clamp(15, 240);
    if (recommendations.isEmpty) {
      return DailyStudyPlan(date: day, totalMinutes: 0, items: const []);
    }

    var remaining = budget;
    final items = <StudyPlanItem>[];
    for (final recommendation in recommendations) {
      if (remaining <= 0) break;
      final action = recommendation.primaryAction;
      final minutes = _minutesFor(action, remaining);
      items.add(
        StudyPlanItem(
          topicId: recommendation.topicId,
          action: action,
          minutes: minutes,
          title: _titleFor(action),
          rationale: recommendation.diagnosis,
        ),
      );
      remaining -= minutes;
    }

    return DailyStudyPlan(
      date: day,
      totalMinutes: budget - remaining,
      items: List.unmodifiable(items),
    );
  }

  int _minutesFor(LearningActionType action, int remaining) {
    final suggested = switch (action) {
      LearningActionType.revise => 20,
      LearningActionType.practice => 25,
      LearningActionType.speedDrill => 15,
      LearningActionType.retest => 20,
      LearningActionType.assess => 15,
    };
    return suggested > remaining ? remaining : suggested;
  }

  String _titleFor(LearningActionType action) => switch (action) {
    LearningActionType.revise => 'Revise the recommended resource',
    LearningActionType.practice => 'Solve a focused DPP',
    LearningActionType.speedDrill => 'Complete a speed drill',
    LearningActionType.retest => 'Retest the weak topic',
    LearningActionType.assess => 'Assess the topic',
  };
}
