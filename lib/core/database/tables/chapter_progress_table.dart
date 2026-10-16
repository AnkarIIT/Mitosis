import 'package:drift/drift.dart';

/// Tracks user progress through a chapter.
///
/// Each row represents a user's progress through a specific chapter.
class ChapterProgressTable extends Table {
  /// The chapter ID (references Chapter.id).
  TextColumn get chapterId => text()();

  /// The user ID (references Users.id).
  IntColumn get userId => integer()();

  /// The current lesson the user is on.
  TextColumn get currentLessonId => text().withDefault(const Constant(''))();

  /// JSON array of completed lesson IDs.
  TextColumn get completedLessonIds =>
      text().withDefault(const Constant('[]'))();

  /// JSON map of lessonId -> quick check score (0-100).
  TextColumn get quickCheckScores => text().withDefault(const Constant('{}'))();

  /// Summary quiz score (0-100), -1 if not taken.
  IntColumn get summaryQuizScore => integer().withDefault(const Constant(-1))();

  /// When the user first started this chapter.
  DateTimeColumn get startedAt => dateTime()();

  /// Last time the user accessed this chapter.
  DateTimeColumn get lastAccessedAt => dateTime()();

  /// When the chapter was completed (null if not completed).
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {chapterId, userId};
}
