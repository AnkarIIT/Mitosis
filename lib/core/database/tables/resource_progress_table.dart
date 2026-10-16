import 'package:drift/drift.dart';

/// User-scoped reading state for shared study resources.
@TableIndex(
  name: 'resource_progress_user_resource_unique',
  columns: {#userId, #resourceId},
  unique: true,
)
class ResourceProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  TextColumn get resourceId => text()();
  TextColumn get chapterId => text().nullable()();
  IntColumn get lastPage => integer().nullable()();
  IntColumn get progressPercent => integer().withDefault(const Constant(0))();
  BoolColumn get isBookmarked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();
}
