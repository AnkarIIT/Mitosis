import 'package:drift/drift.dart';

class MistakeEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().withDefault(const Constant(-1))();
  IntColumn get attemptId => integer().nullable()();
  TextColumn get questionId => text()();
  TextColumn get topicId => text()();
  TextColumn get mistakeType => text()();
  RealColumn get timeSeconds => real()();
  DateTimeColumn get createdAt => dateTime()();
}

class RetentionReviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().withDefault(const Constant(-1))();
  TextColumn get topicId => text()();
  IntColumn get intervalDays => integer()();
  DateTimeColumn get dueAt => dateTime()();
  DateTimeColumn get checkedAt => dateTime()();
  RealColumn get accuracy => real().nullable()();
}
