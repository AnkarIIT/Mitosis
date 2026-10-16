import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/services/ncert_book_catalog.dart';

void main() {
  test('NCERT catalog contains unique, bundled chapter assets', () {
    final entries = NcertBookCatalog.allEntries;
    final paths = entries.map((entry) => entry.assetPath).toSet();

    expect(entries.length, greaterThan(70));
    expect(paths.length, entries.length);
    for (final entry in entries) {
      expect(
        File(entry.assetPath).existsSync(),
        isTrue,
        reason: entry.assetPath,
      );
    }
  });

  test('invalid resource identifiers do not resolve to another chapter', () {
    expect(NcertBookCatalog.entryByChapterKey('missing-resource'), isNull);
  });
}
