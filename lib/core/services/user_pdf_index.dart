/// Data model for a user-uploaded PDF's extracted text index.
/// Mirrors [NcertChapterText] but for arbitrary user PDFs.
class UserPdfPage {
  final int page; // 1-based, physical PDF page number
  final String text;

  const UserPdfPage({required this.page, required this.text});

  factory UserPdfPage.fromJson(Map<String, dynamic> json) => UserPdfPage(
        page: (json['page'] as num?)?.toInt() ?? 0,
        text: json['text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'page': page, 'text': text};
}

class UserPdfIndex {
  final String pdfId; // SHA-256 hash of file content + timestamp
  final String originalName; // e.g., "Biology Notes.pdf"
  final String localPath; // sandboxed copy in app documents
  final int pageCount;
  final int wordCount;
  final List<UserPdfPage> pages;
  final DateTime createdAt;

  const UserPdfIndex({
    required this.pdfId,
    required this.originalName,
    required this.localPath,
    required this.pageCount,
    required this.wordCount,
    required this.pages,
    required this.createdAt,
  });

  factory UserPdfIndex.fromJson(Map<String, dynamic> json) => UserPdfIndex(
        pdfId: json['pdfId'] as String? ?? '',
        originalName: json['originalName'] as String? ?? '',
        localPath: json['localPath'] as String? ?? '',
        pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
        wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
        pages: (json['pages'] as List? ?? const [])
            .map((e) => UserPdfPage.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'pdfId': pdfId,
        'originalName': originalName,
        'localPath': localPath,
        'pageCount': pageCount,
        'wordCount': wordCount,
        'pages': [for (final p in pages) p.toJson()],
        'createdAt': createdAt.toIso8601String(),
      };

  /// Builds the reference block injected into the chat prompt.
  /// Every page is prefixed with its own `[p.N]` marker so the model can cite
  /// the exact PDF page, and the tutor UI can turn those citations into
  /// tappable links that open the user PDF at that page.
  String toContextBlock({int maxPages = 200}) {
    final buffer = StringBuffer();
    buffer
      ..writeln('REFERENCE TEXT — Your uploaded document: $originalName.')
      ..writeln('Answer STRICTLY from this text.')
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

  /// Display label for the grounded ribbon.
  String get ribbonLabel => 'Your PDF: $originalName';
}