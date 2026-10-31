import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/services/pyq_pdf_downloader_service.dart';

/// `downloadPdf` writes the HTTP body straight to `neet_<year>.pdf`. Article
/// pages therefore used to be "downloaded" as broken PDFs.
void main() {
  group('PYQ PDF sources', () {
    test('every source is a direct PDF, not an article page', () {
      final offenders = PyqPdfDownloaderService.neetPdfSources
          .where((s) => !s.url.toLowerCase().contains('.pdf'))
          .map((s) => '${s.year}: ${s.url}')
          .toList();
      expect(offenders, isEmpty);
    });

    test('years are unique', () {
      final years =
          PyqPdfDownloaderService.neetPdfSources.map((s) => s.year).toList();
      expect(years.toSet().length, years.length);
    });

    test('isOfficial is only claimed for government-hosted files', () {
      for (final source in PyqPdfDownloaderService.neetPdfSources) {
        if (source.isOfficial) {
          expect(
            source.url,
            contains('gov.in'),
            reason: '${source.year} is marked official but is a third-party host',
          );
        }
      }
    });
  });
}
