import 'package:drift/drift.dart';

class TopicProgressEntries extends Table {
  TextColumn get topicId => text()();
  IntColumn get questionsAttempted => integer().withDefault(const Constant(0))();
  IntColumn get questionsCorrect => integer().withDefault(const Constant(0))();
  IntColumn get timeSpentSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttempted => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {topicId};
}
