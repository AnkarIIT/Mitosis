import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'user_pdf_index.dart';
import 'user_pdf_index_service.dart';

/// Progress events emitted during PDF extraction.
sealed class PdfExtractionEvent {
  const PdfExtractionEvent();
}

/// Extraction started.
class ExtractionStarted extends PdfExtractionEvent {
  final int totalPages;
  const ExtractionStarted(this.totalPages);
}

/// Page extracted.
class PageExtracted extends PdfExtractionEvent {
  final int page;
  final int totalPages;
  final int wordsSoFar;
  const PageExtracted(this.page, this.totalPages, this.wordsSoFar);
}

/// Extraction completed successfully.
class ExtractionCompleted extends PdfExtractionEvent {
  final UserPdfIndex index;
  const ExtractionCompleted(this.index);
}

/// Extraction failed.
class ExtractionFailed extends PdfExtractionEvent {
  final String error;
  const ExtractionFailed(this.error);
}

/// Extracts text from a PDF file in a background isolate.
///
/// Usage:
/// ```dart
/// final stream = PdfExtractionService.extract(pdfFile, pdfId, originalName);
/// await for (final event in stream) {
///   // update UI
/// }
/// ```
class PdfExtractionService {
  /// Extracts text from [pdfFilePath] and returns a stream of progress events.
  ///
  /// [pdfId] is the pre-computed ID (from [UserPdfIndexService.computePdfId]).
  /// [originalName] is the user-visible filename.
  /// [sandboxPath] is where to copy the PDF for persistent access.
  static Stream<PdfExtractionEvent> extract({
    required String pdfFilePath,
    required String pdfId,
    required String originalName,
    required String sandboxPath,
  }) async* {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn<_ExtractionArgs>(
      _extractionEntryPoint,
      _ExtractionArgs(
        pdfFilePath: pdfFilePath,
        pdfId: pdfId,
        originalName: originalName,
        sandboxPath: sandboxPath,
        sendPort: receivePort.sendPort,
      ),
    );

    try {
      await for (final message in receivePort) {
        if (message is PdfExtractionEvent) {
          yield message;
        }
        if (message is ExtractionCompleted || message is ExtractionFailed) {
          break;
        }
      }
    } finally {
      receivePort.close();
      isolate.kill(priority: Isolate.immediate);
    }
  }

  /// Extracts text from a PDF synchronously (for testing or small PDFs).
  /// Returns the built index or throws on failure.
  static Future<UserPdfIndex> extractSync({
    required String pdfFilePath,
    required String pdfId,
    required String originalName,
    required String sandboxPath,
  }) async {
    final pages = <UserPdfPage>[];
    int wordCount = 0;

    final bytes = await File(pdfFilePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final pageCount = document.pages.count;

    for (int i = 1; i <= pageCount; i++) {
      final text = PdfTextExtractor(document).extractText(
        startPageIndex: i - 1,
        endPageIndex: i - 1,
      );
      final clean = text.trim();
      if (clean.isNotEmpty) {
        wordCount += clean.split(RegExp(r'\s+')).length;
        pages.add(UserPdfPage(page: i, text: clean));
      }
    }
    document.dispose();

    // Copy PDF to sandbox for persistent access
    final sourceFile = File(pdfFilePath);
    final sandboxFile = File(sandboxPath);
    await sandboxFile.parent.create(recursive: true);
    await sourceFile.copy(sandboxPath);

    return UserPdfIndex(
      pdfId: pdfId,
      originalName: originalName,
      localPath: sandboxPath,
      pageCount: pageCount,
      wordCount: wordCount,
      pages: pages,
      createdAt: DateTime.now(),
    );
  }
}

class _ExtractionArgs {
  final String pdfFilePath;
  final String pdfId;
  final String originalName;
  final String sandboxPath;
  final SendPort sendPort;

  const _ExtractionArgs({
    required this.pdfFilePath,
    required this.pdfId,
    required this.originalName,
    required this.sandboxPath,
    required this.sendPort,
  });
}

/// Isolate entry point: does the heavy PDF text extraction.
void _extractionEntryPoint(_ExtractionArgs args) {
  _runExtraction(args);
}

Future<void> _runExtraction(_ExtractionArgs args) async {
  try {
    final bytes = await File(args.pdfFilePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final pageCount = document.pages.count;

    // Check page limit
    if (pageCount > UserPdfIndexService.maxPages) {
      args.sendPort.send(
        ExtractionFailed('PDF has $pageCount pages (max ${UserPdfIndexService.maxPages}).'),
      );
      document.dispose();
      return;
    }

    args.sendPort.send(ExtractionStarted(pageCount));

    final pages = <UserPdfPage>[];
    int wordCount = 0;

    for (int i = 1; i <= pageCount; i++) {
      final text = PdfTextExtractor(document).extractText(
        startPageIndex: i - 1,
        endPageIndex: i - 1,
      );
      final clean = text.trim();
      if (clean.isNotEmpty) {
        wordCount += clean.split(RegExp(r'\s+')).length;
        pages.add(UserPdfPage(page: i, text: clean));
      }
      args.sendPort.send(PageExtracted(i, pageCount, wordCount));
    }
    document.dispose();

    // Copy PDF to sandbox for persistent access
    final sourceFile = File(args.pdfFilePath);
    final sandboxFile = File(args.sandboxPath);
    await sandboxFile.parent.create(recursive: true);
    await sourceFile.copy(args.sandboxPath);

    final index = UserPdfIndex(
      pdfId: args.pdfId,
      originalName: args.originalName,
      localPath: args.sandboxPath,
      pageCount: pageCount,
      wordCount: wordCount,
      pages: pages,
      createdAt: DateTime.now(),
    );

    args.sendPort.send(ExtractionCompleted(index));
  } catch (e) {
    args.sendPort.send(ExtractionFailed(e.toString()));
  }
}