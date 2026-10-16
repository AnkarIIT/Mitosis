import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/services/content_sync_service.dart';

/// In-memory [CatalogSource].
///
/// Backs the engine's delta algorithm without a network, which is what makes
/// pagination, per-row failure isolation, soft-delete propagation, mid-run
/// failure and duplicate prevention testable at all.
class FakeCatalogSource implements CatalogSource {
  /// Active rows, keyed by remote id.
  final Map<String, Map<String, dynamic>> active = {};

  /// Rows that have been deactivated remotely.
  final Map<String, Map<String, dynamic>> inactive = {};

  /// When set, the next `fetchPage` call throws. Used to simulate a network
  /// failure at an exact point in the run.
  Object? failNextPage;

  /// Fails once this many pages have been served. Lets a test break mid-run.
  int? failAfterPages;

  /// Rows served per page. The engine's real page size is
  /// [ContentSyncService.pageSize]; multi-page tests seed more rows than that so
  /// the fake honours its contract ("up to `limit` rows, fewer only on the final
  /// page") rather than lying to the engine.
  int pageCount = 0;

  /// Every cursor the engine asked for, in order, so cursor advancement can be
  /// asserted directly.
  final List<ContentSyncCursor> seenCursors = [];

  /// Every `limit` the engine requested.
  final List<int> seenLimits = [];

