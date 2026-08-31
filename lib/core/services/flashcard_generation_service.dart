import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/services/ncert_book_catalog.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/gemini_proxy_service.dart';

/// Progress events emitted while generating flashcards from an NCERT chapter.
class FlashcardGenerationProgress {
  const FlashcardGenerationProgress({
    required this.status,
    this.currentStep,
    this.processed,
    this.total,
    this.lastError,
  });

  final String status;
  final String? currentStep;
  final int? processed;
  final int? total;
  final String? lastError;
}

/// A single AI-generated flashcard grounded in an NCERT source paragraph.
class GeneratedFlashcard {
  const GeneratedFlashcard({
    required this.front,
    required this.back,
    required this.ncertReference,
    required this.sourcePage,
    this.difficulty = 'Medium',
  });

  final String front;
  final String back;
  final String ncertReference;
  final int sourcePage;
  final String difficulty;
}

/// Generates NotebookLM-style flashcards from bundled NCERT PDFs.
///
/// Flow:
/// 1. Resolve PDF asset path from chapter/subject
/// 2. Extract chapter text via [PdfService]
/// 3. Segment into paragraphs / key blocks
/// 4. Send NCERT-grounded prompt to [GeminiProxyService]
/// 5. Parse JSON response into [GeneratedFlashcard]s
class FlashcardGenerationService {
  FlashcardGenerationService({
    GeminiProxyService? proxy,
    Future<String> Function(String prompt, String systemPrompt)? directGenerate,
    this.batchSize = 5,
    this.delayBetweenBatchesMs = 1200,
  }) : _proxy = proxy,
       _directGenerate = directGenerate;

  final GeminiProxyService? _proxy;

  /// Direct-Gemini fallback using the user's own API key (used when the shared
  /// proxy is disabled/unreachable). Resolves to the response text.
  final Future<String> Function(String prompt, String systemPrompt)?
  _directGenerate;

  final int batchSize;
  final int delayBetweenBatchesMs;

  /// Whether a generation backend (proxy or direct key) is available.
  bool get _hasBackend =>
      (_proxy?.isConfigured ?? false) || _directGenerate != null;
  /// Sends [prompt] to whichever backend is available: the shared proxy first
  /// (cache + rate limiting), else the user's direct Gemini key.
  Future<String> _generateText(String prompt, String systemPrompt) async {
    final proxy = _proxy;
    if (proxy != null && proxy.isConfigured) {
      final result = await proxy.generate(
        prompt: prompt,
        systemPrompt: systemPrompt,
      );
      if (result.text.trim().isNotEmpty) return result.text;
      return '';
    }
    final direct = _directGenerate;
    if (direct != null) {
      try {
        return (await direct(prompt, systemPrompt)).trim();
      } catch (e) {
        debugPrint('❌ Direct flashcard generation failed: $e');
        return '';
      }
    }
    return '';
  }

