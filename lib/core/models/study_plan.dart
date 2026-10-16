import 'learning_recommendation.dart';

class StudyPlanItem {
  final String topicId;
  final LearningActionType action;
  final int minutes;
  final String title;
  final String rationale;

  const StudyPlanItem({
    required this.topicId,
    required this.action,
    required this.minutes,
    required this.title,
    required this.rationale,
  });
}

class DailyStudyPlan {
  final DateTime date;
  final int totalMinutes;
  final List<StudyPlanItem> items;

  const DailyStudyPlan({
    required this.date,
    required this.totalMinutes,
    required this.items,
  });
}
