import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/services/pyq_pdf_downloader_service.dart';

void main() {
  group('PyqPdfDownloaderService Tests', () {
    test('service should be instantiable', () {
      final service = PyqPdfDownloaderService();
      expect(service, isA<PyqPdfDownloaderService>());
    });

    test('only direct PDF sources are listed', () {
      // The list used to hold 11 careers360 article pages, which `downloadPdf`
      // saved as `neet_<year>.pdf` and reported as success.
      expect(PyqPdfDownloaderService.neetPdfSources, isNotEmpty);
      for (final source in PyqPdfDownloaderService.neetPdfSources) {
        expect(
          source.url.toLowerCase(),
          contains('.pdf'),
          reason: '${source.year} points at a page, not a file',
        );
      }
    });

    test('counts reflect the verified source list', () {
      final service = PyqPdfDownloaderService();
      expect(service.availableYears, PyqPdfDownloaderService.neetPdfSources.length);
      expect(
        service.officialYears,
        PyqPdfDownloaderService.neetPdfSources
            .where((s) => s.isOfficial)
            .length,
      );
    });

    test('official sources are government-hosted only', () {
      for (final source in PyqPdfDownloaderService.neetPdfSources) {
        if (source.isOfficial) {
          expect(source.url, contains('gov.in'), reason: '${source.year}');
        }
      }
      // NEET 2024 was marked official while pointing at a careers360 article.
      expect(
        PyqPdfDownloaderService.neetPdfSources.any((s) => s.year == 2024),
        isFalse,
      );
    });

    test('download result class should work correctly', () {
      const result = PdfDownloadResult(
        success: true,
        filePath: '/test/path.pdf',
        sizeBytes: 1024,
      );

      expect(result.success, isTrue);
      expect(result.filePath, equals('/test/path.pdf'));
      expect(result.sizeBytes, equals(1024));
      expect(result.fromCache, isFalse);
    });

    test('pdf source should parse correctly', () {
      final source = PdfSource(
        url: 'https://example.com/paper.pdf',
        year: 2024,
        label: 'NEET 2024',
        isOfficial: true,
      );

      expect(source.year, equals(2024));
      expect(source.label, equals('NEET 2024'));
      expect(source.isOfficial, isTrue);
    });
  });

  group('Download coverage', () {
    test('the shipped years are exactly the verified PDFs', () {
      final years = PyqPdfDownloaderService.neetPdfSources
          .map((s) => s.year)
          .toList();
      expect(years.toSet(), {2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023});
      expect(years.toSet().length, years.length);
    });

    test('coverage is documented, not assumed', () {
      // Anything outside 2015-2023 has no verified direct PDF yet. When a year
      // is added, this count must change deliberately.
      expect(PyqPdfDownloaderService.neetPdfSources.length, 9);
    });
  });
}
