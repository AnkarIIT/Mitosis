import 'package:drift/drift.dart';

/// Tracks sync progress per remote table.
///
/// [lastSyncedAt] is the timestamp component of the delta cursor and is kept as
/// its own column so progress is inspectable without parsing.
///
/// [cursorId] is the id component. A timestamp-only watermark is lossy: the
/// next query uses a strict `gt`, so every row sharing the exact watermark
/// timestamp is skipped forever. Storing the `(timestamp, id)` tuple makes the
/// cursor total-ordered and removes that entire failure class.
class SyncWatermarks extends Table {
  TextColumn get remoteTable => text()();
  DateTimeColumn get lastSyncedAt => dateTime()();

  /// Remote-id component of the delta cursor — the last row's `id` for the
  /// table. Null on rows written by older builds, which are treated as a
  /// timestamp-only cursor (safe: the first run after upgrade re-reads the
  /// boundary rows).
  TextColumn get cursorId => text().nullable()();

  @override
  Set<Column> get primaryKey => {remoteTable};
}
