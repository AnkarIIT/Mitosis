import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()(); // Store hashed password, not plain
  TextColumn get fullName => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get lastLogin => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
