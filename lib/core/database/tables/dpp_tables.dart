import 'package:drift/drift.dart';

class DppSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()(); // YYYY-MM-DD
  TextColumn get subject => text()();
  TextColumn get chapterId => text().nullable()();
  TextColumn get topicId => text().nullable()();
  IntColumn get totalQuestions => integer()();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get incorrectCount => integer().withDefault(const Constant(0))();
  IntColumn get unattemptedCount => integer().withDefault(const Constant(0))();
  IntColumn get timeSpentSeconds => integer().withDefault(const Constant(0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().nullable().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().nullable().clientDefault(() => DateTime.now())();
}

class DppQuestions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dppSetId => integer().nullable()();
  TextColumn get questionId => text()();
  TextColumn get subject => text()();
  TextColumn get chapter => text()();
  TextColumn get topic => text()();
  TextColumn get topicId => text()();
  TextColumn get difficulty => text()();
  TextColumn get questionText => text()();
  TextColumn get options => text()(); // JSON array
  TextColumn get correctAnswer => text()();
  TextColumn get explanation => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get source => text().withDefault(const Constant('dpp'))(); // 'pyq' | 'dpp' | 'seeded'
}
