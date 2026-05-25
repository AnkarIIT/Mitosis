import 'package:drift/drift.dart';

QueryExecutor connect() {
  return LazyDatabase(() async {
    throw UnsupportedError('Web is not supported for sqlite3 database');
  });
}
