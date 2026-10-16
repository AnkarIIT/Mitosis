import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/drift_database.dart' as db;

/// One page of catalog rows as returned by the remote.
typedef CatalogPage = List<Map<String, dynamic>>;

/// Read-only view of the remote question catalog.
///
/// ## Why this exists
/// `ContentSyncService` previously took a concrete `SupabaseClient` and called
/// `.from(...).select().eq().or().order().limit()` directly. That made every
/// interesting behaviour — cursor pagination, per-row failure isolation,
/// soft-delete reconciliation, retry after a mid-run network failure — testable
/// only against a live project. None of it was covered, which is how a
/// defect that silently produced an ungradable question bank survived.
///
/// Pulling the remote read behind this interface gives the engine a seam, so
/// the whole delta algorithm can be driven by an in-memory fake.
abstract class CatalogSource {
  /// Rows strictly after [cursor] (exclusive) and at or before [boundaryIso],
  /// ordered by `(updated_at, id)` and capped at [limit].
  ///
  /// Returns fewer than [limit] rows to signal the final page.
  Future<CatalogPage> fetchPage({
    required ContentSyncCursor cursor,
    required String boundaryIso,
    required int limit,
  });

  /// Remote rows that are no longer active and were last changed at or before
  /// [boundaryIso], used for soft-delete reconciliation.
  ///
  /// Paginated on the same `(updated_at, id)` tuple as [fetchPage]: returning a
  /// single uncursored page silently capped reconciliation at `limit` rows, so
  /// anything beyond that stayed active locally forever. Returns fewer than
  /// [limit] rows to signal the final page.
  Future<CatalogPage> fetchInactive({
    required ContentSyncCursor cursor,
    required String boundaryIso,
    required int limit,
  });
}

/// Raised by a [CatalogSource] when the remote read fails.
///
/// Callers treat this as retryable; the engine records it and stops the run
/// without discarding the pages already committed.
class CatalogFetchException implements Exception {
  final String message;
  const CatalogFetchException(this.message);

  @override
  String toString() => 'CatalogFetchException: $message';
}

/// [CatalogSource] backed by a Supabase PostgREST table.
class SupabaseCatalogSource implements CatalogSource {
  final SupabaseClient _client;
  final String _table;

  SupabaseCatalogSource(this._client, {String table = 'questions'})
    : _table = table;

  @override
  Future<CatalogPage> fetchPage({
    required ContentSyncCursor cursor,
    required String boundaryIso,
    required int limit,
  }) async {
    // Builder-type note: `.or()` lives on PostgrestFilterBuilder, which
    // `.order()` / `.limit()` replace with a PostgrestTransformBuilder. So the
    // tuple predicate must be applied *before* ordering, and ordering last.
    var query = _client
        .from(_table)
        .select()
        .eq('is_active', true)
        .lte('updated_at', boundaryIso);

    final cursorUpdatedAt = cursor.updatedAt;
    if (cursorUpdatedAt != null) {
      final cursorIso = cursorUpdatedAt.toUtc().toIso8601String();
      // Tuple comparison:
      //   (updated_at, id) > (cursor.updatedAt, cursor.id)
      // expressed so the server can satisfy both the predicate and the
      // ORDER BY from the composite index instead of sorting each page.
      query = query.or(
        'and(updated_at.gt.$cursorIso,'
        'or(updated_at.eq.$cursorIso,id.gt.${cursor.id}))',
      );
    }

    try {
      final response = await query.order('updated_at').order('id').limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw CatalogFetchException('$error');
    }
  }

  @override
  Future<CatalogPage> fetchInactive({
    required ContentSyncCursor cursor,
    required String boundaryIso,
    required int limit,
  }) async {
    try {
      var query = _client
          .from(_table)
          .select('id, updated_at')
          .eq('is_active', false)
          .lte('updated_at', boundaryIso);
      if (cursor.updatedAt != null) {
        final cursorIso = cursor.updatedAt!.toUtc().toIso8601String();
        // Same tuple predicate as fetchPage so pagination cannot skip or repeat.
        query = query.or(
          'and(updated_at.gt.$cursorIso,'
          'or(updated_at.eq.$cursorIso,id.gt.${cursor.id}))',
        );
      }
      final response = await query.order('updated_at').order('id').limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw CatalogFetchException('$error');
    }
  }
}

