import 'package:drift/drift.dart';

/// One bookmark per question per local owner.
@TableIndex(
  name: 'bookmarks_user_question_unique',
  columns: {#userId, #questionId},
  unique: true,
)
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  TextColumn get questionId => text()();
  TextColumn get subject => text()();
  TextColumn get topicId => text()();
  DateTimeColumn get bookmarkedAt => dateTime()();
  DateTimeColumn get updatedAt =>
      dateTime().nullable().clientDefault(() => DateTime.now())();
}
