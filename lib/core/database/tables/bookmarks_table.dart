import 'package:drift/drift.dart';

/// One bookmark per question. The unique index on [questionId] keeps local
/// rows idempotent across repeated cloud pulls, and is the natural key used
/// by the timestamp-first sync reconciliation.
@TableIndex(
  name: 'bookmarks_question_id_unique',
  columns: {#questionId},
  unique: true,
)
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionId => text()();
  TextColumn get subject => text()();
  TextColumn get topicId => text()();
  DateTimeColumn get bookmarkedAt => dateTime()();
  DateTimeColumn get updatedAt =>
      dateTime().nullable().clientDefault(() => DateTime.now())();
}
