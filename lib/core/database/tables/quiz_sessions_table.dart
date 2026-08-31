import 'package:drift/drift.dart';

class QuizSessions extends Table {
  /// Unique session ID (UUID-like string)
  TextColumn get sessionId => text()();

  /// Topic ID this quiz is for
  TextColumn get topicId => text()();

  /// Subject name
  TextColumn get subject => text()();

  /// Test type: 'topic', 'mock', 'practice', 'revision', 'speed'
  TextColumn get testType => text().withDefault(const Constant('topic'))();

  /// Quiz mode: 'practice', 'exam', 'revision', 'speed'
  TextColumn get quizMode => text().withDefault(const Constant('practice'))();

  /// Total time limit in seconds (0 = no limit)
  IntColumn get timeLimitSeconds => integer().withDefault(const Constant(0))();

  /// Seed used for question randomization
  IntColumn get seed => integer()();

  /// Current question index
  IntColumn get currentIndex => integer().withDefault(const Constant(0))();

  /// Selected answers as JSON map: {questionIndex: answer}
  TextColumn get selectedAnswers => text()();

  /// Answer results as JSON map: {questionIndex: true/false}
  TextColumn get answerResults => text()();

  /// Time spent per question as JSON map: {questionIndex: seconds}
  TextColumn get timeSpentPerQuestion => text()();

  /// Flagged question indices as JSON array
  TextColumn get flaggedQuestions => text()();

  /// Visited question indices as JSON array
  TextColumn get visitedQuestions => text()();

  /// Current score
  IntColumn get score => integer().withDefault(const Constant(0))();

  /// Incorrect count
  IntColumn get incorrectCount => integer().withDefault(const Constant(0))();

  /// Elapsed time in seconds
  IntColumn get elapsedSeconds => integer().withDefault(const Constant(0))();

  /// Whether quiz is completed
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Question IDs in order as JSON array
  TextColumn get questionIds => text()();

  /// Question data (full questions) as JSON array for offline restore
  TextColumn get questionData => text().nullable()();

  /// Created timestamp
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();

  /// Last updated timestamp
  DateTimeColumn get updatedAt =>
      dateTime().nullable().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {sessionId};
}