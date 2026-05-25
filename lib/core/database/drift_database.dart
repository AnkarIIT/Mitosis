import 'package:drift/drift.dart';
import 'connection.dart'
    if (dart.library.js_util) 'connection_web.dart'
    if (dart.library.io) 'connection_native.dart' as conn;

import 'tables/question_table.dart';
import 'tables/quiz_attempts_table.dart';
import 'tables/topic_progress_table.dart';
import 'tables/bookmarks_table.dart';
import 'tables/chats_table.dart';

part 'drift_database.g.dart';

@DriftDatabase(tables: [Questions, QuizAttempts, TopicProgressEntries, Bookmarks, Chats])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(conn.connect());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(quizAttempts);
        await m.createTable(topicProgressEntries);
        await m.createTable(bookmarks);
      }
      if (from < 3) {
        await m.addColumn(questions, questions.topicId);
        await m.addColumn(questions, questions.tags);
        await m.addColumn(questions, questions.imageUrl);
      }
      if (from < 4) {
        await m.addColumn(quizAttempts, quizAttempts.testType);
        await m.addColumn(quizAttempts, quizAttempts.subjectScores);
      }
      if (from < 5) {
        await m.createTable(chats);
      }
    },
  );

  // ============= CHATS =============

  Future<void> insertChatMessage(ChatsCompanion message) =>
      into(chats).insert(message);

  Future<List<Chat>> getAllChats() =>
      (select(chats)..orderBy([(t) => OrderingTerm(expression: t.timestamp)])).get();

  Future<void> clearChatHistory() => delete(chats).go();

  // ============= QUIZ ATTEMPTS =============

  Future<void> insertQuizAttempt(Insertable<QuizAttempt> attempt) =>
      into(quizAttempts).insert(attempt);

  Future<List<QuizAttempt>> getAllQuizAttempts() =>
      select(quizAttempts).get();

  Future<List<QuizAttempt>> getQuizAttemptsBySubject(String subjectName) =>
      (select(quizAttempts)..where((t) => t.subject.equals(subjectName))).get();

  // ============= TOPIC PROGRESS =============

  Future<void> upsertTopicProgress(Insertable<TopicProgressEntry> entry) =>
      into(topicProgressEntries).insertOnConflictUpdate(entry);

  Future<List<TopicProgressEntry>> getAllTopicProgress() =>
      select(topicProgressEntries).get();

  Future<TopicProgressEntry?> getTopicProgress(String topicId) =>
      (select(topicProgressEntries)..where((t) => t.topicId.equals(topicId)))
          .getSingleOrNull();

  // ============= BOOKMARKS =============

  Future<void> insertBookmark(BookmarksCompanion bookmark) =>
      into(bookmarks).insert(bookmark);

  Future<void> removeBookmark(int questionId) =>
      (delete(bookmarks)..where((t) => t.questionId.equals(questionId))).go();

  Future<List<Bookmark>> getAllBookmarks() =>
      select(bookmarks).get();

  Future<bool> isBookmarked(int questionId) async {
    final result = await (select(bookmarks)
          ..where((t) => t.questionId.equals(questionId)))
        .get();
    return result.isNotEmpty;
  }
}