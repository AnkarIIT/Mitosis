import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/drift_database.dart' as db;

/// Two-way cloud sync with timestamp-first conflict resolution.
///
/// Instead of "pull everything, then push everything" (where the local copy
/// always wins and duplicates accumulate on repeated pulls), every natural key
/// is reconciled inside a single cloud-row loop:
///
///   * remote-only row  -> written into the local Drift store
///   * local-only row   -> upserted to Supabase (stamped with the auth UID)
///   * both sides       -> the row with the newer `updated_at` wins and is
///     mirrored onto the losing side; equal timestamps are left untouched.
///
/// Timestamps on the wire are normalised to UTC so devices in different time
/// zones agree on ordering. Local rows written through Drift's `clientDefault`
/// are stamped with the local wall-clock time on every insert.
///
/// Requirement: the remote `quiz_attempts`, `topic_progress` and `bookmarks`
/// tables must carry an `updated_at` column and unique conflict targets — see
/// `supabase/02_user_data_sync.sql`.
class CloudSyncService {
  final db.AppDatabase _localDb;
  final SupabaseClient _supabase;

  CloudSyncService(this._localDb, this._supabase);

  bool get _isAuthenticated => _supabase.auth.currentUser != null;

  /// Returns the authenticated user's UUID, or throws if not authenticated.
  ///
  /// Using a getter that throws prevents any data from being accidentally
  /// written under a null / wrong user ID.
  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw StateError('CloudSyncService: attempted operation without an authenticated user.');
    }
    return id;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Pull from cloud, then reconcile local changes for all data types.
  Future<void> syncAll() async {
    if (!_isAuthenticated) return;

    try {
      debugPrint('🔄 Starting Cloud Sync...');
      final counters = _SyncCounters();
      await _syncQuizAttempts(counters);
      await _syncTopicProgress(counters);
      await _syncBookmarks(counters);
      debugPrint(
        '✅ Cloud Sync Complete: pushed=${counters.pushed}, pulled=${counters.pulled}',
      );
    } catch (e) {
      debugPrint('❌ Cloud Sync Failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Quiz Attempts
  // ---------------------------------------------------------------------------

  Future<void> _syncQuizAttempts(_SyncCounters counters) async {
    final uid = _userId;

    // RLS on the server ensures this only returns rows for `uid`.
    final cloudRows = List<Map<String, dynamic>>.from(
      await _supabase.from('quiz_attempts').select().eq('user_id', uid),
    );
    final localRows = await _localDb.getAllQuizAttempts();

    // Natural key: attempted_at. Local timestamps are wall-clock naive; remote
    // ones are parsed back to the same local representation, so both sides of
    // a device converge on identical keys.
    final byKey = <int, (db.QuizAttempt?, Map<String, dynamic>?)>{};
    for (final row in localRows) {
      byKey[row.attemptedAt.microsecondsSinceEpoch] = (row, null);
    }
    for (final row in cloudRows) {
      final key = _parseDate(row['attempted_at']).microsecondsSinceEpoch;
      byKey.update(key, (v) => (v.$1, row), ifAbsent: () => (null, row));
    }

    for (final entry in byKey.entries) {
      final (local, remote) = entry.value;
      if (local == null) {
        await _localDb.upsertQuizAttempt(_remoteAttemptToLocal(remote!));
        counters.pulled++;
      } else if (remote == null) {
        await _pushAttempt(uid, local);
        counters.pushed++;
      } else {
        switch (_resolve(local.updatedAt, _rowTimestamp(remote, 'updated_at'))) {
          case _Winner.local:
            await _pushAttempt(uid, local);
            counters.pushed++;
          case _Winner.remote:
            await _localDb.upsertQuizAttempt(_remoteAttemptToLocal(remote));
            counters.pulled++;
          case _Winner.tie:
            break;
        }
      }
    }
  }

  Future<void> _pushAttempt(String uid, db.QuizAttempt local) {
    return _supabase.from('quiz_attempts').upsert(
      {
        'user_id': uid, // always the verified authenticated UID
        'topic_id': local.topicId,
        'subject': local.subject,
        'score': local.score,
        'incorrect_count': local.incorrectCount,
        'total_questions': local.totalQuestions,
        'time_spent_seconds': local.timeSpentSeconds,
        'attempted_at': local.attemptedAt.toUtc().toIso8601String(),
        'selected_answers': local.selectedAnswers,
        'test_type': local.testType,
        'subject_scores': local.subjectScores,
        'updated_at': (local.updatedAt ?? DateTime.now())
            .toUtc()
            .toIso8601String(),
      },
      onConflict: 'user_id, attempted_at',
    );
  }

  db.QuizAttemptsCompanion _remoteAttemptToLocal(Map<String, dynamic> row) {
    return db.QuizAttemptsCompanion.insert(
      topicId: _asString(row['topic_id']),
      subject: _asString(row['subject']),
      score: _asInt(row['score']),
      incorrectCount: Value(_asInt(row['incorrect_count'])),
      totalQuestions: _asInt(row['total_questions']),
      timeSpentSeconds: _asInt(row['time_spent_seconds']),
      attemptedAt: _parseDate(row['attempted_at'], fallback: DateTime.now()),
      selectedAnswers: _asString(row['selected_answers'], fallback: '[]'),
      testType: Value(_asString(row['test_type'], fallback: 'topic')),
      subjectScores: Value(row['subject_scores'] as String?),
      updatedAt: Value(_rowTimestamp(row, 'updated_at')),
    );
  }

  // ---------------------------------------------------------------------------
  // Topic Progress
  // ---------------------------------------------------------------------------

  Future<void> _syncTopicProgress(_SyncCounters counters) async {
    final uid = _userId;

    final cloudRows = List<Map<String, dynamic>>.from(
      await _supabase.from('topic_progress').select().eq('user_id', uid),
    );
    final localRows = await _localDb.getAllTopicProgress();

    final byKey = <String, (db.TopicProgressEntry?, Map<String, dynamic>?)>{};
    for (final row in localRows) {
      byKey[row.topicId] = (row, null);
    }
    for (final row in cloudRows) {
      final key = _asString(row['topic_id']);
      byKey.update(key, (v) => (v.$1, row), ifAbsent: () => (null, row));
    }

    for (final entry in byKey.entries) {
      final (local, remote) = entry.value;
      if (local == null) {
        await _localDb.upsertTopicProgress(_remoteProgressToLocal(remote!));
        counters.pulled++;
      } else if (remote == null) {
        await _pushProgress(uid, local);
        counters.pushed++;
      } else {
        switch (_resolve(local.updatedAt, _rowTimestamp(remote, 'updated_at'))) {
          case _Winner.local:
            await _pushProgress(uid, local);
            counters.pushed++;
          case _Winner.remote:
            await _localDb.upsertTopicProgress(_remoteProgressToLocal(remote));
            counters.pulled++;
          case _Winner.tie:
            break;
        }
      }
    }
  }

  Future<void> _pushProgress(String uid, db.TopicProgressEntry local) {
    return _supabase.from('topic_progress').upsert(
      {
        'user_id': uid,
        'topic_id': local.topicId,
        'questions_attempted': local.questionsAttempted,
        'questions_correct': local.questionsCorrect,
        // The remote schema stores the average; the total is derived locally.
        'average_time_seconds': local.averageTimeSeconds,
        'last_attempted': local.lastAttempted.toUtc().toIso8601String(),
        'is_completed': local.isCompleted,
        'updated_at': (local.updatedAt ?? DateTime.now())
            .toUtc()
            .toIso8601String(),
      },
      onConflict: 'user_id, topic_id',
    );
  }

  db.TopicProgressEntriesCompanion _remoteProgressToLocal(
    Map<String, dynamic> row,
  ) {
    final attempted = _asInt(row['questions_attempted']);
    final average = _asDouble(row['average_time_seconds']);
    return db.TopicProgressEntriesCompanion.insert(
      topicId: _asString(row['topic_id']),
      questionsAttempted: Value(attempted),
      questionsCorrect: Value(_asInt(row['questions_correct'])),
      timeSpentSeconds: Value((average * attempted).round()),
      averageTimeSeconds: Value(average),
      lastAttempted: _parseDate(row['last_attempted'], fallback: DateTime.now()),
      isCompleted: Value(row['is_completed'] as bool? ?? false),
      updatedAt: Value(_rowTimestamp(row, 'updated_at')),
    );
  }

  // ---------------------------------------------------------------------------
  // Bookmarks
  // ---------------------------------------------------------------------------

  Future<void> _syncBookmarks(_SyncCounters counters) async {
    final uid = _userId;

    final cloudRows = List<Map<String, dynamic>>.from(
      await _supabase.from('bookmarks').select().eq('user_id', uid),
    );
    final localRows = await _localDb.getAllBookmarks();

    // Natural key: question_id. The local unique index (v17 migration) makes
    // repeated pulls idempotent.
    final byKey = <String, (db.Bookmark?, Map<String, dynamic>?)>{};
    for (final row in localRows) {
      byKey[row.questionId] = (row, null);
    }
    for (final row in cloudRows) {
      final key = _asString(row['question_id']);
      byKey.update(key, (v) => (v.$1, row), ifAbsent: () => (null, row));
    }

    for (final entry in byKey.entries) {
      final (local, remote) = entry.value;
      if (local == null) {
        await _localDb.insertBookmark(_remoteBookmarkToLocal(remote!));
        counters.pulled++;
      } else if (remote == null) {
        await _pushBookmark(uid, local);
        counters.pushed++;
      } else {
        switch (_resolve(local.updatedAt, _rowTimestamp(remote, 'updated_at'))) {
          case _Winner.local:
            await _pushBookmark(uid, local);
            counters.pushed++;
          case _Winner.remote:
            await _localDb.insertBookmark(_remoteBookmarkToLocal(remote));
            counters.pulled++;
          case _Winner.tie:
            break;
        }
      }
    }
  }

  Future<void> _pushBookmark(String uid, db.Bookmark local) {
    return _supabase.from('bookmarks').upsert(
      {
        'user_id': uid,
        'question_id': local.questionId,
        'subject': local.subject,
        'topic_id': local.topicId,
        'bookmarked_at': local.bookmarkedAt.toUtc().toIso8601String(),
        'updated_at': (local.updatedAt ?? DateTime.now())
            .toUtc()
            .toIso8601String(),
      },
      onConflict: 'user_id, question_id',
    );
  }

  db.BookmarksCompanion _remoteBookmarkToLocal(Map<String, dynamic> row) {
    return db.BookmarksCompanion.insert(
      questionId: _asString(row['question_id']),
      subject: _asString(row['subject']),
      topicId: _asString(row['topic_id']),
      bookmarkedAt: _parseDate(row['bookmarked_at'], fallback: DateTime.now()),
      updatedAt: Value(_rowTimestamp(row, 'updated_at')),
    );
  }

  // ---------------------------------------------------------------------------
  // Conflict resolution helpers
  // ---------------------------------------------------------------------------

  /// The row with the newer `updated_at` wins. Legacy rows whose timestamp was
  /// never written are treated as epoch, so the (better-specified) remote copy
  /// wins on the first sync after the v17 migration.
  static _Winner _resolve(DateTime? localTs, DateTime remoteTs) {
    final local = localTs?.toUtc();
    if (local == null) return _Winner.remote;
    if (local.isAfter(remoteTs)) return _Winner.local;
    if (local == remoteTs) return _Winner.tie;
    return _Winner.remote;
  }

  static DateTime _rowTimestamp(Map<String, dynamic> row, String field) =>
      _parseDate(row[field]).toUtc();

  static DateTime _parseDate(dynamic value, {DateTime? fallback}) {
    if (value is DateTime) return value;
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return fallback ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    try {
      // Parse to the device-local representation so keys line up with naive
      // local timestamps written by Drift.
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return fallback ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
  }

  static int _asInt(dynamic value) => (value as num?)?.toInt() ?? 0;

  static double _asDouble(dynamic value) => (value as num?)?.toDouble() ?? 0.0;

  static String _asString(dynamic value, {String fallback = ''}) {
    final v = value?.toString();
    return (v == null || v.isEmpty) ? fallback : v;
  }
}

enum _Winner { local, remote, tie }

class _SyncCounters {
  int pushed = 0;
  int pulled = 0;
}
