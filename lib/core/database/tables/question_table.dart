import 'package:drift/drift.dart';

class Questions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get subject => text()();
  TextColumn get chapter => text()();
  TextColumn get topic => text()();
  TextColumn get topicId => text().withDefault(const Constant(""))();
  TextColumn get questionText => text()();
  TextColumn get options => text()(); // stored as "opt1|||opt2|||opt3|||opt4"
  TextColumn get correctAnswer => text()();
  TextColumn get explanation => text().nullable()();
  TextColumn get ncertReference => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get difficulty => text().withDefault(const Constant("Medium"))();
  TextColumn get tags => text().nullable()(); // stored as "tag1|||tag2"
  TextColumn get imageUrl => text().nullable()();
}