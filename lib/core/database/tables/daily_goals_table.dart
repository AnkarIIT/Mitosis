import 'package:drift/drift.dart';

class DailyGoals extends Table {
  DateTimeColumn get date => dateTime()(); // YYYY-MM-DD format
  IntColumn get target => integer().withDefault(const Constant(50))(); // questions target
  IntColumn get completed => integer().withDefault(const Constant(0))(); // questions completed
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, in_progress, completed

  @override
  Set<Column> get primaryKey => {date};
}