/// Outcome of a single [ContentSyncService.syncCatalog] run.
class ContentSyncReport {
  /// Rows successfully written to the local store.
  final int pulled;

  /// Rows that failed to map or write. These are *reported*, never fatal — one
  /// bad row must not abort the rest of the catalog.
  final int failed;

  /// Highest `updated_at` observed this run, committed as the new cursor.
  final DateTime? watermark;

  /// True when a hard failure stopped the run early. The cursor is still
  /// advanced to the last fully-persisted page, so the next run resumes there
  /// instead of replaying from the previous cursor.
  final bool partial;

  /// Local rows soft-deleted because the remote row was deactivated.
  final int deactivated;

  /// Human-readable diagnostics for failed rows (bounded).
  final List<String> diagnostics;

  const ContentSyncReport({
    required this.pulled,
    required this.failed,
    required this.watermark,
    required this.partial,
    this.deactivated = 0,
    this.diagnostics = const [],
  });

  /// True when nothing failed and the run completed.
  bool get isClean => failed == 0 && !partial;

  @override
  String toString() =>
      'ContentSyncReport(pulled: $pulled, failed: $failed, '
      'deactivated: $deactivated, partial: $partial, watermark: $watermark)';
}

/// Delta cursor for the content catalog: a `(updated_at, id)` tuple.
///
/// Total-ordered, which is what makes the delta pull lossless. A bare timestamp
/// is not: the next query is a strict `gt`, so every row sharing the final
/// timestamp is skipped forever.
class ContentSyncCursor {
  final String id;
  final DateTime? updatedAt;

  const ContentSyncCursor({required this.id, required this.updatedAt});

  const ContentSyncCursor.empty() : id = '', updatedAt = null;

  /// Parses a `"<iso>|<uuid>"` string into a cursor.
  ///
  /// ⚠️ This is a transport form only — persistence splits the tuple across
  /// `sync_watermarks.lastSyncedAt` and `.cursorId`, so [ContentSyncService]
  /// composes the cursor from those two columns rather than reading an encoded
  /// string back. Kept for callers that need to serialise a cursor themselves.
  ///
  /// An unparseable or absent timestamp yields a cursor with a null
  /// [updatedAt], which the engine treats as "sync from the beginning".
  factory ContentSyncCursor.decode(String stored) {
    final separator = stored.indexOf('|');
    if (separator == -1) {
      return ContentSyncCursor(
        id: '',
        updatedAt: ContentSyncService.parseUtcTimestamp(stored),
      );
    }
    return ContentSyncCursor(
      id: stored.substring(separator + 1),
      updatedAt: ContentSyncService.parseUtcTimestamp(
        stored.substring(0, separator),
      ),
    );
  }

  /// Serialised `"<iso>|<uuid>"` form.
  String encode() => '${updatedAt?.toUtc().toIso8601String()}|$id';

  @override
  String toString() => '${updatedAt?.toIso8601String()}|$id';

  @override
  bool operator ==(Object other) =>
      other is ContentSyncCursor &&
      other.id == id &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);
}

/// Pulls the published content catalog (questions) from Supabase into the local
/// Drift store so the NTA test engine can run 100% offline.
///
/// ## Identity
/// Remote UUIDs are preserved verbatim in `remoteId`. The local primary key is a
/// derived surrogate so bundled sample questions (string ids like `phy_001`) and
/// synced rows can coexist. Surrogate collisions are reported, never thrown —
/// one collision costs one row, not the whole run.
///
/// ## Delta cursor
/// Progress is a **tuple** `(updated_at, id)`, not a bare timestamp. A timestamp
/// watermark silently drops every row sharing that exact timestamp because the
/// next query is a strict `gt`. The tuple makes that failure class impossible.
/// Persisted as `<iso>|<uuid>` in the existing `sync_watermarks` table, so no
/// schema change is required; legacy timestamp-only rows still load.
///
/// ## Transactions
/// Each page's rows *and* its cursor advance commit in **one** Drift
/// transaction. A crash mid-page leaves the cursor exactly where the last
/// durable page ended, so no row is double-counted or skipped.
///
/// ## Soft deletes
/// Deactivated remote rows are collected in the same pass and reconciled at the
/// end, but only after a run that completed without a hard failure. A partial
/// catalog must never deactivate valid local content.
class ContentSyncService {
  static const _catalogTable = 'questions';

