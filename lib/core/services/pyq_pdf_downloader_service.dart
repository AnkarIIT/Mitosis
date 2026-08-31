import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Service for downloading NEET Previous Year Question Papers in PDF format.
/// Supports direct PDF downloads from official and third-party sources.
class PyqPdfDownloaderService {
  PyqPdfDownloaderService();

  /// Public PDF sources for NEET Question Papers (last 20 years: 2006-2024)
  static const List<PdfSource> neetPdfSources = [
    // NTA Official Sources (2019 onwards - official NEET)
    PdfSource(
      url: 'https://neet.nta.nic.in/downloads/',
      year: 2024,
      label: 'NEET 2024 Question Paper',
      isOfficial: true,
    ),
    PdfSource(
      url: 'https://neet.nta.nic.in/downloads/',
      year: 2023,
      label: 'NEET 2023 Question Paper',
      isOfficial: true,
    ),
    PdfSource(
      url: 'https://neet.nta.nic.in/downloads/',
      year: 2022,
      label: 'NEET 2022 Question Paper',
      isOfficial: true,
    ),
    PdfSource(
      url: 'https://neet.nta.nic.in/downloads/',
      year: 2021,
      label: 'NEET 2021 Question Paper',
      isOfficial: true,
    ),
    PdfSource(
      url: 'https://neet.nta.nic.in/downloads/',
      year: 2020,
      label: 'NEET 2020 Question Paper',
      isOfficial: true,
    ),
    PdfSource(
      url: 'https://neet.nta.nic.in/downloads/',
      year: 2019,
      label: 'NEET 2019 Question Paper',
      isOfficial: true,
    ),
    // AIPMT (Pre-NEET era, last 20 years)
    PdfSource(
      url: 'https://example.com/aipmt/',
      year: 2018,
      label: 'AIPMT 2018 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://example.com/aipmt/',
      year: 2017,
      label: 'AIPMT 2017 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://example.com/aipmt/',
      year: 2016,
      label: 'AIPMT 2016 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://example.com/aipmt/',
      year: 2015,
      label: 'AIPMT 2015 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://example.com/aipmt/',
      year: 2014,
      label: 'AIPMT 2014 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://example.com/aipmt/',
      year: 2013,
      label: 'AIPMT 2013 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://example.com/aipmt/',
      year: 2012,
      label: 'AIPMT 2012 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://example.com/aipmt/',
      year: 2011,
      label: 'AIPMT 2011 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://example.com/aipmt/',
      year: 2010,
      label: 'AIPMT 2010 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://example.com/aipmt/',
      year: 2009,
      label: 'AIPMT 2009 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://example.com/aipmt/',
      year: 2008,
      label: 'AIPMT 2008 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://example.com/aipmt/',
      year: 2007,
      label: 'AIPMT 2007 Question Paper',
      isOfficial: false,
    ),
    PdfSource(
      url: 'https://example.com/aipmt/',
      year: 2006,
      label: 'AIPMT 2006 Question Paper',
      isOfficial: false,
    ),
  ];

  /// Download progress events
  Stream<PdfDownloadProgress>? progressStream;

  /// Download status
  bool get isDownloading => _isLoading;
  bool _isLoading = false;

  /// Download ALL PDFs from all sources
  /// Returns list of successfully downloaded files
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

  /// Download a single PDF by year
  Future<PdfDownloadResult> downloadPdfByYear(int year) {
    final source = neetPdfSources.firstWhere(
      (s) => s.year == year,
      orElse: () => throw ArgumentError('No PDF source found for year $year'),
    );
    return downloadPdf(source);
  }

  /// Download from a source
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
      
      // Check if already exists
      if (await file.exists()) {
        return PdfDownloadResult(
          success: true,
          filePath: filePath,
          fromCache: true,
        );
      }

      final response = await http.get(
        Uri.parse(_buildUrl(source)),
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
      
      // Handle redirect or proxy URLs
      if (response.statusCode == 302 || response.statusCode == 301) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          return downloadFromRedirect(redirectUrl, filePath, source.year);
        }
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

  Future<PdfDownloadResult> downloadFromRedirect(
    String url,
    String filePath,
    int year,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'NEET-Mitos/1.0 (Educational Research)',
          'Accept': 'application/pdf',
        },
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return PdfDownloadResult(
          success: true,
          filePath: filePath,
          sizeBytes: response.bodyBytes.length,
        );
      }

      return PdfDownloadResult(
        success: false,
        error: 'Redirect failed: HTTP ${response.statusCode}',
      );
    } catch (e) {
      return PdfDownloadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  String _buildUrl(PdfSource source) {
    // Build year-specific URL
    // This is a template - actual URLs may vary
    if (source.year >= 2019) {
      return '${source.url}neet${source.year}QuestionPaper.pdf';
    }
    return source.url;
  }

  /// Get available downloads count
  int get availableYears => neetPdfSources.length;

  /// Get official sources count (2019+)
  int get officialYears => neetPdfSources.where((s) => s.isOfficial).length;

  /// List downloaded PDFs
  Future<List<PdfFileInfo>> listDownloadedPdfs() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${appDir.path}/neet_pdfs');
      
      if (!await pdfDir.exists()) return [];
      
      final files = pdfDir.listSync();
      return files
          .whereType<File>()
          .map((file) => PdfFileInfo.fromJson(file))
          .toList();
    } catch (e) {
      debugPrint('Error listing PDFs: $e');
      return [];
    }
  }

  /// Delete a downloaded PDF
    Future<bool> deletePdf(int year) async {
      try {
        final appDir = await getApplicationDocumentsDirectory();
      
        // Find matching file in the NEET PDFs directory
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

  /// Cancel ongoing downloads
  void cancel() {
    _isLoading = false;
  }
}

/// Source configuration for PDF download
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

/// Result of PDF download
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

/// Progress during PDF download
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

/// PDF file information
class PdfFileInfo {
  PdfFileInfo({
    required this.year,
    required this.filePath,
    required this.size,
  });

  final int year;
  final String filePath;
  final int size;

  factory PdfFileInfo.fromJson(File file) {
      final fileName = file.path.split('/').last;
      final match = RegExp(r'neet_(\d+)').firstMatch(fileName);
      final year = match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
    
      return PdfFileInfo(
        year: year,
        filePath: file.path,
        size: file.lengthSync(),
      );
    }
}