import 'package:drift/drift.dart';

class ErrorBook extends Table {
  TextColumn get questionId => text()();
  DateTimeColumn get addedAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {questionId};
}
