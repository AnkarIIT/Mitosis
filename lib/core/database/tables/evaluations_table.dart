import 'package:drift/drift.dart';

class Evaluations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionId => text()();
  TextColumn get studentAnswer => text()();
  RealColumn get score => real()();
  RealColumn get semanticSimilarity => real()();
  RealColumn get keywordMatch => real()();
  BoolColumn get isCorrect => boolean()();
  TextColumn get feedback => text().nullable()();
  TextColumn get missingKeywords => text().nullable()();
  DateTimeColumn get evaluatedAt => dateTime()();
}
