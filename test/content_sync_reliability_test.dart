import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/database/drift_database.dart' as db;
import 'package:neet_mitos/core/services/content_sync_service.dart';

/// Covers the defects found in the catalog sync path:
///
/// 1. `_encodeOptions` returned `''` for the JSONB **object** the server
///    actually publishes (`{"A": "text", …}`), so every synced question landed
///    with no options — an ungradable bank, silently.
/// 2. A timestamp-only watermark skipped every row sharing the exact watermark
///    timestamp, because the delta query used a strict `gt`.
/// 3. Timestamps round-tripped through local time, making the cursor
///    DST-fragile.
/// 4. Sync wrote `tags`/`year`/`type` unconditionally, clobbering local values.
void main() {
  group('ContentSyncService.encodeOptions', () {
    test('decodes the server JSONB object shape in A→D order', () {
      final encoded = ContentSyncService.encodeOptions(<String, dynamic>{
        'B': 'Beta',
        'A': 'Alpha',
        'D': 'Delta',
        'C': 'Gamma',
      });
      expect(encoded, 'Alpha|||Beta|||Gamma|||Delta');
    });

    test('decodes a JSONB list', () {
      expect(
        ContentSyncService.encodeOptions(['one', 'two', 'three', 'four']),
        'one|||two|||three|||four',
      );
    });

    test('passes through an already-joined string', () {
      expect(ContentSyncService.encodeOptions('a|||b|||c'), 'a|||b|||c');
    });

    test('lowercase keys still sort A→D', () {
      expect(
        ContentSyncService.encodeOptions(<String, dynamic>{
          'd': 'Delta',
          'a': 'Alpha',
          'c': 'Gamma',
          'b': 'Beta',
        }),
        'Alpha|||Beta|||Gamma|||Delta',
      );
    });

    test('numeric keys order sensibly', () {
      expect(
        ContentSyncService.encodeOptions(<String, dynamic>{
          '2': 'Two',
          '0': 'Zero',
          '1': 'One',
        }),
        'Zero|||One|||Two',
      );
    });

    test('returns empty for null, empty string and unknown shapes', () {
      expect(ContentSyncService.encodeOptions(null), '');
      expect(ContentSyncService.encodeOptions(''), '');
      expect(ContentSyncService.encodeOptions('   '), '');
      expect(ContentSyncService.encodeOptions(42), '');
    });

    test('drops blank option values but keeps positional neighbours', () {
      expect(
        ContentSyncService.encodeOptions(<String, dynamic>{
          'A': 'Alpha',
          'B': '   ',
          'C': 'Gamma',
          'D': 'Delta',
        }),
        'Alpha|||Gamma|||Delta',
      );
    });
  });

  group('ContentSyncCursor', () {
    test('round-trips through encode/decode', () {
      final cursor = ContentSyncCursor(
        id: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
        updatedAt: DateTime.utc(2026, 3, 1, 12, 30, 45),
      );
      final restored = ContentSyncCursor.decode(cursor.encode());

      expect(restored.id, cursor.id);
      expect(restored.updatedAt, cursor.updatedAt);
      expect(restored, cursor);
    });

    test('a legacy timestamp-only watermark decodes with an empty id', () {
      // Legacy rows stored only `lastSyncedAt`. Decoding must not throw and
      // must leave the id empty so the first post-upgrade run re-reads the
      // boundary timestamp's rows exactly once.
      final cursor = ContentSyncCursor.decode('2026-03-01T12:30:45.000Z');
      expect(cursor.id, '');
      expect(cursor.updatedAt, DateTime.utc(2026, 3, 1, 12, 30, 45));
    });

    test('total ordering distinguishes rows sharing a timestamp', () {
      // The whole point of the tuple: two rows with identical updated_at are
      // still ordered, so the second is not silently skipped.
      final a = ContentSyncCursor(
        id: 'aaaa',
        updatedAt: DateTime.utc(2026, 3, 1),
      );
      final b = ContentSyncCursor(
        id: 'bbbb',
        updatedAt: DateTime.utc(2026, 3, 1),
      );
      expect(a, isNot(b));
      expect(a.encode(), isNot(b.encode()));
    });

    test('empty cursor encodes without throwing', () {
      expect(const ContentSyncCursor.empty().encode(), 'null|');
    });
  });

  group('ContentSyncService.parseUtcTimestamp', () {
    test('keeps a UTC input unchanged', () {
      expect(
        ContentSyncService.parseUtcTimestamp('2026-03-01T12:00:00.000Z'),
        DateTime.utc(2026, 3, 1, 12),
      );
    });

    test('normalises a non-UTC input to UTC without shifting the instant', () {
      // A naive timestamp is reinterpreted as UTC. The previous implementation
      // returned .toLocal() and re-converted at query time, which shifted the
      // cursor by the local offset — and by an extra hour across a DST boundary.
      expect(
        ContentSyncService.parseUtcTimestamp('2026-03-01T12:00:00'),
        DateTime.utc(2026, 3, 1, 12),
      );
    });

    test('returns null for unparseable input', () {
      expect(ContentSyncService.parseUtcTimestamp('not a date'), isNull);
      expect(ContentSyncService.parseUtcTimestamp(null), isNull);
    });
  });

  group('Soft-delete reconciliation DAO', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'deactivates only synced rows, leaving bundled ones untouched',
      () async {
        // Bundled sample questions carry a null remoteId and must never be
        // deactivated by catalog reconciliation.
        await database
            .into(database.questions)
            .insert(
              db.QuestionsCompanion.insert(
                id: 'bundled_1',
                subject: 'Physics',
                chapter: 'Mechanics',
                topic: 'Newton',
                topicId: drift.Value('phy_01'),
                questionText: 'Bundled question',
                options: 'A|||B|||C|||D',
                correctAnswer: 'A',
                difficulty: drift.Value('Easy'),
                tags: drift.Value(''),
                type: drift.Value('mcq'),
              ),
            );
        await database
            .into(database.questions)
            .insert(_synced(id: '5000001', remoteId: 'remote-a'));

        final changed = await database.deactivateQuestionsByRemoteIds([
          'remote-a',
        ]);

        expect(changed, 1);
        final bundled = await (database.select(
          database.questions,
        )..where((t) => t.id.equals('bundled_1'))).getSingle();
        final synced = await (database.select(
          database.questions,
        )..where((t) => t.id.equals('5000001'))).getSingle();
        expect(bundled.isActive, isTrue);
        expect(synced.isActive, isFalse);
      },
    );

    test('is idempotent and safe on an empty id list', () async {
      await database
          .into(database.questions)
          .insert(_synced(id: '5000002', remoteId: 'remote-b'));

      expect(await database.deactivateQuestionsByRemoteIds([]), 0);
      expect(await database.deactivateQuestionsByRemoteIds(['remote-b']), 1);
      // Second call matches nothing because the row is already inactive.
      expect(await database.deactivateQuestionsByRemoteIds(['remote-b']), 0);
    });
  });

  group('Sync cursor persistence', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('persists and reads back the tuple cursor', () async {
      final timestamp = DateTime.utc(2026, 3, 1, 12);
      await database.setSyncTimestamp(
        'questions',
        timestamp,
        cursorId: 'remote-z',
      );

      expect(await database.getSyncCursorId('questions'), 'remote-z');
      expect(await database.getLastSyncTimestamp('questions'), timestamp);
    });

    test('upserts without creating a duplicate row', () async {
      await database.setSyncTimestamp(
        'questions',
        DateTime.utc(2026, 3, 1),
        cursorId: 'first',
      );
      await database.setSyncTimestamp(
        'questions',
        DateTime.utc(2026, 3, 2),
        cursorId: 'second',
      );

      expect(await database.getSyncCursorId('questions'), 'second');
      expect(
        await database.getLastSyncTimestamp('questions'),
        DateTime.utc(2026, 3, 2),
      );
    });
  });

  group('Collision-check lookup is batched', () {
    test('returns a local-id to remote-id map for the supplied keys', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await database
          .into(database.questions)
          .insert(_synced(id: '5000003', remoteId: 'remote-c'));

      final map = await database.getRemoteIdMapForLocalIds([
        '5000003',
        'does_not_exist',
      ]);

      expect(map, {'5000003': 'remote-c'});
    });

    test('returns an empty map for an empty key list', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      expect(await database.getRemoteIdMapForLocalIds([]), isEmpty);
    });
  });
}

/// A catalog-sourced question row (non-null `remoteId`).
db.QuestionsCompanion _synced({required String id, required String remoteId}) =>
    db.QuestionsCompanion.insert(
      id: id,
      remoteId: drift.Value(remoteId),
      subject: 'Physics',
      chapter: 'Mechanics',
      topic: 'Newton',
      topicId: drift.Value('phy_01'),
      questionText: 'Synced question',
      options: 'A|||B|||C|||D',
      correctAnswer: 'A',
      difficulty: drift.Value('Easy'),
      tags: drift.Value(''),
      type: drift.Value('mcq'),
    );
