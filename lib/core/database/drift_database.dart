import 'package:drift/drift.dart';
import 'connection.dart'
    if (dart.library.js_util) 'connection_web.dart'
    if (dart.library.io) 'connection_native.dart'
    as conn;
import '../utils/security_utils.dart';

import 'tables/question_table.dart';
import 'tables/quiz_attempts_table.dart';
import 'tables/quiz_sessions_table.dart';
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
    QuizSessions,
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
  int get schemaVersion => 32;

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
      if (from < 29) {
        // Quiz sessions table for session persistence (save/resume in-progress quizzes)
        await m.createTable(quizSessions);
      }
      if (from < 30) {
        // Add primary key to Questions table (SQLite requires table recreation)
        try {
          await customStatement(
            'CREATE TABLE IF NOT EXISTS questions_new ('
            'id TEXT NOT NULL PRIMARY KEY,'
            'subject TEXT NOT NULL,'
            'chapter TEXT NOT NULL,'
            'topic TEXT NOT NULL,'
            'topicId TEXT NOT NULL DEFAULT \'\','
            'questionText TEXT NOT NULL,'
            'options TEXT NOT NULL,'
            'correctAnswer TEXT NOT NULL,'
            'explanation TEXT,'
            'ncertReference TEXT,'
            'year INTEGER,'
            'difficulty TEXT NOT NULL DEFAULT \'Medium\','
            'tags TEXT,'
            'imageUrl TEXT,'
            'type TEXT NOT NULL DEFAULT \'MCQ\','
            'remoteId TEXT,'
            'updatedAt INTEGER,'
            'isActive INTEGER NOT NULL DEFAULT 1,'
            'source TEXT NOT NULL DEFAULT \'seeded\''
            ')',
          );
          await customStatement(
            'INSERT OR IGNORE INTO questions_new ('
            'id, subject, chapter, topic, topicId, questionText, options, correctAnswer, '
            'explanation, ncertReference, year, difficulty, tags, imageUrl, type, '
            'remoteId, updatedAt, isActive, source'
            ') SELECT '
            'id, subject, chapter, topic, topicId, questionText, options, correctAnswer, '
            'explanation, ncertReference, year, difficulty, tags, imageUrl, type, '
            'remoteId, updatedAt, isActive, source '
            'FROM questions',
          );
          await m.deleteTable('questions');
          await customStatement(
            'ALTER TABLE questions_new RENAME TO questions',
          );
        } catch (_) {}
      }
      if (from < 31) {
        // Add user_id columns to all user-scoped tables for account isolation
        // QuizAttempts
        await _addColumnSafely(
          m,
          quizAttempts,
          (quizAttempts as dynamic).userId,
        );
        // Chats
        await _addColumnSafely(m, chats, (chats as dynamic).userId);
        // Bookmarks
        await _addColumnSafely(m, bookmarks, (bookmarks as dynamic).userId);
        // ErrorBook - recreate table with new primary key
        try {
          await customStatement(
            'CREATE TABLE IF NOT EXISTS error_book_new ('
            'user_id INTEGER NOT NULL,'
            'question_id TEXT NOT NULL,'
            'added_at INTEGER NOT NULL,'
            'retry_count INTEGER NOT NULL DEFAULT 0,'
            'is_resolved INTEGER NOT NULL DEFAULT 0,'
            'PRIMARY KEY (user_id, question_id)'
            ')',
          );
          await customStatement(
            'INSERT OR IGNORE INTO error_book_new (user_id, question_id, added_at, retry_count, is_resolved) '
            'SELECT 1, question_id, added_at, retry_count, is_resolved FROM error_book',
          );
          await m.deleteTable('error_book');
          await customStatement(
            'ALTER TABLE error_book_new RENAME TO error_book',
          );
        } catch (_) {}
        // SpacedRepetition - recreate table with new primary key
        try {
          await customStatement(
            'CREATE TABLE IF NOT EXISTS spaced_repetition_new ('
            'user_id INTEGER NOT NULL,'
            'question_id TEXT NOT NULL,'
            'box INTEGER NOT NULL DEFAULT 0,'
            'ease_factor REAL NOT NULL DEFAULT 2.5,'
            'interval_days INTEGER NOT NULL DEFAULT 0,'
            'repetitions INTEGER NOT NULL DEFAULT 0,'
            'lapses INTEGER NOT NULL DEFAULT 0,'
            'due_at INTEGER NOT NULL,'
            'last_reviewed_at INTEGER,'
            'updated_at INTEGER,'
            'PRIMARY KEY (user_id, question_id)'
            ')',
          );
          await customStatement(
            'INSERT OR IGNORE INTO spaced_repetition_new (user_id, question_id, box, ease_factor, interval_days, repetitions, lapses, due_at, last_reviewed_at, updated_at) '
            'SELECT 1, question_id, box, ease_factor, interval_days, repetitions, lapses, due_at, last_reviewed_at, updated_at FROM spaced_repetition',
          );
          await m.deleteTable('spaced_repetition');
          await customStatement(
            'ALTER TABLE spaced_repetition_new RENAME TO spaced_repetition',
          );
        } catch (_) {}
        // TopicProgressEntries - recreate table with new primary key
        try {
          await customStatement(
            'CREATE TABLE IF NOT EXISTS topic_progress_entries_new ('
            'user_id INTEGER NOT NULL,'
            'topic_id TEXT NOT NULL,'
            'questions_attempted INTEGER NOT NULL DEFAULT 0,'
            'questions_correct INTEGER NOT NULL DEFAULT 0,'
            'time_spent_seconds INTEGER NOT NULL DEFAULT 0,'
            'average_time_seconds REAL NOT NULL DEFAULT 0.0,'
            'last_attempted INTEGER NOT NULL,'
            'is_completed INTEGER NOT NULL DEFAULT 0,'
            'updated_at INTEGER,'
            'PRIMARY KEY (user_id, topic_id)'
            ')',
          );
          await customStatement(
            'INSERT OR IGNORE INTO topic_progress_entries_new (user_id, topic_id, questions_attempted, questions_correct, time_spent_seconds, average_time_seconds, last_attempted, is_completed, updated_at) '
            'SELECT 1, topic_id, questions_attempted, questions_correct, time_spent_seconds, average_time_seconds, last_attempted, is_completed, updated_at FROM topic_progress_entries',
          );
          await m.deleteTable('topic_progress_entries');
          await customStatement(
            'ALTER TABLE topic_progress_entries_new RENAME TO topic_progress_entries',
          );
        } catch (_) {}
        // Flashcards - recreate table with new primary key
        try {
          await customStatement(
            'CREATE TABLE IF NOT EXISTS flashcards_new ('
            'user_id INTEGER NOT NULL,'
            'id TEXT NOT NULL,'
            'front TEXT NOT NULL,'
            'back TEXT NOT NULL,'
            'subject TEXT NOT NULL,'
            'topic_id TEXT NOT NULL DEFAULT \'\','
            'image_url TEXT,'
            'chapter_id TEXT NOT NULL DEFAULT \'\','
            'ncert_reference TEXT NOT NULL DEFAULT \'\','
            'source_page INTEGER NOT NULL DEFAULT 0,'
            'difficulty TEXT NOT NULL DEFAULT \'Medium\','
            'is_generated INTEGER NOT NULL DEFAULT 0,'
            'box INTEGER NOT NULL DEFAULT 0,'
            'ease_factor REAL NOT NULL DEFAULT 2.5,'
            'interval_days INTEGER NOT NULL DEFAULT 0,'
            'repetitions INTEGER NOT NULL DEFAULT 0,'
            'lapses INTEGER NOT NULL DEFAULT 0,'
            'due_at INTEGER NOT NULL,'
            'last_reviewed_at INTEGER,'
            'created_at INTEGER,'
            'PRIMARY KEY (user_id, id)'
            ')',
          );
          await customStatement(
            'INSERT OR IGNORE INTO flashcards_new (user_id, id, front, back, subject, topic_id, image_url, chapter_id, ncert_reference, source_page, difficulty, is_generated, box, ease_factor, interval_days, repetitions, lapses, due_at, last_reviewed_at, created_at) '
            'SELECT 1, id, front, back, subject, topic_id, image_url, chapter_id, ncert_reference, source_page, difficulty, is_generated, box, ease_factor, interval_days, repetitions, lapses, due_at, last_reviewed_at, created_at FROM flashcards',
          );
          await m.deleteTable('flashcards');
          await customStatement(
            'ALTER TABLE flashcards_new RENAME TO flashcards',
          );
        } catch (_) {}
        // DailyGoals - recreate table with new primary key
        try {
          await customStatement(
            'CREATE TABLE IF NOT EXISTS daily_goals_new ('
            'user_id INTEGER NOT NULL,'
            'date INTEGER NOT NULL,'
            'target INTEGER NOT NULL DEFAULT 50,'
            'completed INTEGER NOT NULL DEFAULT 0,'
            'status TEXT NOT NULL DEFAULT \'pending\','
            'PRIMARY KEY (user_id, date)'
            ')',
          );
          await customStatement(
            'INSERT OR IGNORE INTO daily_goals_new (user_id, date, target, completed, status) '
            'SELECT 1, date, target, completed, status FROM daily_goals',
          );
          await m.deleteTable('daily_goals');
          await customStatement(
            'ALTER TABLE daily_goals_new RENAME TO daily_goals',
          );
        } catch (_) {}
        // DppSets
        await _addColumnSafely(m, dppSets, (dppSets as dynamic).userId);
        // DppQuestions
        await _addColumnSafely(
          m,
          dppQuestions,
          (dppQuestions as dynamic).userId,
        );
        // QuizSessions - recreate table with new primary key
        try {
          await customStatement(
            'CREATE TABLE IF NOT EXISTS quiz_sessions_new ('
            'session_id TEXT NOT NULL,'
            'user_id INTEGER NOT NULL,'
            'topic_id TEXT NOT NULL,'
            'subject TEXT NOT NULL,'
            'test_type TEXT NOT NULL DEFAULT \'topic\','
            'quiz_mode TEXT NOT NULL DEFAULT \'practice\','
            'time_limit_seconds INTEGER NOT NULL DEFAULT 0,'
            'seed INTEGER NOT NULL,'
            'current_index INTEGER NOT NULL DEFAULT 0,'
            'selected_answers TEXT NOT NULL,'
            'answer_results TEXT NOT NULL,'
            'time_spent_per_question TEXT NOT NULL,'
            'flagged_questions TEXT NOT NULL,'
            'visited_questions TEXT NOT NULL,'
            'score INTEGER NOT NULL DEFAULT 0,'
            'incorrect_count INTEGER NOT NULL DEFAULT 0,'
            'elapsed_seconds INTEGER NOT NULL DEFAULT 0,'
            'is_completed INTEGER NOT NULL DEFAULT 0,'
            'question_ids TEXT NOT NULL,'
            'question_data TEXT,'
            'created_at INTEGER NOT NULL,'
            'updated_at INTEGER,'
            'PRIMARY KEY (user_id, session_id)'
            ')',
          );
          await customStatement(
            'INSERT OR IGNORE INTO quiz_sessions_new (user_id, session_id, topic_id, subject, test_type, quiz_mode, time_limit_seconds, seed, current_index, selected_answers, answer_results, time_spent_per_question, flagged_questions, visited_questions, score, incorrect_count, elapsed_seconds, is_completed, question_ids, question_data, created_at, updated_at) '
            'SELECT 1, session_id, topic_id, subject, test_type, quiz_mode, time_limit_seconds, seed, current_index, selected_answers, answer_results, time_spent_per_question, flagged_questions, visited_questions, score, incorrect_count, elapsed_seconds, is_completed, question_ids, question_data, created_at, updated_at FROM quiz_sessions',
          );
          await m.deleteTable('quiz_sessions');
          await customStatement(
            'ALTER TABLE quiz_sessions_new RENAME TO quiz_sessions',
          );
        } catch (_) {}
        // Evaluations
        await _addColumnSafely(m, evaluations, (evaluations as dynamic).userId);
      }
      if (from < 32) {
        // Add unique index on questions.remoteId to prevent duplicate catalog questions
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS questions_remote_id_unique ON questions(remoteId)',
        );
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

  Future<void> removeFromErrorBook(String questionId, {int userId = 0}) =>
      (delete(errorBook)..where(
            (t) => t.questionId.equals(questionId) & t.userId.equals(userId),
          ))
          .go();

  Future<List<ErrorBookData>> getErrorBookEntries({int userId = 0}) =>
      (select(errorBook)..where((t) => t.userId.equals(userId))).get();

  Future<void> resolveErrorBookEntry(
    String questionId, {
    int userId = 0,
  }) async {
    await (update(errorBook)..where(
          (t) => t.questionId.equals(questionId) & t.userId.equals(userId),
        ))
        .write(const ErrorBookCompanion(isResolved: Value(true)));
  }

  // ============= USERS =============

  Future<User?> registerUser(UsersCompanion user) async {
    final id = await into(users).insert(user);
    return getUserById(id);
  }

  /// Creates a local user from an already-authenticated Supabase user.
  Future<User?> createUserFromCloud({
    required String email,
    required String username,
    required String supabaseId,
    String? fullName,
  }) async {
    final companion = UsersCompanion(
      email: Value(email),
      username: Value(username),
      supabaseId: Value(supabaseId),
      fullName: Value(fullName),
      passwordHash: Value(''), // No local password for cloud-linked accounts
      createdAt: Value(DateTime.now()),
    );
    final id = await into(users).insert(companion);
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

  Future<void> incrementFailedLoginAttempts(int userId) async {
    final user = await getUserById(userId);
    if (user == null) return;
    final attempts = user.failedLoginAttempts + 1;
    DateTime? lockedUntil;
    if (attempts >= 5) {
      lockedUntil = DateTime.now().add(const Duration(minutes: 15));
    }
    await (update(users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        failedLoginAttempts: Value(attempts),
        lockedUntil: lockedUntil != null ? Value(lockedUntil) : const Value.absent(),
      ),
    );
  }

  Future<void> resetFailedLoginAttempts(int userId) async {
    await (update(users)..where((t) => t.id.equals(userId))).write(
      const UsersCompanion(
        failedLoginAttempts: Value(0),
        lockedUntil: Value(null),
      ),
    );
  }

Future<bool> isAccountLocked(int userId) async {
    final user = await getUserById(userId);
    if (user == null || user.lockedUntil == null) return false;
    return user.lockedUntil!.isAfter(DateTime.now());
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
    final codeHash = SecurityUtils.hashPassword(code);
    await (update(users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        twoFactorCode: Value(codeHash),
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
  getActiveTwoFactorCode(int userId, String providedCode) async {
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
    // Verify the provided code against the stored hash
    if (!SecurityUtils.verifyPassword(providedCode, row.twoFactorCode!)) {
      return null;
    }
    return (
      userId: row.id,
      code: providedCode,
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
    final codeHash = SecurityUtils.hashPassword(code);
    await (update(users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        passwordResetCode: Value(codeHash),
        passwordResetExpiresAt: Value(expiresAt),
      ),
    );
  }

  Future<({int userId, String code, DateTime expiresAt})?>
  getActivePasswordReset(int userId, String providedCode) async {
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
    // Verify the provided code against the stored hash
    if (!SecurityUtils.verifyPassword(providedCode, row.passwordResetCode!)) {
      return null;
    }
    return (
      userId: row.id,
      code: providedCode,
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

  Future<void> clearAllUserData(int userId) async {
    // Delete all user-scoped data
    await (delete(quizAttempts)..where((t) => t.userId.equals(userId))).go();
    await (delete(
      topicProgressEntries,
    )..where((t) => t.userId.equals(userId))).go();
    await (delete(bookmarks)..where((t) => t.userId.equals(userId))).go();
    await (delete(chats)..where((t) => t.userId.equals(userId))).go();
    await (delete(errorBook)..where((t) => t.userId.equals(userId))).go();
    await (delete(
      spacedRepetition,
    )..where((t) => t.userId.equals(userId))).go();
    await (delete(flashcards)..where((t) => t.userId.equals(userId))).go();
    await (delete(dailyGoals)..where((t) => t.userId.equals(userId))).go();
    await (delete(dppSets)..where((t) => t.userId.equals(userId))).go();
    await (delete(dppQuestions)..where((t) => t.userId.equals(userId))).go();
    await (delete(quizSessions)..where((t) => t.userId.equals(userId))).go();
    await (delete(evaluations)..where((t) => t.userId.equals(userId))).go();
    // Finally delete the user
    await (delete(users)..where((t) => t.id.equals(userId))).go();
  }

  Future<void> clearUserData(int userId) async {
    await clearAllUserData(userId);
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

  Future<List<Chat>> getAllChats({int userId = 0}) =>
      (select(chats)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]))
          .get();

  Future<void> clearChatHistory({int userId = 0}) =>
      (delete(chats)..where((t) => t.userId.equals(userId))).go();

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

  Future<List<QuizAttempt>> getAllQuizAttempts({int userId = 0}) =>
      (select(quizAttempts)..where((t) => t.userId.equals(userId))).get();

  Future<List<QuizAttempt>> getQuizAttemptsBySubject(
    String subjectName, {
    int userId = 0,
  }) =>
      (select(quizAttempts)..where(
            (t) => t.subject.equals(subjectName) & t.userId.equals(userId),
          ))
          .get();

  // ============= TOPIC PROGRESS =============

  Future<void> upsertTopicProgress(Insertable<TopicProgressEntry> entry) =>
      into(topicProgressEntries).insertOnConflictUpdate(entry);

  Future<List<TopicProgressEntry>> getAllTopicProgress({int userId = 0}) =>
      (select(
        topicProgressEntries,
      )..where((t) => t.userId.equals(userId))).get();

  Future<TopicProgressEntry?> getTopicProgress(
    String topicId, {
    int userId = 0,
  }) =>
      (select(topicProgressEntries)
            ..where((t) => t.topicId.equals(topicId) & t.userId.equals(userId)))
          .getSingleOrNull();

  // ============= BOOKMARKS =============

  /// Upserts by the `question_id` unique index so repeated cloud pulls never
  /// duplicate a bookmark.
  Future<void> insertBookmark(BookmarksCompanion bookmark) =>
      into(bookmarks).insert(
        bookmark,
        onConflict: DoUpdate((_) => bookmark, target: [bookmarks.questionId]),
      );

  Future<void> removeBookmark(String questionId, {int userId = 0}) =>
      (delete(bookmarks)..where(
            (t) => t.questionId.equals(questionId) & t.userId.equals(userId),
          ))
          .go();

  Future<List<Bookmark>> getAllBookmarks({int userId = 0}) =>
      (select(bookmarks)..where((t) => t.userId.equals(userId))).get();

  Future<bool> isBookmarked(String questionId, {int userId = 0}) async {
    final result =
        await (select(bookmarks)..where(
              (t) => t.questionId.equals(questionId) & t.userId.equals(userId),
            ))
            .get();
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

  Future<List<SpacedRepetitionData>> getSpacedRepetitionCards({
    int userId = 0,
  }) => (select(spacedRepetition)..where((t) => t.userId.equals(userId))).get();

  Future<SpacedRepetitionData?> getSpacedRepetition(
    String questionId, {
    int userId = 0,
  }) =>
      (select(spacedRepetition)..where(
            (t) => t.questionId.equals(questionId) & t.userId.equals(userId),
          ))
          .getSingleOrNull();

  Future<List<SpacedRepetitionData>> getDueSpacedRepetition(
    DateTime now, {
    int userId = 0,
  }) {
    final query = select(spacedRepetition)
      ..where(
        (t) => t.dueAt.isSmallerOrEqualValue(now) & t.userId.equals(userId),
      )
      ..orderBy([(t) => OrderingTerm(expression: t.dueAt)]);
    return query.get();
  }

  Future<void> removeSpacedRepetition(String questionId, {int userId = 0}) =>
      (delete(spacedRepetition)..where(
            (t) => t.questionId.equals(questionId) & t.userId.equals(userId),
          ))
          .go();

  // ============= FLASHCARDS =============

  Future<void> insertFlashcard(FlashcardsCompanion card) =>
      into(flashcards).insert(card, mode: InsertMode.insertOrReplace);

  Future<void> insertFlashcardsBatch(List<FlashcardsCompanion> cards) async {
    await batch(
      (b) => b.insertAll(flashcards, cards, mode: InsertMode.insertOrReplace),
    );
  }

  Future<List<Flashcard>> getAllFlashcards({int userId = 0}) =>
      (select(flashcards)..where((t) => t.userId.equals(userId))).get();

  Future<List<Flashcard>> getFlashcardsBySubject(
    String subject, {
    int userId = 0,
  }) => (select(
    flashcards,
  )..where((t) => t.subject.equals(subject) & t.userId.equals(userId))).get();

  Future<List<Flashcard>> getDueFlashcards(DateTime now, {int userId = 0}) {
    final query = select(flashcards)
      ..where(
        (t) => t.dueAt.isSmallerOrEqualValue(now) & t.userId.equals(userId),
      )
      ..orderBy([(t) => OrderingTerm(expression: t.dueAt)]);
    return query.get();
  }

  Future<Flashcard?> getFlashcardById(String id, {int userId = 0}) => (select(
    flashcards,
  )..where((t) => t.id.equals(id) & t.userId.equals(userId))).getSingleOrNull();

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

  // ============= QUIZ SESSIONS =============

  Future<void> upsertQuizSession(QuizSessionsCompanion session) =>
      into(quizSessions).insertOnConflictUpdate(session);

  Future<QuizSession?> getQuizSession(String sessionId, {int userId = 0}) =>
      (select(quizSessions)..where(
            (t) => t.sessionId.equals(sessionId) & t.userId.equals(userId),
          ))
          .getSingleOrNull();

  Future<List<QuizSession>> getAllQuizSessions({int userId = 0}) =>
      (select(quizSessions)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([
              (t) => OrderingTerm(
                expression: t.updatedAt,
                mode: OrderingMode.desc,
              ),
            ]))
          .get();

  Future<void> deleteQuizSession(String sessionId, {int userId = 0}) =>
      (delete(quizSessions)..where(
            (t) => t.sessionId.equals(sessionId) & t.userId.equals(userId),
          ))
          .go();

  Future<void> deleteCompletedQuizSessions({int userId = 0}) => (delete(
    quizSessions,
  )..where((t) => t.isCompleted.equals(true) & t.userId.equals(userId))).go();

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
