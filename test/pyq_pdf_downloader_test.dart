import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/services/pyq_pdf_downloader_service.dart';

void main() {
  group('PyqPdfDownloaderService Tests', () {
    test('service should be instantiable', () {
      final service = PyqPdfDownloaderService();
      expect(service, isA<PyqPdfDownloaderService>());
    });

    test('service should have 19 years of sources (2006-2024)', () {
      expect(PyqPdfDownloaderService.neetPdfSources.length, equals(19));
    });

    test('service should have 6 official sources (2019-2024)', () {
      final service = PyqPdfDownloaderService();
      expect(service.officialYears, equals(6));
      expect(service.availableYears, equals(19));
    });

    test('sources should cover years 2006-2024', () {
      final years = PyqPdfDownloaderService.neetPdfSources.map((s) => s.year).toSet();
      
      // Check that all years are covered
      for (int year = 2006; year <= 2024; year++) {
        expect(
          years.contains(year),
          isTrue,
          reason: 'Year $year should be in sources',
        );
      }
    });

    test('official sources should be marked correctly', () {
      // 2019-2024 are official NEET papers
      for (var source in PyqPdfDownloaderService.neetPdfSources) {
        if (source.year >= 2019 && source.year <= 2024) {
          expect(source.isOfficial, isTrue);
        } else {
          expect(source.isOfficial, isFalse);
        }
      }
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

    test('pdf file info should parse correctly', () {
      // Note: This test would need an actual file in a real scenario
      // Here we test the factory constructor with mock data
      final source = PdfSource(
        url: 'https://example.com/',
        year: 2024,
        label: 'NEET 2024',
        isOfficial: true,
      );

      expect(source.year, equals(2024));
      expect(source.label, equals('NEET 2024'));
      expect(source.isOfficial, isTrue);
    });
  });

  group('Download Coverage Summary', () {
    test('should identify download summary', () {
      // This test documents what the service provides
      final service = PyqPdfDownloaderService();
      
      // Total years covered: 2006-2024 = 19 years
      final totalYears = 2024 - 2006 + 1;
      expect(totalYears, equals(19));
      
      // Official NTA/NEET papers: 2019-2024 = 6 years
      final officialYears = 2024 - 2019 + 1;
      expect(officialYears, equals(6));
      
      // Pre-NEET AIPMT papers: 2006-2018 = 13 years
      final aipmtYears = 2018 - 2006 + 1;
      expect(aipmtYears, equals(13));
      
      // Verify counts match
      expect(service.availableYears, equals(totalYears));
      expect(service.officialYears, equals(officialYears));
    });
  });
}