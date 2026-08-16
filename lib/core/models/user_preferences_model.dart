import 'subject_model.dart';

/// The NEET aspirant cohort chosen during batch onboarding.
enum NeetBatch {
  class11('Class 11'),
  class12('Class 12'),
  dropper('Dropper');

  const NeetBatch(this.displayName);

  final String displayName;

  static NeetBatch? fromStored(String? value) {
    for (final batch in values) {
      if (batch.displayName == value) return batch;
    }
    return null;
  }
}

/// Batch-aware onboarding choices plus the computed fields built on top of
/// them (syllabus coverage, recommended daily target).
class UserPreferences {
  const UserPreferences({
    this.batch,
    this.targetYear,
    this.dailyCommitmentMinutes,
    this.isOnboarded = false,
  });

  /// One of `NeetBatch.displayName`, or null when unset (treated as Dropper).
  final String? batch;
  final int? targetYear;
  final int? dailyCommitmentMinutes;

  /// True once the batch triage has been completed (or explicitly skipped).
  final bool isOnboarded;

  bool get hasBatch => batch != null;

  NeetBatch? get batchValue => NeetBatch.fromStored(batch);

  /// Whether the given chapter's syllabus applies to this user. A null batch
  /// (never triaged) or Dropper covers the full NEET syllabus.
  bool includesChapter(String? chapterClassLevel) {
    if (batch == null || batch == NeetBatch.dropper.displayName) return true;
    return chapterClassLevel == batch;
  }

  /// Filters topics to those whose chapter belongs to the user's syllabus.
  static List<Topic> filterTopicsByBatch(
    List<Topic> topics, {
    required String? batch,
    required List<Subject> subjects,
  }) {
    if (batch == null || batch == NeetBatch.dropper.displayName) {
      return topics;
    }
    final chapterLevel = <String, String?>{};
    for (final subject in subjects) {
      for (final chapter in subject.chapters) {
        chapterLevel[chapter.id] = chapter.classLevel;
      }
    }
    return topics
        .where((topic) => chapterLevel[topic.chapterId] == batch)
        .toList();
  }

  /// Maps the daily commitment choice to a sensible question-count goal.
  int get recommendedDailyTarget {
    final minutes = dailyCommitmentMinutes ?? 60;
    if (minutes <= 30) return 25;
    if (minutes <= 60) return 50;
    if (minutes <= 90) return 75;
    return 100;
  }

  UserPreferences copyWith({
    String? batch,
    int? targetYear,
    int? dailyCommitmentMinutes,
    bool? isOnboarded,
  }) {
    return UserPreferences(
      batch: batch ?? this.batch,
      targetYear: targetYear ?? this.targetYear,
      dailyCommitmentMinutes: dailyCommitmentMinutes ?? this.dailyCommitmentMinutes,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }
}
