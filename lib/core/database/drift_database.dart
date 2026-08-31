import 'package:drift/drift.dart';
import 'connection.dart'
    if (dart.library.js_util) 'connection_web.dart'
    if (dart.library.io) 'connection_native.dart'
    as conn;

import 'tables/question_table.dart';
import 'tables/quiz_attempts_table.dart';
import 'tables/topic_progress_table.dart';
import 'tables/bookmarks_table.dart';
import 'tables/chats_table.dart';
import 'tables/daily_goals_table.dart';
import 'tables/users_table.dart';
import 'tables/error_book_table.dart';
import 'tables/evaluations_table.dart';
import 'tables/sync_watermarks_table.dart';
import 'tables/spaced_repetition_table.dart';
import 'tables/flashcards_table.dart';
import 'tables/dpp_tables.dart';

part 'drift_database.g.dart';

@DriftDatabase(
  tables: [
    Questions,
    QuizAttempts,
    TopicProgressEntries,
    Bookmarks,
    Chats,
    DailyGoals,
    Users,
    ErrorBook,
    Evaluations,
    SyncWatermarks,
    SpacedRepetition,
    Flashcards,
    DppSets,
    DppQuestions,
  ],
)
class AppDatabase extends _$AppDatabase {
  static AppDatabase? _instance;

