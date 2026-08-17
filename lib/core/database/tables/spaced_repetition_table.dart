import 'package:drift/drift.dart';

/// SM-2 / Leitner hybrid scheduling card for a single question.
///
/// The card is created the first time a question is answered incorrectly and
/// is then re-surfaced at growing intervals (1 → 3 → 7 → 21 days, then
/// multiplied by the ease factor, capped at 60). Correct reviews advance the
/// box and grow the interval; incorrect reviews reset to day 1 and bump the
/// lapse count.
class SpacedRepetition extends Table {
  TextColumn get questionId => text()();
  IntColumn get box => integer().withDefault(const Constant(0))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueAt => dateTime()();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().nullable().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {questionId};
}
