import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mark_booster_model.dart';
import '../services/mark_booster_service.dart';
import 'content_providers.dart';
import 'user_providers.dart';
import 'quiz_providers.dart';

// ============= MARK BOOSTER DIAGNOSIS =============
final markBoosterDiagnosisProvider =
    FutureProvider<MarkBoosterDiagnosis>((ref) async {
      final progress = ref.watch(userProgressProvider);
      final allSubjects = ref.watch(subjectsProvider);
      final allQuestions = await ref.watch(allQuestionsProvider.future);
      final errorQuestions = await ref.watch(errorBookProvider.future);

      final weakTopics = <WeakTopicDiagnosis>[];
      final masteredTopics = <MasteredTopic>[];
      for (var subject in allSubjects) {
        for (var chapter in subject.chapters) {
          for (var topic in chapter.topics) {
            final topicProgress = progress.topicProgress[topic.id];
            if (topicProgress == null) continue;
            if (MarkBoosterService.isTopicMastered(
              topicProgress.questionsAttempted,
              topicProgress.accuracy,
            )) {
              masteredTopics.add(
                MasteredTopic(
                  name: topic.name,
                  chapterName: chapter.name,
                  subjectName: subject.name,
                  accuracy: topicProgress.accuracy,
                ),
              );
            } else if (topicProgress.questionsAttempted >= 2 &&
                topicProgress.accuracy < 60) {
              final available = allQuestions
                  .where((q) => q.topicId == topic.id)
                  .length;
              weakTopics.add(
                WeakTopicDiagnosis(
                  topic: topic,
                  subjectName: subject.name,
                  chapterName: chapter.name,
                  questionsAttempted: topicProgress.questionsAttempted,
                  questionsCorrect: topicProgress.questionsCorrect,
                  questionsAvailable: available,
                ),
              );
            }
          }
        }
      }
      weakTopics.sort((a, b) => a.accuracy.compareTo(b.accuracy));

      final typeCounts = <String, int>{};
      final difficultyCounts = <String, int>{};
      for (final q in errorQuestions) {
        final type = q.type.isEmpty ? 'MCQ' : q.type;
        final difficulty = q.difficulty.isEmpty ? 'Medium' : q.difficulty;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
        difficultyCounts[difficulty] = (difficultyCounts[difficulty] ?? 0) + 1;
      }

      final totalErrors = errorQuestions.length;
      final typeWeaknesses = typeCounts.entries
          .map(
            (e) => TypeWeakness(
              type: e.key,
              errorCount: e.value,
              shareOfErrors: totalErrors == 0
                  ? 0
                  : (e.value / totalErrors) * 100,
            ),
          )
          .toList()
        ..sort((a, b) => b.errorCount.compareTo(a.errorCount));

      final difficultyWeaknesses = difficultyCounts.entries
          .map(
            (e) => DifficultyWeakness(
              difficulty: e.key,
              errorCount: e.value,
              shareOfErrors: totalErrors == 0
                  ? 0
                  : (e.value / totalErrors) * 100,
            ),
          )
          .toList()
        ..sort((a, b) => b.errorCount.compareTo(a.errorCount));

      return MarkBoosterDiagnosis(
        weakTopics: weakTopics,
        typeWeaknesses: typeWeaknesses,
        difficultyWeaknesses: difficultyWeaknesses,
        errorBookQuestions: errorQuestions,
        masteredTopics: masteredTopics,
      );
    });
