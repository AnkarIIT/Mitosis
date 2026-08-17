import 'package:drift/drift.dart';

/// Persistent flashcard with SM-2 scheduling fields.
///
/// Cards are either hand-created by the user or AI-generated from NCERT
/// chapters. The scheduling fields follow the same SM-2 / Leitner hybrid
/// algorithm used by [SpacedRepetition] for MCQ questions.
class Flashcards extends Table {
  TextColumn get id => text()();
  TextColumn get front => text()();
  TextColumn get back => text()();
  TextColumn get subject => text()();
  TextColumn get topicId => text().withDefault(const Constant(''))();
  TextColumn get imageUrl => text().nullable()();

  // NCERT provenance
  TextColumn get chapterId => text().withDefault(const Constant(''))();
  TextColumn get ncertReference => text().withDefault(const Constant(''))();
  IntColumn get sourcePage => integer().withDefault(const Constant(0))();
  TextColumn get difficulty => text().withDefault(const Constant('Medium'))();
  BoolColumn get isGenerated => boolean().withDefault(const Constant(false))();

  // SM-2 / Leitner scheduling
  IntColumn get box => integer().withDefault(const Constant(0))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueAt => dateTime()();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().nullable().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}