  void add({
    required String id,
    required DateTime updatedAt,
    bool isActive = true,
    Map<String, dynamic>? options,
    String? questionText,
    String? correctOption,
    String? subject,
    String? chapterId,
  }) {
    final row = <String, dynamic>{
      'id': id,
      'subject': subject ?? 'Physics',
      'chapter_id': chapterId ?? 'phy_01',
      'chapter_name': 'Mechanics',
      'topic_name': 'Newton',
      'question_text': questionText ?? 'Question $id?',
      // The real catalog publishes options as a JSONB *object*. Reproducing
      // that shape here is deliberate: the pre-fix decoder returned '' for it.
      'options':
          options ??
          <String, String>{
            'A': 'Alpha',
            'B': 'Beta',
            'C': 'Gamma',
            'D': 'Delta',
          },
      'correct_option': correctOption ?? 'A',
      'explanation': 'Because.',
      'difficulty': 'Medium',
      'is_active': isActive,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
    (isActive ? active : inactive)[id] = row;
  }

  /// Removes a row entirely from the fake (models a hard delete).
  void remove(String id) {
    active.remove(id);
    inactive.remove(id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPage({
    required ContentSyncCursor cursor,
    required String boundaryIso,
    required int limit,
  }) async {
    pageCount++;
    seenCursors.add(cursor);
    seenLimits.add(limit);

    final fail = failNextPage;
    if (fail != null) {
      failNextPage = null;
      throw fail;
    }
    if (failAfterPages != null && pageCount > failAfterPages!) {
      throw const CatalogFetchException('simulated mid-run failure');
    }

    final boundary = DateTime.parse(boundaryIso);

    // Ordered by (updated_at, id), strictly after the cursor, at or before the
    // boundary — the same contract SupabaseCatalogSource relies on the server
    // index for.
    final eligible =
        active.values.where((row) {
          final updatedAt = DateTime.parse(row['updated_at'] as String);
          if (updatedAt.isAfter(boundary)) return false;
          final cursorAt = cursor.updatedAt;
          if (cursorAt == null) return true;
          if (updatedAt.isAfter(cursorAt)) return true;
          if (updatedAt.isBefore(cursorAt)) return false;
          // Same timestamp: fall through to the id tie-break. This is exactly the
          // case a timestamp-only watermark loses.
          return (row['id'] as String).compareTo(cursor.id) > 0;
        }).toList()..sort((a, b) {
          final ta = DateTime.parse(a['updated_at'] as String);
          final tb = DateTime.parse(b['updated_at'] as String);
          final byTime = ta.compareTo(tb);
          return byTime != 0
              ? byTime
              : (a['id'] as String).compareTo(b['id'] as String);
        });

    return eligible.take(limit).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchInactive({
    required ContentSyncCursor cursor,
    required String boundaryIso,
    required int limit,
  }) async {
    final boundary = DateTime.parse(boundaryIso);
    final cursorIso = cursor.updatedAt?.toUtc().toIso8601String();
    final eligible =
        inactive.values.where((row) {
          final updatedAt = DateTime.parse(row['updated_at'] as String);
          if (updatedAt.isAfter(boundary)) return false;
          if (cursorIso == null) return true;
          final iso = updatedAt.toUtc().toIso8601String();
          if (iso == cursorIso) {
            return (row['id'] as String).compareTo(cursor.id) > 0;
          }
          return iso.compareTo(cursorIso) > 0;
        }).toList()..sort((a, b) {
          final at = (a['updated_at'] as String).compareTo(
            b['updated_at'] as String,
          );
          if (at != 0) return at;
          return (a['id'] as String).compareTo(b['id'] as String);
        });
    return eligible.take(limit).toList();
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// Every stored question, ordered by local id for stable comparison.
  Future<List<dynamic>> allQuestions() async {
    final rows = await db.select(db.questions).get();
    rows.sort((a, b) => a.id.compareTo(b.id));
    return rows;
  }

  group('First sync from an empty local database', () {
    test('pulls the whole catalog and stores usable questions', () async {
      final source = FakeCatalogSource();
      for (var i = 0; i < 5; i++) {
        source.add(
          id: 'remote-$i',
          updatedAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
        );
      }

      final report = await ContentSyncService.withSource(
        db,
        source,
      ).syncCatalog();

      expect(report.pulled, 5);
      expect(report.failed, 0);
      expect(report.partial, isFalse);
      expect(report.isClean, isTrue);

      final stored = await allQuestions();
      expect(stored.length, 5);

      // The decisive assertion: options must survive. The pre-fix decoder
      // returned '' for the catalog's JSONB object shape, which produced a
      // question bank where nothing could be graded.
      for (final q in stored) {
        expect(
          q.options,
          isNotEmpty,
          reason: 'question ${q.id} lost its options',
        );
        expect(q.options.split('|||').length, 4);
        expect(q.correctAnswer, 'A');
      }
    });

    test('decodes the JSONB options object in A→D order', () async {
      final source = FakeCatalogSource();
      source.add(
        id: 'remote-order',
        updatedAt: DateTime.utc(2026, 1, 1),
        options: {'D': 'Delta', 'B': 'Beta', 'A': 'Alpha', 'C': 'Gamma'},
      );

      await ContentSyncService.withSource(db, source).syncCatalog();

      final stored = await allQuestions();
      expect(stored.single.options, 'Alpha|||Beta|||Gamma|||Delta');
    });

    test('records the remote uuid alongside a local surrogate key', () async {
      final source = FakeCatalogSource();
      source.add(id: 'remote-abc', updatedAt: DateTime.utc(2026, 1, 1));

      await ContentSyncService.withSource(db, source).syncCatalog();

      final stored = await allQuestions();
      // Local primary key is the derived surrogate; the authoritative remote id
      // is preserved verbatim so bookmarks and attempts keep resolving.
      expect(stored.single.remoteId, 'remote-abc');
      expect(stored.single.id, isNot('remote-abc'));
      expect(int.tryParse(stored.single.id), isNotNull);
    });
  });

  group('Cursor pagination', () {
    test('requests pages of the configured size', () async {
      final source = FakeCatalogSource();
      for (var i = 0; i < 3; i++) {
        source.add(
          id: 'remote-$i',
          updatedAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
        );
      }

      await ContentSyncService.withSource(db, source).syncCatalog();

      expect(source.seenLimits, everyElement(ContentSyncService.pageSize));
      // Three rows fit in one page; `rows.length < pageSize` ends the loop
      // without a second fetch.
      expect(source.pageCount, 1);
    });

    test('walks multiple pages when a page is full', () async {
      final source = FakeCatalogSource();
      // One row more than a full page, so a second fetch is required. Using
      // pageSize+1 (rather than shrinking the page) keeps the fake honest: the
      // engine decides a run is finished by comparing the returned row count to
      // the limit it asked for.
      final total = ContentSyncService.pageSize + 1;
      for (var i = 0; i < total; i++) {
        source.add(
          id: 'remote-${i.toString().padLeft(6, '0')}',
          updatedAt: DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
        );
      }

      final report = await ContentSyncService.withSource(
        db,
        source,
      ).syncCatalog();

      expect(report.pulled, total);
      // Page 1 is full (so the engine does not stop), page 2 holds the single
      // remainder and ends the loop.
      expect(source.pageCount, 2);
      expect((await allQuestions()).length, total);
      // The cursor handed to the second fetch must already point at the last
      // row of page 1.
      expect(source.seenCursors.first.id, isEmpty);
      expect(
        source.seenCursors[1].id,
        'remote-${(ContentSyncService.pageSize - 1).toString().padLeft(6, '0')}',
      );
    });

    test('does not re-pull rows it has already stored', () async {
      final source = FakeCatalogSource();
      source.add(id: 'remote-1', updatedAt: DateTime.utc(2026, 1, 1));
      source.add(id: 'remote-2', updatedAt: DateTime.utc(2026, 1, 2));

      final service = ContentSyncService.withSource(db, source);
      await service.syncCatalog();
      expect((await allQuestions()).length, 2);

      // Second run with nothing new: no writes, no duplicates.
      final second = await service.syncCatalog();
      expect(second.pulled, 0);
      expect((await allQuestions()).length, 2);
    });

    test('preserves rows that share an updated_at timestamp', () async {
      // The exact failure a timestamp-only watermark produces: the boundary row
      // sets the watermark, and the next run's strict `gt` skips everything
      // stamped identically.
      final source = FakeCatalogSource();
      final shared = DateTime.utc(2026, 1, 1, 12);
      for (final id in ['remote-a', 'remote-b', 'remote-c']) {
        source.add(id: id, updatedAt: shared);
      }

      final service = ContentSyncService.withSource(db, source);
      await service.syncCatalog();

      expect((await allQuestions()).length, 3);
      // All three must be readable by their remote id afterwards.
      for (final id in ['remote-a', 'remote-b', 'remote-c']) {
        expect(source.active.containsKey(id), isTrue);
      }
    });

    test('the persisted cursor advances past the last row', () async {
      final source = FakeCatalogSource();
      source.add(id: 'remote-1', updatedAt: DateTime.utc(2026, 1, 1));
      source.add(id: 'remote-2', updatedAt: DateTime.utc(2026, 1, 2));

      await ContentSyncService.withSource(db, source).syncCatalog();

      final cursorId = await db.getSyncCursorId('questions');
      expect(cursorId, 'remote-2');
      expect(
        await db.getLastSyncTimestamp('questions'),
        DateTime.utc(2026, 1, 2),
      );
    });
  });

  group('Duplicate prevention', () {
    test('re-syncing an unchanged row updates in place, not twice', () async {
      final source = FakeCatalogSource();
      source.add(id: 'remote-1', updatedAt: DateTime.utc(2026, 1, 1));
      final service = ContentSyncService.withSource(db, source);
      await service.syncCatalog();

      // Same id, new updated_at → the delta should pick it up as an update.
      source.add(
        id: 'remote-1',
        updatedAt: DateTime.utc(2026, 1, 5),
        questionText: 'Revised question',
      );
      await service.syncCatalog();

      final stored = await allQuestions();
      expect(stored.length, 1);
      expect(stored.single.questionText, 'Revised question');
    });

    test('two distinct remote ids never collapse into one local row', () async {
      final source = FakeCatalogSource();
      source.add(id: 'remote-1', updatedAt: DateTime.utc(2026, 1, 1));
      source.add(id: 'remote-2', updatedAt: DateTime.utc(2026, 1, 2));

      await ContentSyncService.withSource(db, source).syncCatalog();

      final stored = await allQuestions();
      expect(stored.length, 2);
      expect(stored.map((q) => q.remoteId).toSet().length, 2);
    });
  });

  group('Per-row failure isolation', () {
    test('a row with no options is skipped, the rest still sync', () async {
      final source = FakeCatalogSource();
      source.add(id: 'good-1', updatedAt: DateTime.utc(2026, 1, 1));
      source.add(
        id: 'bad-1',
        updatedAt: DateTime.utc(2026, 1, 2),
        options: <String, dynamic>{},
      );
      source.add(id: 'good-2', updatedAt: DateTime.utc(2026, 1, 3));

      final report = await ContentSyncService.withSource(
        db,
        source,
      ).syncCatalog();

      // The bad row must not abort the run.
      expect(report.partial, isFalse);
      expect(report.failed, greaterThan(0));
      expect(report.pulled, 2);

      final stored = await allQuestions();
      expect(stored.length, 2);
      expect(stored.every((q) => q.options.isNotEmpty), isTrue);
    });

    test('a row missing an id is skipped without failing the run', () async {
      final source = FakeCatalogSource();
      source.add(id: 'good-1', updatedAt: DateTime.utc(2026, 1, 1));
      // A row whose id is the empty string cannot be keyed.
      source.active[''] = {
        'id': '',
        'subject': 'Physics',
        'question_text': 'Nameless',
        'options': {'A': 'a'},
        'correct_option': 'A',
        'updated_at': DateTime.utc(2026, 1, 2).toIso8601String(),
        'is_active': true,
      };

      final report = await ContentSyncService.withSource(
        db,
        source,
      ).syncCatalog();

      expect(report.partial, isFalse);
      expect(report.pulled, 1);
    });
  });

  group('Retry after a network failure', () {
    test(
      'a failure on the first page reports partial and writes nothing',
      () async {
        final source = FakeCatalogSource();
        source.add(id: 'remote-1', updatedAt: DateTime.utc(2026, 1, 1));
        source.failNextPage = const CatalogFetchException('connection reset');

        final report = await ContentSyncService.withSource(
          db,
          source,
        ).syncCatalog();

        expect(report.partial, isTrue);
        expect(report.isClean, isFalse);
        expect(report.pulled, 0);
        expect(await allQuestions(), isEmpty);
        expect(report.diagnostics.join(), contains('CatalogFetchException'));
      },
    );

    test('a mid-run failure keeps already-committed pages and advances the '
        'cursor to the last durable page', () async {
      final source = FakeCatalogSource();
      // Two full pages, so the break lands *between* committed pages.
      final total = ContentSyncService.pageSize + 1;
      for (var i = 0; i < total; i++) {
        source.add(
          id: 'remote-${i.toString().padLeft(6, '0')}',
          updatedAt: DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
        );
      }
      // Page 1 is served and committed; the fetch for page 2 throws.
      source.failAfterPages = 1;

      final report = await ContentSyncService.withSource(
        db,
        source,
      ).syncCatalog();

      expect(report.partial, isTrue);
      expect(report.pulled, ContentSyncService.pageSize);
      expect((await allQuestions()).length, ContentSyncService.pageSize);
      // The cursor must point at the last durable row, not the original one,
      // so the next run resumes rather than replaying the whole catalog.
      expect(
        await db.getSyncCursorId('questions'),
        'remote-${(ContentSyncService.pageSize - 1).toString().padLeft(6, '0')}',
      );
    });

    test('the next run after a failure resumes and completes', () async {
      final source = FakeCatalogSource();
      for (var i = 0; i < 3; i++) {
        source.add(
          id: 'remote-$i',
          updatedAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
        );
      }
      final service = ContentSyncService.withSource(db, source);

      source.failNextPage = const CatalogFetchException('timeout');
      final first = await service.syncCatalog();
      expect(first.partial, isTrue);

      // No failure injected now.
      final second = await service.syncCatalog();
      expect(second.partial, isFalse);
      expect((await allQuestions()).length, 3);
    });
  });

  group('Soft deletion propagation', () {
    test('a row deactivated remotely is deactivated locally', () async {
      final source = FakeCatalogSource();
      final updatedAt = DateTime.utc(2026, 1, 1);
      source.add(id: 'remote-1', updatedAt: updatedAt);
      source.add(
        id: 'remote-2',
        updatedAt: updatedAt.add(const Duration(days: 1)),
      );

      final service = ContentSyncService.withSource(db, source);
      await service.syncCatalog();
      expect((await allQuestions()).every((q) => q.isActive), isTrue);

      // Remote deactivates remote-1 *without* touching updated_at, which is
      // how a reconciliation-only change arrives.
      final row = source.active.remove('remote-1')!;
      source.inactive['remote-1'] = {
        'id': 'remote-1',
        'updated_at': row['updated_at'],
        'is_active': false,
      };

      final report = await service.syncCatalog();

      expect(report.deactivated, 1);
      final stored = await allQuestions();
      final byRemote = {for (final q in stored) q.remoteId: q};
      expect(byRemote['remote-1']!.isActive, isFalse);
      expect(byRemote['remote-2']!.isActive, isTrue);
    });

    test('bundled questions without a remoteId are never deactivated', () async {
      // The shared catalog is not user- or sync-owned; reconciliation must not
      // touch it.
      await db
          .into(db.questions)
          .insert(
            QuestionsCompanion.insert(
              id: 'bundled_1',
              subject: 'Physics',
              chapter: 'Mechanics',
              topic: 'Newton',
              questionText: 'Bundled',
              options: 'A|||B',
              correctAnswer: 'A',
              topicId: const Value('phy_01'),
              difficulty: const Value('Easy'),
              tags: const Value(''),
              type: const Value('mcq'),
            ),
          );

      final source = FakeCatalogSource();
      source.add(id: 'remote-1', updatedAt: DateTime.utc(2026, 1, 1));
      await ContentSyncService.withSource(db, source).syncCatalog();

      final stored = await allQuestions();
      expect(stored.firstWhere((q) => q.id == 'bundled_1').isActive, isTrue);
    });

    test('a partial run does not deactivate anything', () async {
      // The critical safety property: an incomplete catalog must never hide
      // valid content.
      final source = FakeCatalogSource();
      source.add(id: 'remote-1', updatedAt: DateTime.utc(2026, 1, 1));
      final service = ContentSyncService.withSource(db, source);
      await service.syncCatalog();

      final row = source.active.remove('remote-1')!;
      source.inactive['remote-1'] = {
        'id': 'remote-1',
        'updated_at': row['updated_at'],
        'is_active': false,
      };

      source.failNextPage = const CatalogFetchException('flaky');
      final report = await service.syncCatalog();

      expect(report.partial, isTrue);
      expect(report.deactivated, 0);
      final stored = await allQuestions();
      expect(stored.single.isActive, isTrue);
    });

    test(
      'a deactivation newer than the cursor is deferred, not applied',
      () async {
        final source = FakeCatalogSource();
        source.add(id: 'remote-1', updatedAt: DateTime.utc(2026, 1, 1));
        final service = ContentSyncService.withSource(db, source);
        await service.syncCatalog();

        // Deactivation stamped *after* the cursor is not yet trustworthy.
        source.inactive['remote-1'] = {
          'id': 'remote-1',
          'updated_at': DateTime.utc(2030, 1, 1).toIso8601String(),
          'is_active': false,
        };

        final report = await service.syncCatalog();

        expect(report.deactivated, 0);
        expect((await allQuestions()).single.isActive, isTrue);
      },
    );
  });

  group('Configuration guard', () {
    test('a null source is a no-op, not a crash', () async {
      final report = await ContentSyncService.withSource(
        db,
        null,
      ).syncCatalog();

      expect(report.pulled, 0);
      expect(report.partial, isFalse);
    });
  });

  group('Diagnostics', () {
    test('failures are reported and bounded', () async {
      final source = FakeCatalogSource();
      for (var i = 0; i < 40; i++) {
        source.add(
          id: 'bad-$i',
          updatedAt: DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
          options: <String, dynamic>{'A': ''},
        );
      }

      final report = await ContentSyncService.withSource(
        db,
        source,
      ).syncCatalog();

      expect(report.failed, 40);
      expect(report.diagnostics, isNotEmpty);
      // Bounded so a pathological payload cannot grow the report without limit.
      expect(report.diagnostics.length, lessThanOrEqualTo(30));
    });
  });

  group('Offline edits then reconnect', () {
    test(
      'a locally generated explanation survives a re-sync that has none',
      () async {
        final source = FakeCatalogSource();
        // Catalog row with NO explanation, as an un-edited question would be.
        source.add(id: 'remote-1', updatedAt: DateTime.utc(2026, 1, 1));
        source.active['remote-1']!.remove('explanation');

        final service = ContentSyncService.withSource(db, source);
        await service.syncCatalog();

        // Simulate an offline, locally generated explanation.
        final stored = await allQuestions();
        final localId = stored.single.id;
        await (db.update(
          db.questions,
        )..where((t) => t.id.equals(localId))).write(
          QuestionsCompanion(explanation: const Value('Locally written.')),
        );

        // A remote edit re-pulls the row. Writing `Value(null)` for the absent
        // explanation would silently destroy the local one on every sync.
        source.add(
          id: 'remote-1',
          updatedAt: DateTime.utc(2026, 2, 1),
          questionText: 'Updated remotely',
        );
        source.active['remote-1']!.remove('explanation');
        await service.syncCatalog();

        final after = await allQuestions();
        expect(after.single.questionText, 'Updated remotely');
        expect(
          after.single.explanation,
          'Locally written.',
          reason:
              'a remote row without an explanation must not clobber a local one',
        );
      },
    );

    test('a remote explanation does overwrite the local one', () async {
      final source = FakeCatalogSource();
      source.add(id: 'remote-1', updatedAt: DateTime.utc(2026, 1, 1));
      source.active['remote-1']!.remove('explanation');

      final service = ContentSyncService.withSource(db, source);
      await service.syncCatalog();

      final stored = await allQuestions();
      final localId = stored.single.id;
      await (db.update(db.questions)..where((t) => t.id.equals(localId))).write(
        QuestionsCompanion(explanation: const Value('Stale local copy.')),
      );

      // An editor-authored explanation on the remote is authoritative.
      source.add(id: 'remote-1', updatedAt: DateTime.utc(2026, 2, 1));
      source.active['remote-1']!['explanation'] = 'Official explanation.';

      await service.syncCatalog();

      expect(
        (await allQuestions()).single.explanation,
        'Official explanation.',
      );
    });
  });
}
