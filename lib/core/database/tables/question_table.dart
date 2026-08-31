import 'package:drift/drift.dart';

class Questions extends Table {
  TextColumn get id => text()();
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
  TextColumn get type => text().withDefault(const Constant("MCQ"))();

  /// Supabase content-catalog UUID for remote-sourced questions.
  /// Null for the bundled sample bank.
  TextColumn get remoteId => text().nullable()();

  /// Last server-modified timestamp (delta sync watermark source).
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// False once a catalog question is removed/deactivated on the server.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Origin of the question: 'seeded', 'pyq', 'dpp', 'imported'.
  TextColumn get source => text().withDefault(const Constant('seeded'))();
}
