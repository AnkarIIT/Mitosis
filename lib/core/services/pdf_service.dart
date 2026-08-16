import 'dart:io';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfParagraph {
  final int page;
  final String text;

  const PdfParagraph({required this.page, required this.text});
}

class PdfService {
  static Future<Uint8List> _loadAssetBytes(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  static Future<String> extractText(File file) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      return "Error extracting text: $e";
    }
  }

  /// Extracts the plain text of a single page (0-based index) from a bundled
  /// PDF asset.
  static Future<String> extractPageText(String assetPath, int pageIndex) async {
    final bytes = await _loadAssetBytes(assetPath);
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText(
        startPageIndex: pageIndex,
        endPageIndex: pageIndex,
      );
    } finally {
      document.dispose();
    }
  }

  /// Groups extracted page text into paragraphs. Blocks of text separated by
  /// blank lines are treated as distinct paragraphs (used for the paragraph
  /// question pool).
  static List<PdfParagraph> segmentParagraphs(String pageText, int page) {
    final lines = pageText.split('\n').map((l) => l.trim()).toList();
    final paragraphs = <PdfParagraph>[];
    final buffer = <String>[];

    void flush() {
      if (buffer.isEmpty) return;
      final text = buffer.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.length >= 25) {
        paragraphs.add(PdfParagraph(page: page, text: text));
      }
      buffer.clear();
    }

    for (final line in lines) {
      if (line.isEmpty) {
        flush();
        continue;
      }
      buffer.add(line);
    }
    flush();
    return paragraphs;
  }

  /// Finds the first page (0-based) whose extracted text contains the given
  /// chapter title. Returns null when not found or the PDF cannot be parsed.
  static Future<int?> findChapterStartPage(
    String assetPath,
    String chapterTitle,
  ) async {
    final bytes = await _loadAssetBytes(assetPath);
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      final needle = _normalize(chapterTitle);
      for (int i = 0; i < document.pages.count; i++) {
        final text = extractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        if (_normalize(text).contains(needle)) return i;
      }
    } catch (_) {
      return null;
    } finally {
      document.dispose();
    }
    return null;
  }

  static List<Map<String, String>> splitByChapters(String fullText) {
    List<Map<String, String>> chapters = [];
    final RegExp chapterRegex = RegExp(r'(Chapter\s+\d+[:\s]+[A-Za-z\s]+)', caseSensitive: false);
    
    final matches = chapterRegex.allMatches(fullText).toList();
    
    if (matches.isEmpty) {
      chapters.add({
        'title': 'General Content',
        'content': fullText,
      });
      return chapters;
    }

    for (int i = 0; i < matches.length; i++) {
      int start = matches[i].start;
      int end = (i + 1 < matches.length) ? matches[i + 1].start : fullText.length;
      
      chapters.add({
        'title': matches[i].group(0) ?? 'Unknown Chapter',
        'content': fullText.substring(start, end).trim(),
      });
    }
    return chapters;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
