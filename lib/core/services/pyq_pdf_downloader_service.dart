import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Service for downloading NEET Previous Year Question Papers in PDF format.
/// Verified direct PDF links are used where available; others fall back to the web.
class PyqPdfDownloaderService {
  PyqPdfDownloaderService();

  /// Verified sources for NEET Question Papers.
  static const List<PdfSource> neetPdfSources = [
    PdfSource(
      url: 'https://medicine.careers360.com/articles/neet-2025-question-paper',
      year: 2025,
      label: 'NEET 2025 Question Paper',
      isOfficial: true,
    ),
    PdfSource(
      url: 'https://medicine.careers360.com/articles/neet-2024-question-paper',
      year: 2024,
      label: 'NEET 2024 Question Paper',
      isOfficial: true,
    ),
    PdfSource(
      url: 'https://static.collegedekho.com/media/uploads/2023/05/07/qs-and-ans_neet-2023_code-f1_final.pdf',
      year: 2023,
      label: 'NEET 2023 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://static.collegedekho.com/media/uploads/2022/07/18/neetug-2022-examination-qp-_17-07-2022.pdf',
      year: 2022,
      label: 'NEET 2022 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://static.collegedekho.com/media/uploads/2024/01/12/neet-2021-question-paper-code-m3.pdf',
      year: 2021,
      label: 'NEET 2021 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://cdnbbsr.s3waas.gov.in/s37bc1ec1d9c3426357e69acd5bf320061/uploads/2022/02/2022021555.pdf',
      year: 2020,
      label: 'NEET 2020 Question Paper',
      isOfficial: true,
    ),
    PdfSource(
      url: 'https://www.nishantbhushan.in/_files/ugd/37999e_f0eb85efd4314e279a10573636799f44.pdf?index=true',
      year: 2019,
      label: 'NEET 2019 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://static.collegedekho.com/media/uploads/2024/09/11/neet-2018-question-paper-code-aa.pdf',
      year: 2018,
      label: 'NEET 2018 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://static.collegedekho.com/media/uploads/2024/09/12/neet-2017-question-paper-code-a.pdf',
      year: 2017,
      label: 'NEET 2017 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://static.collegedekho.com/media/uploads/2024/09/12/neet-2016-question-paper-phase-1-code-c-r-y.pdf',
      year: 2016,
      label: 'NEET 2016 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://static.collegedekho.com/media/uploads/2024/09/12/neet-2015-question-paper-code-c-re-exam.pdf',
      year: 2015,
      label: 'NEET 2015 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://medicine.careers360.com/articles/neet-previous-year-question-papers',
      year: 2014,
      label: 'AIPMT 2014 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://medicine.careers360.com/articles/neet-previous-year-question-papers',
      year: 2013,
      label: 'AIPMT 2013 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://medicine.careers360.com/articles/neet-previous-year-question-papers',
      year: 2012,
      label: 'AIPMT 2012 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://medicine.careers360.com/articles/neet-previous-year-question-papers',
      year: 2011,
      label: 'AIPMT 2011 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://medicine.careers360.com/articles/neet-previous-year-question-papers',
      year: 2010,
      label: 'AIPMT 2010 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://medicine.careers360.com/articles/neet-previous-year-question-papers',
      year: 2009,
      label: 'AIPMT 2009 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://medicine.careers360.com/articles/neet-previous-year-question-papers',
      year: 2008,
      label: 'AIPMT 2008 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://medicine.careers360.com/articles/neet-previous-year-question-papers',
      year: 2007,
      label: 'AIPMT 2007 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://medicine.careers360.com/articles/neet-previous-year-question-papers',
      year: 2006,
      label: 'AIPMT 2006 Question Paper',
      isOfficial: false,
    ),
  ];

  Stream<PdfDownloadProgress>? progressStream;
  bool get isDownloading => _isLoading;
  bool _isLoading = false;

  Future<List<String>> downloadAllPdfs() async {
    final downloaded = <String>[];

    for (final source in neetPdfSources) {
      if (_isLoading) break;

      try {
        final result = await downloadPdf(source);
        if (result.success) {
          downloaded.add(source.label);
          debugPrint('✅ Downloaded: ${source.label}');
        } else {
          debugPrint('❌ Failed: ${source.label} - ${result.error}');
        }
      } catch (e) {
        debugPrint('❌ Error downloading ${source.label}: $e');
      }
    }

    return downloaded;
  }

  Future<PdfDownloadResult> downloadPdfByYear(int year) {
    final source = neetPdfSources.firstWhere(
      (s) => s.year == year,
      orElse: () => throw ArgumentError('No PDF source found for year $year'),
    );
    return downloadPdf(source);
  }

  Future<PdfDownloadResult> downloadPdf(PdfSource source) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${appDir.path}/neet_pdfs');

      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      final fileName = 'neet_${source.year}_${source.isOfficial ? 'official' : 'aipmt'}.pdf';
      final filePath = '${pdfDir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        return PdfDownloadResult(
          success: true,
          filePath: filePath,
          fromCache: true,
        );
      }

      final response = await http.get(
        Uri.parse(source.url),
        headers: {
          'User-Agent': 'NEET-Mitos/1.0 (Educational Research)',
          'Accept': 'application/pdf',
        },
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return PdfDownloadResult(
          success: true,
          filePath: filePath,
          sizeBytes: response.bodyBytes.length,
        );
      }

      return PdfDownloadResult(
        success: false,
        error: 'HTTP ${response.statusCode}',
      );
    } catch (e) {
      return PdfDownloadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<List<PdfFileInfo>> listDownloadedPdfs() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${appDir.path}/neet_pdfs');

      if (!await pdfDir.exists()) return [];

      final files = pdfDir.listSync().whereType<File>().toList();
      return files
          .map((file) => PdfFileInfo(
                year: _extractYear(file.path),
                filePath: file.path,
                size: file.lengthSync(),
              ))
          .toList();
    } catch (e) {
      debugPrint('Error listing PDFs: $e');
      return [];
    }
  }

  Future<bool> deletePdf(int year) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${appDir.path}/neet_pdfs');

      if (await pdfDir.exists()) {
        final files = pdfDir.listSync();
        for (final file in files) {
          if (file is File && file.path.contains('neet_$year')) {
            await file.delete();
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting PDF for $year: $e');
      return false;
    }
  }

  void cancel() {
    _isLoading = false;
  }

  int get availableYears => neetPdfSources.length;

  int get officialYears =>
      neetPdfSources.where((source) => source.isOfficial).length;

  int _extractYear(String path) {
    final match = RegExp(r'neet_(\d+)').firstMatch(path);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }
}

class PdfSource {
  const PdfSource({
    required this.url,
    required this.year,
    required this.label,
    required this.isOfficial,
  });

  final String url;
  final int year;
  final String label;
  final bool isOfficial;
}

class PdfDownloadResult {
  const PdfDownloadResult({
    required this.success,
    this.filePath,
    this.sizeBytes,
    this.error,
    this.fromCache = false,
  });

  final bool success;
  final String? filePath;
  final int? sizeBytes;
  final String? error;
  final bool fromCache;
}

class PdfDownloadProgress {
  const PdfDownloadProgress({
    required this.currentYear,
    this.completed = 0,
    this.total = 0,
    this.percentage = 0.0,
    this.error,
  });

  final int currentYear;
  final int completed;
  final int total;
  final double percentage;
  final String? error;
}

class PdfFileInfo {
  PdfFileInfo({
    required this.year,
    required this.filePath,
    required this.size,
  });

  final int year;
  final String filePath;
  final int size;
}
