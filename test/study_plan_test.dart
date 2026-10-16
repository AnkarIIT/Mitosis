import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/learning_recommendation.dart';
import 'package:neet_mitos/core/services/study_plan_service.dart';

void main() {
  test('study plan stays within the learner commitment budget', () {
    const service = StudyPlanService();
    final plan = service.build(
      commitmentMinutes: 40,
      recommendations: [
        LearningRecommendation(
          topicId: 'kinematics',
          topicName: 'Kinematics',
          subject: 'Physics',
          chapterId: 'motion',
          mastery: 40,
          diagnosis: 'Low accuracy',
          primaryAction: LearningActionType.revise,
          actions: [LearningActionType.revise],
        ),
        LearningRecommendation(
          topicId: 'kinematics',
          topicName: 'Kinematics',
          subject: 'Physics',
          chapterId: 'motion',
          mastery: 40,
          diagnosis: 'Verify improvement',
          primaryAction: LearningActionType.retest,
          actions: [LearningActionType.retest],
        ),
      ],
    );

    expect(plan.totalMinutes, 40);
    expect(plan.items.map((item) => item.minutes), [20, 20]);
  });
}