  factory AppDatabase([QueryExecutor? executor]) {
    if (executor != null) {
      return AppDatabase._internal(executor);
    }

    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  AppDatabase._internal([QueryExecutor? executor])
    : super(executor ?? conn.connect());

  @override
  int get schemaVersion => 28;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Versioned migration logic
      // Note: Drift executes all blocks sequentially if multiple versions are skipped.
      // We use try-catch on specific columns to handle potential desyncs where columns already exist.

      if (from < 2) {
        await m.createTable(quizAttempts);
        await m.createTable(topicProgressEntries);
        await m.createTable(bookmarks);
      }
      if (from < 3) {
        await _addColumnSafely(m, questions, (questions as dynamic).topicId);
        await _addColumnSafely(m, questions, (questions as dynamic).tags);
        await _addColumnSafely(m, questions, (questions as dynamic).imageUrl);
      }
      if (from < 4) {
        await _addColumnSafely(
          m,
          quizAttempts,
          (quizAttempts as dynamic).testType,
        );
        await _addColumnSafely(
          m,
          quizAttempts,
          (quizAttempts as dynamic).subjectScores,
        );
      }
      if (from < 5) {
        await m.createTable(chats);
      }
      if (from < 6) {
        await m.createTable(dailyGoals);
      }
      if (from < 7) {
        await m.createTable(users);
      }
      if (from < 8) {
        await _addColumnSafely(
          m,
          quizAttempts,
          (quizAttempts as dynamic).incorrectCount,
        );
      }
      if (from < 9) {
        await m.createTable(errorBook);
      }
      if (from < 10) {
        await _addColumnSafely(m, questions, (questions as dynamic).type);
      }
      if (from < 11) {
        await _addColumnSafely(m, users, (users as dynamic).currentStreak);
        await _addColumnSafely(m, users, (users as dynamic).lastActivityDate);
      }
      if (from < 12) {
        // Drop and recreate ErrorBook table to change primary key structure if needed
        try {
          await m.deleteTable('error_book');
          await m.createTable(errorBook);
        } catch (_) {}
      }
      if (from < 13) {
        // SQLite does not allow adding a UNIQUE column via ALTER TABLE directly in many versions.
        // We use alterTable with TableMigration which handles recreating the table safely.
        await m.alterTable(TableMigration(users));
      }
      if (from < 14) {
        await _addColumnSafely(m, users, (users as dynamic).isTwoFactorEnabled);
      }
      if (from < 15) {
        await m.createTable(evaluations);
      }
      if (from < 16) {
        // Content-catalog sync columns plus the delta-sync watermark table.
        await _addColumnSafely(m, questions, (questions as dynamic).remoteId);
        await _addColumnSafely(m, questions, (questions as dynamic).updatedAt);
        await _addColumnSafely(m, questions, (questions as dynamic).isActive);
        await m.createTable(syncWatermarks);
      }
      if (from < 17) {
        // Timestamp-first cloud sync: every user-data row carries a local
        // last-modified marker so the sync layer can reconcile Drift writes
        // with Supabase upserts instead of blindly last-writer-wins.
        await _addColumnSafely(
          m,
          quizAttempts,
          (quizAttempts as dynamic).updatedAt,
        );
        await _addColumnSafely(
          m,
          topicProgressEntries,
          (topicProgressEntries as dynamic).updatedAt,
        );
        await _addColumnSafely(m, bookmarks, (bookmarks as dynamic).updatedAt);

        // Bookmarks use `question_id` as their natural sync key. Collapse any
        // pre-existing duplicates (older schema allowed them) before enforcing
        // the unique index so repeated pulls become idempotent.
        await customStatement(
          'DELETE FROM bookmarks WHERE id NOT IN '
          '(SELECT MIN(id) FROM bookmarks GROUP BY question_id)',
        );
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS bookmarks_question_id_unique '
          'ON bookmarks(question_id)',
        );
      }
      if (from < 18) {
        // Spaced-repetition scheduling cards (SM-2 / Leitner hybrid).
        await m.createTable(spacedRepetition);
      }
      if (from < 19) {
        // Batch onboarding triage stored on the user profile.
        await m.addColumn(users, users.batch);
        await m.addColumn(users, users.targetYear);
        await m.addColumn(users, users.dailyCommitmentMinutes);
      }
      if (from < 20) {
        // AI-generated + hand-created flashcards with SM-2 scheduling.
        await m.createTable(flashcards);
      }
      if (from < 21) {
        // Change questionId from int to text in error_book, spaced_repetition, bookmarks.
        // Preserve data by copying to new tables before dropping old ones.
        try {
          await customStatement(
            'CREATE TABLE IF NOT EXISTS error_book_new ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT,'
            'question_id TEXT NOT NULL,'
            'subject TEXT NOT NULL,'
            'topic_id TEXT NOT NULL,'
            'added_at INTEGER NOT NULL,'
            'is_resolved INTEGER NOT NULL DEFAULT 0,'
            'notes TEXT'
            ')',
          );
          await customStatement(
            'INSERT OR IGNORE INTO error_book_new (id, question_id, subject, topic_id, added_at, is_resolved, notes) '
            "SELECT id, CAST(question_id AS TEXT), subject, topic_id, added_at, is_resolved, notes FROM error_book",
          );
          await m.deleteTable('error_book');
          await customStatement(
            'ALTER TABLE error_book_new RENAME TO error_book',
          );
        } catch (_) {}
        try {
          await customStatement(
            'CREATE TABLE IF NOT EXISTS spaced_repetition_new ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT,'
            'question_id TEXT NOT NULL,'
            'subject TEXT NOT NULL,'
            'topic_id TEXT NOT NULL,'
            'box INTEGER NOT NULL DEFAULT 1,'
            'ease_factor REAL NOT NULL DEFAULT 2.5,'
            'interval_days INTEGER NOT NULL DEFAULT 0,'
            'repetitions INTEGER NOT NULL DEFAULT 0,'
            'lapses INTEGER NOT NULL DEFAULT 0,'
            'due_at INTEGER NOT NULL,'
            'last_reviewed_at INTEGER'
            ')',
          );
          await customStatement(
            'INSERT OR IGNORE INTO spaced_repetition_new (id, question_id, subject, topic_id, box, ease_factor, interval_days, repetitions, lapses, due_at, last_reviewed_at) '
            "SELECT id, CAST(question_id AS TEXT), subject, topic_id, box, ease_factor, interval_days, repetitions, lapses, due_at, last_reviewed_at FROM spaced_repetition",
          );
          await m.deleteTable('spaced_repetition');
          await customStatement(
            'ALTER TABLE spaced_repetition_new RENAME TO spaced_repetition',
          );
        } catch (_) {}
        try {
          await customStatement(
            'CREATE TABLE IF NOT EXISTS bookmarks_new ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT,'
            'question_id TEXT NOT NULL,'
            'subject TEXT NOT NULL,'
            'topic_id TEXT NOT NULL,'
            'bookmarked_at INTEGER NOT NULL,'
            'updated_at INTEGER'
            ')',
          );
          await customStatement(
            'INSERT OR IGNORE INTO bookmarks_new (question_id, subject, topic_id, bookmarked_at, updated_at) '
            "SELECT CAST(question_id AS TEXT), subject, topic_id, bookmarked_at, updated_at FROM bookmarks",
          );
          await m.deleteTable('bookmarks');
          await customStatement(
            'ALTER TABLE bookmarks_new RENAME TO bookmarks',
          );
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS bookmarks_question_id_unique '
            'ON bookmarks(question_id)',
          );
        } catch (_) {}
      }
      if (from < 22) {
        // Persist real ±marks on each attempt (single source of truth for the
        // NEET score, instead of re-deriving with a hardcoded 4/−1 formula).
        await _addColumnSafely(
          m,
          quizAttempts,
          (quizAttempts as dynamic).rawScore,
        );
        await _addColumnSafely(
          m,
          quizAttempts,
          (quizAttempts as dynamic).maxMarks,
        );
      }
      if (from < 23) {
        // Track which question IDs were presented per attempt so later
        // sessions can exclude them and avoid repeats across quizzes/mocks.
        await _addColumnSafely(
          m,
          quizAttempts,
          (quizAttempts as dynamic).questionIds,
        );
        // Mark the origin of each question: bundled sample, downloaded PYQ,
        // generated DPP, or user-imported file.
        await _addColumnSafely(m, questions, (questions as dynamic).source);
        // Daily Practice Paper tables.
        await m.createTable(dppSets);
        await m.createTable(dppQuestions);
      }
      if (from < 24) {
        // Persist the shuffle seed for each attempt so the question order
        // can be reproduced in review and diagnostics.
        await _addColumnSafely(m, quizAttempts, (quizAttempts as dynamic).seed);
      }
      if (from < 25) {
        // DPP-specific duration so DPP sets are not forced into the 180-minute
        // NEET mock timer.
        await _addColumnSafely(
          m,
          dppSets,
          (dppSets as dynamic).durationMinutes,
        );
      }
      if (from < 26) {
        // Password reset fields for local auth.
        await _addColumnSafely(m, users, (users as dynamic).passwordResetCode);
        await _addColumnSafely(
          m,
          users,
          (users as dynamic).passwordResetExpiresAt,
        );
      }
      if (from < 27) {
        // Email OTP two-factor authentication fields.
        await _addColumnSafely(m, users, (users as dynamic).twoFactorCode);
        await _addColumnSafely(m, users, (users as dynamic).twoFactorExpiresAt);
      }
      if (from < 28) {
        // Cloud identity linkage: Supabase auth user id (email/password + Google).
        await _addColumnSafely(m, users, (users as dynamic).supabaseId);
      }
    },
    beforeOpen: (details) async {
      // Enable foreign keys
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Safely attempts to add a column, ignoring 'duplicate column' errors.
  /// This handles cases where the user's local DB is in a partial state.
  Future<void> _addColumnSafely(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    try {
      await m.addColumn(table, column);
    } catch (e) {
      if (e.toString().contains('duplicate column name')) {
        // Column already exists, safe to ignore
      } else {
        rethrow;
      }
    }
  }

  // ============= ERROR BOOK =============

  Future<void> addToErrorBook(ErrorBookCompanion entry) =>
      into(errorBook).insertOnConflictUpdate(entry);

  Future<void> removeFromErrorBook(String questionId) =>
      (delete(errorBook)..where((t) => t.questionId.equals(questionId))).go();

  Future<List<ErrorBookData>> getErrorBookEntries() => select(errorBook).get();

  Future<void> resolveErrorBookEntry(String questionId) async {
    await (update(errorBook)..where((t) => t.questionId.equals(questionId)))
        .write(const ErrorBookCompanion(isResolved: Value(true)));
  }

  // ============= USERS =============

  Future<User?> registerUser(UsersCompanion user) async {
    final id = await into(users).insert(user);
    return getUserById(id);
  }

  Future<User?> getUserByEmail(String email) =>
      (select(users)..where((t) => t.email.equals(email))).getSingleOrNull();

  Future<User?> getUserByPhone(String phone) =>
      (select(users)..where((t) => t.phone.equals(phone))).getSingleOrNull();

  Future<User?> getUserById(int id) =>
      (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateLastLogin(int userId) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(lastLogin: Value(DateTime.now())),
    );
  }

  Future<void> setSupabaseId(int userId, String supabaseId) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(supabaseId: Value(supabaseId)),
    );
  }

  Future<void> verifyUserEmail(int userId) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      const UsersCompanion(isEmailVerified: Value(true)),
    );
  }

  Future<void> verifyUserPhone(int userId) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      const UsersCompanion(isPhoneVerified: Value(true)),
    );
  }

  Future<void> updateTwoFactorStatus(int userId, bool enabled) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(isTwoFactorEnabled: Value(enabled)),
    );
  }

  Future<void> setTwoFactorCode(
    int userId,
    String code,
    DateTime expiresAt,
  ) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        twoFactorCode: Value(code),
        twoFactorExpiresAt: Value(expiresAt),
      ),
    );
  }

  Future<void> clearTwoFactorCode(int userId) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      const UsersCompanion(
        twoFactorCode: Value(null),
        twoFactorExpiresAt: Value(null),
      ),
    );
  }

  Future<({int userId, String code, DateTime expiresAt})?>
  getActiveTwoFactorCode(int userId) async {
    final row = await (select(
      users,
    )..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (row == null ||
        row.twoFactorCode == null ||
        row.twoFactorExpiresAt == null) {
      return null;
    }
    if (row.twoFactorExpiresAt!.isBefore(DateTime.now())) {
      return null;
    }
    return (
      userId: row.id,
      code: row.twoFactorCode!,
      expiresAt: row.twoFactorExpiresAt!,
    );
  }

  Future<void> updateUserPreferences(
    int userId, {
    String? batch,
    int? targetYear,
    int? dailyCommitmentMinutes,
  }) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        batch: Value(batch),
        targetYear: Value(targetYear),
        dailyCommitmentMinutes: Value(dailyCommitmentMinutes),
      ),
    );
  }

  Future<void> updateUserPassword(int userId, String passwordHash) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(passwordHash: Value(passwordHash)),
    );
  }

  Future<void> updateUserPasswordReset(
    int userId,
    String code,
    DateTime expiresAt,
  ) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        passwordResetCode: Value(code),
        passwordResetExpiresAt: Value(expiresAt),
      ),
    );
  }

  Future<({int userId, String code, DateTime expiresAt})?>
  getActivePasswordReset(int userId) async {
    final row = await (select(
      users,
    )..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (row == null ||
        row.passwordResetCode == null ||
        row.passwordResetExpiresAt == null) {
      return null;
    }
    if (row.passwordResetExpiresAt!.isBefore(DateTime.now())) {
      return null;
    }
    return (
      userId: row.id,
      code: row.passwordResetCode!,
      expiresAt: row.passwordResetExpiresAt!,
    );
  }

  Future<void> clearPasswordReset(int userId) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      const UsersCompanion(
        passwordResetCode: Value(null),
        passwordResetExpiresAt: Value(null),
      ),
    );
  }

  Future<void> clearUserData(int userId) async {
    await (delete(users)..where((t) => t.id.equals(userId))).go();
  }

  // ============= DAILY GOALS =============

  Future<void> upsertDailyGoal(DailyGoalsCompanion goal) =>
      into(dailyGoals).insertOnConflictUpdate(goal);

  Future<DailyGoal?> getDailyGoal(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return (select(
      dailyGoals,
    )..where((t) => t.date.equals(dateOnly))).getSingleOrNull();
  }

  Future<List<DailyGoal>> getDailyGoalsRange(DateTime from, DateTime to) =>
      (select(dailyGoals)
            ..where((t) => t.date.isBetween(Variable(from), Variable(to)))
            ..orderBy([
              (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            ]))
          .get();

  // ============= CHATS =============

  Future<void> insertChatMessage(ChatsCompanion message) =>
      into(chats).insert(message);

  Future<List<Chat>> getAllChats() => (select(
    chats,
  )..orderBy([(t) => OrderingTerm(expression: t.timestamp)])).get();

  Future<void> clearChatHistory() => delete(chats).go();

  // ============= QUIZ ATTEMPTS =============

  Future<int> insertQuizAttempt(Insertable<QuizAttempt> attempt) =>
      into(quizAttempts).insert(attempt);

  Future<void> upsertQuizAttempt(QuizAttemptsCompanion attempt) async {
    final attemptedAt = attempt.attemptedAt.value;

    // An older schema could produce multiple local rows sharing an
    // `attempted_at`. Updating every match (instead of `getSingleOrNull`,
    // which would throw) keeps the pull loop crash-free.
    final existing = await (select(
      quizAttempts,
    )..where((t) => t.attemptedAt.equals(attemptedAt))).get();

    if (existing.isEmpty) {
      await into(quizAttempts).insert(attempt);
      return;
    }

    for (final row in existing) {
      await (update(
        quizAttempts,
      )..where((t) => t.id.equals(row.id))).write(attempt);
    }
  }

  Future<List<QuizAttempt>> getAllQuizAttempts() => select(quizAttempts).get();

  Future<List<QuizAttempt>> getQuizAttemptsBySubject(String subjectName) =>
      (select(quizAttempts)..where((t) => t.subject.equals(subjectName))).get();

  // ============= TOPIC PROGRESS =============

  Future<void> upsertTopicProgress(Insertable<TopicProgressEntry> entry) =>
      into(topicProgressEntries).insertOnConflictUpdate(entry);

  Future<List<TopicProgressEntry>> getAllTopicProgress() =>
      select(topicProgressEntries).get();

  Future<TopicProgressEntry?> getTopicProgress(String topicId) => (select(
    topicProgressEntries,
  )..where((t) => t.topicId.equals(topicId))).getSingleOrNull();

  // ============= BOOKMARKS =============

  /// Upserts by the `question_id` unique index so repeated cloud pulls never
  /// duplicate a bookmark.
  Future<void> insertBookmark(BookmarksCompanion bookmark) =>
      into(bookmarks).insert(
        bookmark,
        onConflict: DoUpdate((_) => bookmark, target: [bookmarks.questionId]),
      );

  Future<void> removeBookmark(String questionId) =>
      (delete(bookmarks)..where((t) => t.questionId.equals(questionId))).go();

  Future<List<Bookmark>> getAllBookmarks() => select(bookmarks).get();

  Future<bool> isBookmarked(String questionId) async {
    final result = await (select(
      bookmarks,
    )..where((t) => t.questionId.equals(questionId))).get();
    return result.isNotEmpty;
  }

  // ============= CONTENT SYNC WATERMARKS =============

  Future<DateTime?> getLastSyncTimestamp(String tableName) async {
    final row = await (select(
      syncWatermarks,
    )..where((t) => t.remoteTable.equals(tableName))).getSingleOrNull();
    return row?.lastSyncedAt;
  }

  Future<void> setSyncTimestamp(String tableName, DateTime timestamp) =>
      into(syncWatermarks).insertOnConflictUpdate(
        SyncWatermarksCompanion.insert(
          remoteTable: tableName,
          lastSyncedAt: timestamp,
        ),
      );

  /// Local ids of every remote-sourced (catalog) question, used to reconcile
  /// rows that were removed/deactivated on the server.
  Future<List<String>> getRemoteQuestionLocalIds() async {
    final rows = await (select(
      questions,
    )..where((t) => t.remoteId.isNotNull())).get();
    return rows.map((r) => r.id).toList();
  }

  // ============= SPACED REPETITION =============

  Future<void> upsertSpacedRepetition(Insertable<SpacedRepetitionData> entry) =>
      into(spacedRepetition).insertOnConflictUpdate(entry);

  Future<List<SpacedRepetitionData>> getSpacedRepetitionCards() =>
      select(spacedRepetition).get();

  Future<SpacedRepetitionData?> getSpacedRepetition(String questionId) =>
      (select(
        spacedRepetition,
      )..where((t) => t.questionId.equals(questionId))).getSingleOrNull();

  Future<List<SpacedRepetitionData>> getDueSpacedRepetition(DateTime now) {
    final query = select(spacedRepetition)
      ..where((t) => t.dueAt.isSmallerOrEqualValue(now))
      ..orderBy([(t) => OrderingTerm(expression: t.dueAt)]);
    return query.get();
  }

  Future<void> removeSpacedRepetition(String questionId) => (delete(
    spacedRepetition,
  )..where((t) => t.questionId.equals(questionId))).go();

  // ============= FLASHCARDS =============

  Future<void> insertFlashcard(FlashcardsCompanion card) =>
      into(flashcards).insert(card, mode: InsertMode.insertOrReplace);

  Future<void> insertFlashcardsBatch(List<FlashcardsCompanion> cards) async {
    await batch(
      (b) => b.insertAll(flashcards, cards, mode: InsertMode.insertOrReplace),
    );
  }

  Future<List<Flashcard>> getAllFlashcards() => select(flashcards).get();

  Future<List<Flashcard>> getFlashcardsBySubject(String subject) =>
      (select(flashcards)..where((t) => t.subject.equals(subject))).get();

  Future<List<Flashcard>> getDueFlashcards(DateTime now) {
    final query = select(flashcards)
      ..where((t) => t.dueAt.isSmallerOrEqualValue(now))
      ..orderBy([(t) => OrderingTerm(expression: t.dueAt)]);
    return query.get();
  }

  Future<Flashcard?> getFlashcardById(String id) =>
      (select(flashcards)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateFlashcardSchedule(
    String id, {
    required int box,
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required int lapses,
    required DateTime dueAt,
    DateTime? lastReviewedAt,
  }) async {
    await (update(flashcards)..where((t) => t.id.equals(id))).write(
      FlashcardsCompanion(
        box: Value(box),
        easeFactor: Value(easeFactor),
        intervalDays: Value(intervalDays),
        repetitions: Value(repetitions),
        lapses: Value(lapses),
        dueAt: Value(dueAt),
        lastReviewedAt: Value(lastReviewedAt),
      ),
    );
  }

  Future<void> deleteFlashcard(String id) =>
      (delete(flashcards)..where((t) => t.id.equals(id))).go();

  Future<void> deleteFlashcardsByChapter(String chapterId) =>
      (delete(flashcards)..where((t) => t.chapterId.equals(chapterId))).go();

  // ============= QUIZ ATTEMPT QUESTION IDS =============

  Future<List> getRecentQuizAttempts(int maxAttempts) async {
    final query = select(quizAttempts)
      ..orderBy([
        (t) => OrderingTerm(expression: t.attemptedAt, mode: OrderingMode.desc),
      ])
      ..limit(maxAttempts);
    return query.get();
  }

  Future<void> updateQuizAttemptQuestionIds(
    int attemptId,
    String questionIdsJson,
  ) async {
    await (update(quizAttempts)..where((t) => t.id.equals(attemptId))).write(
      QuizAttemptsCompanion(questionIds: Value(questionIdsJson)),
    );
  }

  // ============= DPP SETS =============

  Future<List> getDppSets() => select(dppSets).get();

  Future getTodayDppSet(String subject) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final query = select(dppSets)
      ..where((t) => t.date.equals(dateStr) & t.subject.equals(subject));
    return query.getSingleOrNull();
  }

  Future<int> insertDppSet(DppSetsCompanion dppSet) =>
      into(dppSets).insert(dppSet);

  Future<void> updateDppSet(DppSet dppSet) async {
    await update(dppSets).replace(dppSet);
  }

  Future<List> getDppQuestions(int dppSetId) async {
    final query = select(dppQuestions)
      ..where((t) => t.dppSetId.equals(dppSetId));
    return query.get();
  }

  Future<void> insertDppQuestions(List questions) async {
    await batch((batch) {
      batch.insertAll(dppQuestions, questions as Iterable<Insertable>);
    });
  }

  // ============= RESET DATA =============

  Future<void> clearAllProgress() async {
    await transaction(() async {
      await delete(quizAttempts).go();
      await delete(topicProgressEntries).go();
      await delete(bookmarks).go();
      await delete(dailyGoals).go();
      await delete(spacedRepetition).go();
      await delete(errorBook).go();
      await delete(flashcards).go();
      await delete(dppSets).go();
      await delete(dppQuestions).go();
    });
  }
}
