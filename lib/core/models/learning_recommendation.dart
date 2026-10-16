enum LearningActionType { assess, revise, practice, speedDrill, retest }

class LearningRecommendation {
  final String topicId;
  final String topicName;
  final String subject;
  final String chapterId;
  final double mastery;
  final String diagnosis;
  final LearningActionType primaryAction;
  final List<LearningActionType> actions;

  const LearningRecommendation({
    required this.topicId,
    required this.topicName,
    required this.subject,
    required this.chapterId,
    required this.mastery,
    required this.diagnosis,
    required this.primaryAction,
    required this.actions,
  });
}
