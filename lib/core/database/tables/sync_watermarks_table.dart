import 'package:drift/drift.dart';

/// Tracks the last successful delta-sync timestamp per remote table so the
/// next `ContentSyncService.syncCatalog()` only fetches changed rows.
class SyncWatermarks extends Table {
  TextColumn get remoteTable => text()();
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {remoteTable};
}