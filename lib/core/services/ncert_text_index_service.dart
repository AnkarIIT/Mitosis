import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One extracted page of a chapter's NCERT PDF.
class NcertPageText {
  final int page; // 1-based, equals the physical PDF page number
  final String text;

  const NcertPageText({required this.page, required this.text});
}

/// The full extracted text of one NCERT chapter, as produced by
/// `scripts/build_ncert_text_index.py`. This is what grounds the AI tutor:
/// the whole chapter is injected into the prompt, so the model can only
/// reason from real NCERT content and cite the PDF page it used.
class NcertChapterText {
  final String chapterId;
  final String subject;
  final String className;
  final String title;
  final String pdf;
  final int wordCount;
  final List<NcertPageText> pages;

  const NcertChapterText({
    required this.chapterId,
    required this.subject,
    required this.className,
    required this.title,
    required this.pdf,
    required this.wordCount,
    required this.pages,
  });

  factory NcertChapterText.fromJson(Map<String, dynamic> json) {
    return NcertChapterText(
      chapterId: json['chapterId'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      className: json['className'] as String? ?? '',
      title: json['title'] as String? ?? '',
      pdf: json['pdf'] as String? ?? '',
      wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
      pages: [
        for (final page in (json['pages'] as List? ?? const []))
          NcertPageText(
            page: (page['n'] as num?)?.toInt() ?? 0,
            text: page['text'] as String? ?? '',
          ),
      ],
    );
  }

  /// Builds the reference block injected into the chat prompt.
  ///
  /// Every page is prefixed with its own `[p.N]` marker so the model can cite
  /// the exact PDF page, and the tutor UI can turn those citations into
  /// tappable links that open the bundled PDF at that page.
  String toContextBlock({int maxPages = 200}) {
    final buffer = StringBuffer();
    buffer
      ..writeln('REFERENCE TEXT — NCERT $className $subject, '
          'Chapter $title. Answer STRICTLY from this text.')
      ..writeln('If the answer is not here, say so plainly instead of guessing.')
      ..writeln('Every page is marked; cite page numbers as [p.N] in your answer.');
    for (final page in pages.take(maxPages)) {
      final text = page.text.trim();
      if (text.isEmpty) continue;
      buffer
        ..writeln()
        ..writeln('[p.${page.page}]')
        ..writeln(text);
    }
    return buffer.toString();
  }
}

/// Loads the per-chapter text index from `assets/ncert_text/`.
///
/// Chapter files are loaded lazily per chapter — the whole index is ~1.2 MB
/// but a single grounded session only ever needs one chapter.
class NcertTextIndexService {
  final Map<String, Future<NcertChapterText?>> _cache = {};
  Future<Map<String, dynamic>>? _manifest;

  /// Chapter ids that actually have an index file on disk.
  Future<Set<String>> indexedChapterIds() async {
    try {
      _manifest ??= rootBundle
          .loadString('assets/ncert_text/manifest.json')
          .then((raw) => jsonDecode(raw) as Map<String, dynamic>);
      return (await _manifest!).keys.toSet();
    } catch (_) {
      return const <String>{};
    }
  }

  /// Loads one chapter's extracted text, or `null` when the chapter was not
  /// indexed (e.g. it has no bundled PDF because NCERT removed it).
  ///
  /// The future is cached, so repeated sends within a session do not re-read
  /// the asset.
  Future<NcertChapterText?> load(String chapterId) {
    return _cache.putIfAbsent(
      chapterId,
      () => _readChapter(chapterId),
    );
  }

  Future<NcertChapterText?> _readChapter(String chapterId) async {
    try {
      final raw = await rootBundle.loadString(
        'assets/ncert_text/$chapterId.json',
      );
      return NcertChapterText.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Missing or unreadable index — the caller must surface this honestly,
      // not pretend the chat is grounded.
      _cache.remove(chapterId);
      return null;
    }
  }
}
