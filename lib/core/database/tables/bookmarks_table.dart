import 'package:drift/drift.dart';

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer()();
  TextColumn get subject => text()();
  TextColumn get topicId => text()();
  DateTimeColumn get bookmarkedAt => dateTime()();
}
