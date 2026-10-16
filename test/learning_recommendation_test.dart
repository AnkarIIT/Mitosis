import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/constants/neet_sample_data.dart';
import 'package:neet_mitos/core/models/user_progress_model.dart';
import 'package:neet_mitos/core/services/learning_recommendation_service.dart';

void main() {
  const service = LearningRecommendationService();

  test('unassessed topics receive an assessment recommendation', () {
    final result = service.build(
      subjects: subjects,
      progress: const {},
      attempts: const [],
      limit: 1,
    );

    expect(result, hasLength(1));
    expect(result.first.diagnosis, 'Not assessed yet');
    expect(result.first.primaryAction.name, 'assess');
  });

  test('low accuracy topics receive revision before retest', () {
    final topic = subjects.first.chapters.first.topics.first;
    final result = service.build(
      subjects: subjects,
      progress: {
        topic.id: TopicProgress(
          topicId: topic.id,
          questionsAttempted: 10,
          questionsCorrect: 3,
          averageTimeSeconds: 40,
          lastAttempted: DateTime(2026),
        ),
      },
      attempts: const [],
      limit: 1,
    );

    final recommendation = result.firstWhere(
      (item) => item.topicId == topic.id,
    );
    expect(recommendation.topicId, topic.id);
    expect(recommendation.primaryAction.name, 'revise');
    expect(
      recommendation.actions.map((action) => action.name),
      contains('retest'),
    );
  });

  test('slow but accurate topics receive a speed drill', () {
    final topic = subjects.first.chapters.first.topics.first;
    final result = service.build(
      subjects: subjects,
      progress: {
        topic.id: TopicProgress(
          topicId: topic.id,
          questionsAttempted: 20,
          questionsCorrect: 16,
          averageTimeSeconds: 90,
          lastAttempted: DateTime(2026),
        ),
      },
      attempts: const [],
      limit: 1,
    );

    final recommendation = result.firstWhere(
      (item) => item.topicId == topic.id,
    );
    expect(recommendation.primaryAction.name, 'speedDrill');
  });
}
