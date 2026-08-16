import 'question_model.dart';
import 'subject_model.dart';

/// A topic the user has driven to mastery (accuracy >= 60%).
class MasteredTopic {
  final String name;
  final String chapterName;
  final String subjectName;
  final double accuracy;

  MasteredTopic({
    required this.name,
    required this.chapterName,
    required this.subjectName,
    required this.accuracy,
  });
}

/// A topic where the user's accuracy is below the mastery threshold.
class WeakTopicDiagnosis {
  final Topic topic;
  final String subjectName;
  final String chapterName;
  final int questionsAttempted;
  final int questionsCorrect;
  final int questionsAvailable;

  WeakTopicDiagnosis({
    required this.topic,
    required this.subjectName,
    required this.chapterName,
    required this.questionsAttempted,
    required this.questionsCorrect,
    required this.questionsAvailable,
  });

  double get accuracy =>
      questionsAttempted == 0 ? 0 : (questionsCorrect / questionsAttempted) * 100;

  /// Progress (0.0–1.0) toward the mastery threshold.
  double get masteryProgress {
    const threshold = 60.0;
    return (accuracy / threshold).clamp(0.0, 1.0);
  }
}

/// Share of the user's errors falling in a given question type.
class TypeWeakness {
  final String type;
  final int errorCount;
  final double shareOfErrors;

  TypeWeakness({
    required this.type,
    required this.errorCount,
    required this.shareOfErrors,
  });
}

/// Share of the user's errors falling in a given difficulty band.
class DifficultyWeakness {
  final String difficulty;
  final int errorCount;
  final double shareOfErrors;

  DifficultyWeakness({
    required this.difficulty,
    required this.errorCount,
    required this.shareOfErrors,
  });
}

/// Full diagnostic snapshot that drives the Mark Booster.
class MarkBoosterDiagnosis {
  final List<WeakTopicDiagnosis> weakTopics;
  final List<TypeWeakness> typeWeaknesses;
  final List<DifficultyWeakness> difficultyWeaknesses;
  final List<Question> errorBookQuestions;
  final List<MasteredTopic> masteredTopics;

  MarkBoosterDiagnosis({
    required this.weakTopics,
    required this.typeWeaknesses,
    required this.difficultyWeaknesses,
    required this.errorBookQuestions,
    this.masteredTopics = const [],
  });

  int get errorBookCount => errorBookQuestions.length;

  int get masteredTopicCount => masteredTopics.length;

  bool get hasWeaknesses =>
      weakTopics.isNotEmpty ||
      typeWeaknesses.isNotEmpty ||
      difficultyWeaknesses.isNotEmpty ||
      errorBookQuestions.isNotEmpty;
}
