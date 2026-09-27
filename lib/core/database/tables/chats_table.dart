import 'package:drift/drift.dart';

class Chats extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().withDefault(const Constant(0))();
  TextColumn get message => text()();
  BoolColumn get isUser => boolean()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get sessionId => text().nullable()(); // To group conversations
}