  /// Rows per page.
  static const int pageSize = 1000;

  /// Bound on retained diagnostics so a pathological payload cannot grow the
  /// report without limit.
  static const int _maxDiagnostics = 25;

  /// Chunk size for the collision-check lookup, kept well under Postgres' bind
  /// parameter limit.
  static const int _lookupChunk = 500;

  final db.AppDatabase _localDb;

  /// Remote catalog. Null disables sync (the offline-only configuration).
  final CatalogSource? _source;

  /// Builds a service that reads through a Supabase client.
  ///
  /// Kept as a convenience constructor so existing call sites are unchanged.
  ContentSyncService(this._localDb, SupabaseClient? client)
    : _source = client == null ? null : SupabaseCatalogSource(client);

  /// Builds a service over an arbitrary [CatalogSource].
  ///
  /// This is the seam the integration tests drive.
  ContentSyncService.withSource(this._localDb, CatalogSource? source)
    : _source = source;

  /// Pulls a bounded delta since the local cursor and reconciles soft deletes.
  ///
  /// Never throws: every failure mode is captured in the returned
  /// [ContentSyncReport] so callers can surface it without a try/catch, and so a
  /// transient network error is never misreported as a data error.
  Future<ContentSyncReport> syncCatalog() async {
    final source = _source;
    if (source == null) {
      return const ContentSyncReport(
        pulled: 0,
        failed: 0,
        watermark: null,
        partial: false,
      );
    }

    final diagnostics = <String>[];
    var pulled = 0;
    var failed = 0;
    var skipped = 0;
    var partial = false;
    var deactivated = 0;

    // Freeze the upper bound so rows written *during* this sync are picked up by
    // the next run instead of making this run internally inconsistent.
    final syncBoundary = DateTime.now().toUtc();
    final boundaryIso = syncBoundary.toIso8601String();

    // Loaded cursor, committed after each durable page.
    var cursor = await _loadCursor();

    try {
      while (true) {
        final rows = await source.fetchPage(
          cursor: cursor,
          boundaryIso: boundaryIso,
          limit: pageSize,
        );
        if (rows.isEmpty) break;

        // Load the local remote-id map for this page once so the collision
        // check below is an in-memory lookup rather than one SELECT per row.
        // Held in a LOCAL, not on the service: as instance state it was
        // reassigned per page, so two concurrent syncCatalog() runs raced and
        // one could validate its rows against the other's map.
        final pageRemoteIds = await _loadExistingRemoteIds([
          for (final row in rows)
            if ((row['id']?.toString() ?? '').isNotEmpty)
              _remoteToLocalId(row['id'].toString()),
        ]);

        // Map rows, isolating per-row failures.
        final mapped = <db.QuestionsCompanion>[];
        var pageFailed = 0;
        var pageSkipped = 0;
        for (final row in rows) {
          try {
            final companion = _mapRow(row, pageRemoteIds);
            if (companion != null) {
              mapped.add(companion);
            } else {
              pageSkipped++;
            }
          } catch (error) {
            pageFailed++;
            _addDiagnostic(
              diagnostics,
              'row ${row['id']}: ${error.runtimeType}',
            );
          }
        }

        // Durable page commit: rows + cursor in one transaction.
        final nextCursor = _cursorFrom(rows.last, syncBoundary);
        await _localDb.transaction(() async {
          if (mapped.isNotEmpty) {
            await _localDb.batch((batch) {
              batch.insertAllOnConflictUpdate(_localDb.questions, mapped);
            });
          }
          await _localDb.setSyncTimestamp(
            _catalogTable,
            nextCursor.updatedAt!,
            cursorId: nextCursor.id,
          );
        });

        pulled += mapped.length;
        failed += pageFailed;
        skipped += pageSkipped;
        cursor = nextCursor;

        if (rows.length < pageSize) break;
      }

      // Soft-delete reconciliation, only after a clean pass.
      if (!partial) {
        deactivated = await _reconcileInactive(source, cursor, boundaryIso);
      }
    } catch (error) {
      partial = true;
      _addDiagnostic(diagnostics, 'sync aborted: ${error.runtimeType}');
      debugPrint('🌐 Content sync failed: $error');
    }

    if (skipped > 0) {
      _addDiagnostic(diagnostics, '$skipped row(s) skipped (unusable)');
    }

    debugPrint(
      '📦 Content sync: $pulled pulled, $failed failed, $skipped skipped, '
      '$deactivated deactivated, partial=$partial, cursor=$cursor',
    );

    return ContentSyncReport(
      pulled: pulled,
      failed: failed,
      watermark: cursor.updatedAt,
      partial: partial,
      deactivated: deactivated,
      diagnostics: diagnostics,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Paging
  // ─────────────────────────────────────────────────────────────

  /// Builds the cursor for the next page from a raw remote row.
  ///
  /// [boundary] is always non-null in practice: it falls back to the sync
  /// boundary (then to "now") when a row somehow lacks the column, so the cursor
  /// can never regress and re-pull the same page forever.
  static ContentSyncCursor _cursorFrom(
    Map<String, dynamic> row, [
    DateTime? boundary,
  ]) {
    final id = row['id']?.toString() ?? '';
    final updatedAt =
        parseUtcTimestamp(row['updated_at']) ??
        boundary ??
        DateTime.now().toUtc();
    return ContentSyncCursor(id: id, updatedAt: updatedAt);
  }

  // ─────────────────────────────────────────────────────────────
  // Row mapping
  // ─────────────────────────────────────────────────────────────

  /// Surrogate ids already present locally, keyed by local id. Populated once
  /// per page so the collision check is an in-memory lookup rather than one
  /// SELECT per row.
  ///
  /// Returns the map instead of storing it: as an instance field it was
  /// reassigned on every page, so concurrent [syncCatalog] runs overwrote each
  /// other and rows could be validated against the wrong map.
  Future<Map<String, String>> _loadExistingRemoteIds(
    List<String> candidateLocalIds,
  ) async {
    if (candidateLocalIds.isEmpty) return const {};
    final map = <String, String>{};
    for (var i = 0; i < candidateLocalIds.length; i += _lookupChunk) {
      final end = (i + _lookupChunk).clamp(0, candidateLocalIds.length);
      map.addAll(
        await _localDb.getRemoteIdMapForLocalIds(
          candidateLocalIds.sublist(i, end),
        ),
      );
    }
    return map;
  }

  /// Maps one remote row to a local companion.
  ///
  /// Returns `null` for rows that are *unusable* rather than erroneous: a
  /// missing id. Throws for rows that are malformed (no options) or that hit a
  /// surrogate collision — both are counted and reported by the caller so the
  /// run stays diagnosable without being fatal.
  db.QuestionsCompanion? _mapRow(
    Map<String, dynamic> row,
    Map<String, String> existingRemoteIds,
  ) {
    final remoteId = row['id']?.toString() ?? '';
    if (remoteId.isEmpty) return null;

    final options = encodeOptions(row['options']);
    if (options.isEmpty) {
      throw const FormatException(
        'options missing or empty — question would be ungradable',
      );
    }

    final localId = _remoteToLocalId(remoteId);
    final existingRemoteId = existingRemoteIds[localId];
    if (existingRemoteId != null && existingRemoteId != remoteId) {
      throw StateError(
        'surrogate collision for local key $localId '
        '($existingRemoteId vs $remoteId)',
      );
    }

    return db.QuestionsCompanion(
      id: Value(localId),
      subject: Value(_asString(row['subject'], fallback: 'General')),
      chapter: Value(
        _asString(row['chapter_name'], fallback: row['chapter_id']),
      ),
      topic: Value(_asString(row['topic_name'], fallback: 'General')),
      topicId: Value(_asString(row['topic_id'], fallback: row['chapter_id'])),
      questionText: Value(_asString(row['question_text'])),
      options: Value(options),
      correctAnswer: Value(_asString(row['correct_option']).toUpperCase()),
      explanation: _optionalRemoteValue(row['explanation']),
      ncertReference: _optionalRemoteValue(row['ncert_reference']),
      difficulty: Value(_asString(row['difficulty'], fallback: 'Medium')),
      imageUrl: Value(_nullableString(row['question_image_url'])),
      remoteId: Value(remoteId),
      updatedAt: Value(parseUtcTimestamp(row['updated_at'])),
      isActive: const Value(true),
      // NOTE: `tags`, `year` and `type` are intentionally omitted. They are
      // absent from the catalog, so writing them would clobber locally-generated
      // values (AI-written explanations, PYQ years) on every re-sync. Drift
      // leaves omitted columns untouched on both insert and conflict-update.
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Soft deletes
  // ─────────────────────────────────────────────────────────────

  /// Marks locally-synced questions inactive when the remote row is no longer
  /// active. Runs only after a clean pass.
  ///
  /// Deactivations newer than our cursor are skipped — the next delta run picks
  /// them up — so we never deactivate based on incomplete information.
  Future<int> _reconcileInactive(
    CatalogSource source,
    ContentSyncCursor cursor,
    String boundaryIso,
  ) async {
    try {
      // Paginate. The previous single uncursored call meant anything past
      // `limit` soft-deleted rows stayed active locally forever, silently.
      final inactiveIds = <String>[];
      var pageCursor = ContentSyncCursor.empty();
      while (true) {
        final response = await source.fetchInactive(
          cursor: pageCursor,
          boundaryIso: boundaryIso,
          limit: pageSize * 4,
        );
        if (response.isEmpty) break;

        for (final row in response) {
          final id = row['id']?.toString();
          if (id == null || id.isEmpty) continue;

          final updatedAt = parseUtcTimestamp(row['updated_at']);
          final cursorAt = cursor.updatedAt;
          if (cursorAt != null &&
              updatedAt != null &&
              updatedAt.isAfter(cursorAt)) {
            continue;
          }
          inactiveIds.add(id);
        }

        final last = response.last;
        // Advance by the row's own (updated_at, id); _cursorFrom falls back to
        // "now" when the row has no timestamp.
        final next = _cursorFrom(last);
        // Defensive: a source that returns a full page without advancing the
        // cursor would otherwise loop forever.
        if (next.id == pageCursor.id &&
            next.updatedAt == pageCursor.updatedAt) {
          break;
        }
        pageCursor = next;

        if (response.length < pageSize * 4) break;
      }

      if (inactiveIds.isEmpty) return 0;

      return await _localDb.deactivateQuestionsByRemoteIds(inactiveIds);
    } catch (error) {
      debugPrint('⚠️ Content sync soft-delete reconciliation skipped: $error');
      return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Cursor persistence
  // ─────────────────────────────────────────────────────────────

  /// Loads the persisted cursor.
  ///
  /// The tuple is stored across **two columns** — `lastSyncedAt` for the
  /// timestamp and `cursorId` for the remote id — so both must be read and
  /// composed here.
  ///
  /// ⚠️ An earlier version looked only at `cursorId`, expecting it to hold a
  /// pipe-joined `"<iso>|<uuid>"` string. Nothing ever wrote that form: the id
  /// went into its own column, so the lookup found a bare uuid, failed to parse
  /// it as a timestamp, and silently produced an *empty* cursor. Every
  /// subsequent run therefore re-pulled the entire catalog from the beginning,
  /// which is exactly the wasteful replay the tuple was introduced to prevent.
  Future<ContentSyncCursor> _loadCursor() async {
    final storedId = await _localDb.getSyncCursorId(_catalogTable);
    final storedAt = await _localDb.getLastSyncTimestamp(_catalogTable);

    if (storedAt == null) {
      return const ContentSyncCursor.empty();
    }

    return ContentSyncCursor(
      id: (storedId ?? '').trim(),
      updatedAt: storedAt.toUtc(),
    );
  }

  static void _addDiagnostic(List<String> sink, String message) {
    if (sink.length < _maxDiagnostics) sink.add(message);
    if (sink.length == _maxDiagnostics) sink.add('… more diagnostics dropped');
  }

  // ─────────────────────────────────────────────────────────────
  // Pure helpers
  // ─────────────────────────────────────────────────────────────

  /// Stable cross-platform mapping from a remote UUID to a positive 31-bit
  /// integer local id (FNV-1a).
  ///
  /// Deterministic, so bookmarks and attempts keep pointing at the same question
  /// across re-syncs. Collisions are reported, not thrown.
  static String _remoteToLocalId(String remoteId) {
    var hash = 0x811C9DC5;
    for (var i = 0; i < remoteId.length; i++) {
      hash ^= remoteId.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return (hash == 0 ? 1 : hash).toString();
  }

  /// Wraps an optional remote column so that **absent** stays absent.
  ///
  /// Writing `Value(null)` for a column the remote simply did not supply would
  /// erase any locally-held value on every re-sync. That matters most for
  /// `explanation`: rows can carry an AI-generated explanation written offline,
  /// and a catalog that has no editor-authored explanation for that question
  /// would otherwise silently wipe it.
  ///
  /// A *present* remote value still wins — that is the point of a catalog — so
  /// this only suppresses the null case, not real updates.
  static Value<String?> _optionalRemoteValue(dynamic value) {
    if (value == null) return const Value.absent();
    final text = value.toString();
    if (text.trim().isEmpty) return const Value.absent();
    return Value(text);
  }

  static String _asString(dynamic value, {dynamic fallback}) {
    final v = value?.toString();
    if (v == null || v.isEmpty) {
      return fallback?.toString() ?? '';
    }
    return v;
  }

  static String? _nullableString(dynamic value) {
    final v = value?.toString();
    return (v == null || v.isEmpty) ? null : v;
  }

  /// Parses a remote timestamp as **UTC**.
  ///
  /// The previous implementation returned `.toLocal()`, which was re-converted
  /// with `.toUtc()` at query time. That round-trip is DST-fragile and can shift
  /// the cursor by hours. Everything here is UTC end-to-end.
  static DateTime? parseUtcTimestamp(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse('$value');
    if (parsed == null) return null;
    if (parsed.isUtc) return parsed;
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  /// Encodes catalog options into the local `'A|||B|||C|||D'` format.
  ///
  /// The server declares `options JSONB` as an **object**
  /// (`{"A": "text", "B": "text", …}`). The previous implementation handled only
  /// `List` and `String`, so every real row decoded to a `Map`, fell through to
  /// the `else` branch, and stored an empty string — producing an ungradable
  /// question bank with no error surfaced anywhere. This was the single most
  /// severe defect in the catalog path.
  ///
  /// Supported shapes, in priority order:
  /// * `Map`  — `{"A": "…", "B": "…"}` (the actual catalog format)
  /// * `List` — `["…", "…"]`
  /// * `String` — already joined, or a single option
  ///
  /// Output is **positional and always ordered A→D**, because the local model
  /// identifies an answer by its option *letter* (`correct_option` is a
  /// `CHAR(1)`). A map is therefore sorted by key, never by insertion order —
  /// JSON object key order is not semantically meaningful.
  static String encodeOptions(dynamic raw) {
    final ordered = <String>[];

    void add(String? value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) ordered.add(text);
    }

    if (raw is Map) {
      final entries = raw.entries.toList()
        ..sort((a, b) {
          final rankA = _labelRank('${a.key}');
          final rankB = _labelRank('${b.key}');
          if (rankA != rankB) return rankA.compareTo(rankB);
          return 0;
        });
      for (final entry in entries) {
        add('${entry.value}');
      }
      return ordered.join('|||');
    }

    if (raw is List) {
      for (final value in raw) {
        add('$value');
      }
      return ordered.join('|||');
    }

    if (raw is String) {
      final text = raw.trim();
      return text.isEmpty ? '' : text;
    }

    return '';
  }

  /// Rank for an option label so A→D ordering is explicit and stable.
  static int _labelRank(String key) {
    final trimmed = key.trim();
    if (trimmed.length == 1) {
      final code = trimmed.codeUnitAt(0);
      if (code >= 65 && code <= 90) return code - 65; // A–Z
      if (code >= 97 && code <= 122) return code - 97; // a–z
    }
    final numeric = int.tryParse(trimmed);
    if (numeric != null) {
      // Treat "0" as A so both zero- and one-based numeric keys order sanely.
      return numeric >= 0 && numeric < 26 ? numeric : 99;
    }
    return 99;
  }
}
