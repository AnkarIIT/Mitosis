import 'package:drift/drift.dart';

class QuizAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get topicId => text()();
  TextColumn get subject => text()();
  IntColumn get score => integer()();
  IntColumn get totalQuestions => integer()();
  IntColumn get timeSpentSeconds => integer()();
  DateTimeColumn get attemptedAt => dateTime()();
  TextColumn get selectedAnswers => text()(); // stored as JSON array string
  TextColumn get testType => text().withDefault(const Constant("topic"))();
  TextColumn get subjectScores => text().nullable()(); // stored as JSON map string
}