  /// Generates [count] flashcards for the given NCERT chapter.
  ///
  /// Throws if the PDF asset is missing or text extraction fails.
  Stream<FlashcardGenerationProgress> generateFromChapter({
    required String subject,
    required String chapterTitle,
    required int chapterNumber,
    required String classLevel,
    int count = 20,
    String? assetPathOverride,
  }) async* {
    if (count <= 0) {
      yield const FlashcardGenerationProgress(status: 'No cards requested');
      return;
    }

    if (!_hasBackend) {
      yield FlashcardGenerationProgress(
        status:
            'AI flashcard generation requires cloud sync. Please enable it in Settings.',
        currentStep: 'ai',
        lastError: 'ai_unavailable',
      );
      return;
    }

    // 1. Resolve asset path.
    final assetPath =
        assetPathOverride ??
        _resolveAssetPath(subject, chapterNumber, classLevel);
    if (assetPath == null) {
      yield FlashcardGenerationProgress(
        status: 'No bundled NCERT PDF found for this chapter.',
        currentStep: 'resolve',
        lastError: 'asset_missing',
      );
      return;
    }

    // 2. Extract text.
    yield const FlashcardGenerationProgress(
      status: 'Reading NCERT chapter…',
      currentStep: 'extract',
    );

    final fullText = await PdfService.extractTextFromAsset(assetPath);
    if (fullText.isEmpty || fullText.startsWith('Error')) {
      yield FlashcardGenerationProgress(
        status: 'Failed to read the NCERT PDF for this chapter.',
        currentStep: 'extract',
        lastError: 'extraction_failed',
      );
      return;
    }

    // 3. Segment into chunks.
    final paragraphs = PdfService.segmentParagraphs(fullText, 0);
    if (paragraphs.isEmpty) {
      yield const FlashcardGenerationProgress(
        status: 'No readable text found in this chapter.',
        currentStep: 'segment',
      );
      return;
    }

    final chunks = _chunkParagraphs(paragraphs, count);
    final total = chunks.length;

    yield FlashcardGenerationProgress(
      status: 'Generating $total flashcard blocks…',
      currentStep: 'generate',
      processed: 0,
      total: total,
    );

    final results = <GeneratedFlashcard>[];
    var processed = 0;
    var failed = 0;

    for (var i = 0; i < total; i += batchSize) {
      final batch = chunks.skip(i).take(batchSize).toList();

      for (final chunk in batch) {
        processed += 1;

        final prompt = _buildFlashcardPrompt(
          subject: subject,
          chapterTitle: chapterTitle,
          classLevel: classLevel,
          chunk: chunk,
          count: 1,
        );

        final text = await _generateText(prompt, _systemPrompt);
        if (text.isEmpty) {
          failed += 1;
          yield FlashcardGenerationProgress(
            status: 'Generating… ($processed/$total)',
            currentStep: 'generate',
            processed: processed,
            total: total,
            lastError: 'Empty response',
          );
          continue;
        }

        final cards = _parseFlashcards(text, chapterTitle);
        results.addAll(cards);

        yield FlashcardGenerationProgress(
          status: 'Generating… ($processed/$total)',
          currentStep: 'generate',
          processed: processed,
          total: total,
        );
      }

      if (i + batchSize < total && delayBetweenBatchesMs > 0) {
        await Future<void>.delayed(
          Duration(milliseconds: delayBetweenBatchesMs),
        );
      }
    }

    // Deduplicate by front text.
    final unique = <String, GeneratedFlashcard>{};
    for (final card in results) {
      final key = _normalize(card.front);
      if (!unique.containsKey(key)) {
        unique[key] = card;
      }
    }
    final deduped = unique.values.toList();

    if (deduped.isEmpty) {
      yield FlashcardGenerationProgress(
        status: 'No flashcards could be generated. Try another chapter.',
        currentStep: 'done',
        total: total,
        lastError: failed > 0 ? 'generation_failed' : null,
      );
      return;
    }

    yield FlashcardGenerationProgress(
      status: 'Generated ${deduped.length} flashcards from NCERT.',
      currentStep: 'done',
      processed: processed,
      total: total,
    );
  }

