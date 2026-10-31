import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/services/user_pdf_index.dart';

void main() {
  group('UserPdfIndex', () {
    test('toContextBlock emits page markers and text', () {
      final index = UserPdfIndex(
        pdfId: 'test123',
        originalName: 'My Notes.pdf',
        localPath: '/tmp/test.pdf',
        pageCount: 3,
        wordCount: 100,
        pages: [
          UserPdfPage(page: 1, text: 'Cover page'),
          UserPdfPage(page: 2, text: ''),
          UserPdfPage(page: 3, text: 'Biology is the study of life.'),
        ],
        createdAt: DateTime(2024, 1, 1),
      );

      final block = index.toContextBlock();
      expect(block, contains('[p.1]'));
      expect(block, contains('Cover page'));
      expect(block, isNot(contains('[p.2]'))); // empty page skipped
      expect(block, contains('[p.3]'));
      expect(block, contains('Biology is the study of life.'));
      expect(block, contains('My Notes.pdf'));
    });

    test('toJson/fromJson roundtrip', () {
      final original = UserPdfIndex(
        pdfId: 'abc123',
        originalName: 'Test.pdf',
        localPath: '/path/to/test.pdf',
        pageCount: 2,
        wordCount: 50,
        pages: [
          UserPdfPage(page: 1, text: 'Page 1 text'),
          UserPdfPage(page: 2, text: 'Page 2 text'),
        ],
        createdAt: DateTime(2024, 6, 15, 10, 30),
      );

      final json = original.toJson();
      final restored = UserPdfIndex.fromJson(json);

      expect(restored.pdfId, original.pdfId);
      expect(restored.originalName, original.originalName);
      expect(restored.localPath, original.localPath);
      expect(restored.pageCount, original.pageCount);
      expect(restored.wordCount, original.wordCount);
      expect(restored.pages.length, original.pages.length);
      expect(restored.pages[0].text, original.pages[0].text);
      expect(restored.createdAt, original.createdAt);
    });

    test('UserPdfPage toJson/fromJson roundtrip', () {
      const page = UserPdfPage(page: 5, text: 'Some text');
      final json = page.toJson();
      final restored = UserPdfPage.fromJson(json);
      expect(restored.page, 5);
      expect(restored.text, 'Some text');
    });

    test('ribbonLabel returns expected format', () {
      final index = UserPdfIndex(
        pdfId: 'test',
        originalName: 'Biology Notes.pdf',
        localPath: '/tmp/test.pdf',
        pageCount: 10,
        wordCount: 5000,
        pages: [],
        createdAt: DateTime.now(),
      );
      expect(index.ribbonLabel, 'Your PDF: Biology Notes.pdf');
    });
  });
}