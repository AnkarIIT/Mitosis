import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/drift_database.dart' as db;

/// Pulls the published content catalog (questions) from Supabase into the
/// local Drift store so the NTA test engine can run 100% offline.
///
/// Integration design: remote rows are upserted into the existing
/// [db.Questions] table keyed by a stable positive-int id derived from the
/// remote UUID. The raw UUID is preserved in `remoteId` for reconciliation and
/// deduplication. Bundled sample questions keep `remoteId = null` and are never
/// touched by sync.
class ContentSyncService {
  static const _catalogTable = 'questions';

  final db.AppDatabase _localDb;
  final SupabaseClient? _supabase;

  ContentSyncService(this._localDb, [this._supabase]);

  /// Pulls delta rows (updated since the local watermark) plus a lightweight
  /// reconcile that deactivates local rows whose remote record is no longer
  /// active on the server.
  Future<void> syncCatalog() async {
    final client = _supabase;
    if (client == null) return;

    try {
      final watermark = await _localDb.getLastSyncTimestamp(_catalogTable);

      var query = client.from(_catalogTable).select().eq('is_active', true);
      if (watermark != null) {
        query = query.gt('updated_at', watermark.toUtc().toIso8601String());
      }

      final response = await query;
      final rows = List<Map<String, dynamic>>.from(response);

      if (rows.isNotEmpty) {
        await _upsertRows(rows, watermark);
        debugPrint('✅ Content sync pulled ${rows.length} catalog rows');
      }

      await _reconcileActiveSet(client);
    } catch (e) {
      // Offline / network failure: fall back to the local Drift store.
      debugPrint('🌐 Content sync skipped (offline or unconfigured): $e');
    }
  }

  Future<void> _upsertRows(
    List<Map<String, dynamic>> rows,
    DateTime? previousWatermark,
  ) async {
    final companions = <db.QuestionsCompanion>[];
    DateTime? latest = previousWatermark;

    for (final row in rows) {
      final remoteId = row['id']?.toString() ?? '';
      if (remoteId.isEmpty) continue;

      final imageUrl = row['question_image_url']?.toString();
      final updatedAt = _parseDate(row['updated_at']);

      companions.add(
        db.QuestionsCompanion(
          id: Value(_remoteToLocalId(remoteId).toString()),
          subject: Value(_asString(row['subject'])),
          chapter: Value(
            _asString(row['chapter_name'], fallback: row['chapter_id']),
          ),
          topic: Value(_asString(row['topic_name'])),
          topicId: Value(_asString(row['chapter_id'])),
          questionText: Value(_asString(row['question_text'])),
          options: Value(_encodeOptions(row['options'])),
          correctAnswer: Value(_asString(row['correct_option'])),
          explanation: Value(_nullableString(row['explanation'])),
          ncertReference: Value(_nullableString(row['ncert_reference'])),
          difficulty: Value(_asString(row['difficulty'], fallback: 'Medium')),
          tags: const Value(''),
          year: const Value(null),
          imageUrl: Value(
            imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
          ),
          type: const Value('mcq'),
          remoteId: Value(remoteId),
          updatedAt: Value(updatedAt),
          isActive: const Value(true),
        ),
      );

      if (updatedAt != null && (latest == null || updatedAt.isAfter(latest))) {
        latest = updatedAt;
      }
    }

    if (companions.isEmpty) return;

    await _localDb.batch((batch) {
      batch.insertAllOnConflictUpdate(_localDb.questions, companions);
    });

    if (latest != null) {
      await _localDb.setSyncTimestamp(_catalogTable, latest);
    }
  }

  /// Sets `is_active = false` locally for any remote-sourced row whose UUID is
  /// no longer returned as active by the server (removed or soft-disabled).
  Future<void> _reconcileActiveSet(SupabaseClient client) async {
    try {
      final active = await client
          .from(_catalogTable)
          .select('id')
          .eq('is_active', true);
      final activeLocalIds = active
          .map((r) => _remoteToLocalId(r['id'].toString()))
          .toSet();
      final localRemoteIds = await _localDb.getRemoteQuestionLocalIds();

      for (final localId in localRemoteIds) {
        if (!activeLocalIds.contains(localId)) {
          await (_localDb.update(_localDb.questions)
                ..where((t) => t.id.equals(localId)))
              .write(db.QuestionsCompanion(isActive: Value(false)));
        }
      }
    } catch (e) {
      debugPrint('Content sync reconcile skipped: $e');
    }
  }

  /// Stable cross-platform mapping from a remote UUID to a positive 31-bit
  /// integer local id (FNV-1a). Deterministic so bookmarks/attempts keep
  /// pointing at the same question across re-syncs.
  static String _remoteToLocalId(String remoteId) {
    var hash = 0x811C9DC5;
    for (var i = 0; i < remoteId.length; i++) {
      hash ^= remoteId.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return (hash == 0 ? 1 : hash).toString();
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

  static DateTime? _parseDate(dynamic value) =>
      DateTime.tryParse('$value')?.toLocal();

  /// Accepts either a native JSONB list ([...]) or a pre-joined '|||' string.
  static String _encodeOptions(dynamic raw) {
    if (raw is List) {
      return raw.map((o) => o.toString()).join('|||');
    }
    if (raw is String) {
      return raw;
    }
    return '';
  }
}