  /// Returns the generated flashcards synchronously.
  Future<List<GeneratedFlashcard>> generate({
    required String subject,
    required String chapterTitle,
    required int chapterNumber,
    required String classLevel,
    int count = 20,
    String? assetPathOverride,
  }) async {
    if (!_hasBackend) return const [];

    final cards = <GeneratedFlashcard>[];

    final assetPath =
        assetPathOverride ??
        _resolveAssetPath(subject, chapterNumber, classLevel);
    if (assetPath == null) return cards;

    final fullText = await PdfService.extractTextFromAsset(assetPath);
    if (fullText.isEmpty || fullText.startsWith('Error')) return cards;

    final paragraphs = PdfService.segmentParagraphs(fullText, 0);
    final chunks = _chunkParagraphs(paragraphs, count);

    for (var i = 0; i < chunks.length; i += batchSize) {
      final batch = chunks.skip(i).take(batchSize).toList();

      for (final chunk in batch) {
        final prompt = _buildFlashcardPrompt(
          subject: subject,
          chapterTitle: chapterTitle,
          classLevel: classLevel,
          chunk: chunk,
          count: 1,
        );

        final text = await _generateText(prompt, _systemPrompt);
        if (text.isEmpty) continue;

        final parsed = _parseFlashcards(text, chapterTitle);
        cards.addAll(parsed);
      }

      if (i + batchSize < chunks.length && delayBetweenBatchesMs > 0) {
        await Future<void>.delayed(
          Duration(milliseconds: delayBetweenBatchesMs),
        );
      }
    }

    // Deduplicate.
    final unique = <String, GeneratedFlashcard>{};
    for (final card in cards) {
      final key = _normalize(card.front);
      if (!unique.containsKey(key)) unique[key] = card;
    }

    return unique.values.toList();
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  String? _resolveAssetPath(
    String subject,
    int chapterNumber,
    String classLevel,
  ) {
    final prefix = classLevel.toLowerCase().contains('12') ? 'le' : 'ke';
    final subjectPrefix = subject.toLowerCase().startsWith('bio')
        ? 'bo'
        : subject.toLowerCase().startsWith('chem')
        ? 'ch'
        : 'ph';
    final padded = chapterNumber.toString().padLeft(3, '0');
    final fileName = '$prefix$subjectPrefix$padded.pdf';

    // Try known paths from the catalog.
    for (final entry in NcertBookCatalog.allEntries) {
      if (entry.assetPath.endsWith(fileName)) return entry.assetPath;
    }

    // Fallback: generic structure.
    final folder = subject.toLowerCase();
    final book = subject.toLowerCase().startsWith('bio')
        ? (classLevel.toLowerCase().contains('12')
              ? 'Biology_Class_12'
              : 'Biology_Class_11')
        : (classLevel.toLowerCase().contains('12')
              ? '${subject}_Class_12_Part_1'
              : '${subject}_Class_11_Part_1');

    return 'assets/ncert_books/$folder/$book/$fileName';
  }

  List<String> _chunkParagraphs(
    List<PdfParagraph> paragraphs,
    int targetCount,
  ) {
    if (paragraphs.isEmpty) return const [];

    final shuffled = List<PdfParagraph>.from(paragraphs)..shuffle(Random());
    final selected = shuffled.take(max(targetCount, 1)).toList();

    return selected.map((p) => p.text).toList();
  }

  String _buildFlashcardPrompt({
    required String subject,
    required String chapterTitle,
    required String classLevel,
    required String chunk,
    required int count,
  }) {
    return '''
Generate exactly $count high-yield NEET flashcard(s) from this $classLevel $subject chapter text.
Chapter: $chapterTitle

TEXT:
"$chunk"

RULES:
- Front: a concise key term, definition, formula, fact, or direct question.
- Back: a short, accurate answer strictly grounded in the provided text.
- Keep back under 40 words.
- Add "Source: NCERT $classLevel $subject, Chapter $chapterTitle, p.<page_estimate>" at the end of the back.

OUTPUT FORMAT (strict JSON array, no markdown):
[
  {
    "front": "...",
    "back": "...",
    "source": "NCERT $classLevel $subject, Chapter $chapterTitle, p.X"
  }
]
''';
  }

  List<GeneratedFlashcard> _parseFlashcards(String raw, String chapterTitle) {
    String text = raw.trim();

    // Strip markdown fences.
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final fenceMatch = fence.firstMatch(text);
    if (fenceMatch != null) {
      text = fenceMatch.group(1)!.trim();
    }

    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) return const [];

    final slice = text.substring(start, end + 1);

    Object? decoded;
    try {
      decoded = slice.runes.isEmpty ? null : _decodeJsonLoose(slice);
    } on FormatException {
      return const [];
    }

    if (decoded is! List) return const [];

    final result = <GeneratedFlashcard>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final front = item['front']?.toString().trim();
      final back = item['back']?.toString().trim();
      final source = item['source']?.toString().trim() ?? '';

      if (front == null || front.isEmpty || back == null || back.isEmpty)
        continue;

      final page = _extractPageNumber(source);

      result.add(
        GeneratedFlashcard(
          front: front,
          back: back.replaceFirst(RegExp(r'Source:.*$'), '').trim(),
          ncertReference: source.isEmpty ? chapterTitle : source,
          sourcePage: page,
        ),
      );
    }

    return result;
  }

  int _extractPageNumber(String source) {
    final match = RegExp(r'p\.?(\d+)', caseSensitive: false).firstMatch(source);
    if (match != null) return int.tryParse(match.group(1) ?? '') ?? 0;
    return 0;
  }

  Object _decodeJsonLoose(String input) {
    // Remove control characters that can break jsonDecode.
    final cleaned = input.replaceAll(
      RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]'),
      '',
    );
    return jsonDecode(cleaned);
  }

  static String _normalize(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static const _systemPrompt =
      'You are an expert NEET flashcard creator. Generate concise, NCERT-grounded Q&A pairs. Never hallucinate.';
}
