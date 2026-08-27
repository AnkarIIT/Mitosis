import 'package:drift/drift.dart';

class QuizAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get topicId => text()();
  TextColumn get subject => text()();
  IntColumn get score => integer()();
  IntColumn get incorrectCount => integer().withDefault(const Constant(0))();
  IntColumn get totalQuestions => integer()();
  IntColumn get timeSpentSeconds => integer()();
  DateTimeColumn get attemptedAt => dateTime()();
  TextColumn get selectedAnswers => text()(); // stored as JSON array string
  TextColumn get testType => text().withDefault(const Constant("topic"))();
  TextColumn get subjectScores => text().nullable()(); // stored as JSON map string
  // Persisted ±marks so history reflects the real scoring scheme instead of
  // re-deriving it with a hardcoded formula. Nullable for pre-v22 rows.
  IntColumn get rawScore => integer().nullable()();
  IntColumn get maxMarks => integer().nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().nullable().clientDefault(() => DateTime.now())();
}
