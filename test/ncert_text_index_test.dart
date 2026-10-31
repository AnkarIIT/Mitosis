import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/services/ncert_book_catalog.dart';
import 'package:neet_mitos/core/services/ncert_text_index_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NcertChapterText.toContextBlock', () {
    const chapter = NcertChapterText(
      chapterId: 'bio_ch1',
      subject: 'Biology',
      className: 'Class 11',
      title: 'The Living World',
      pdf: 'assets/ncert_books/biology/Biology_Class_11/kebo101.pdf',
      wordCount: 42,
      pages: [
        NcertPageText(page: 1, text: 'cover page  '),
        NcertPageText(page: 2, text: ''),
        NcertPageText(page: 3, text: 'Living organisms reproduce.'),
      ],
    );

    test('emits a [p.N] marker for every non-empty page', () {
      final block = chapter.toContextBlock();
      expect(block, contains('[p.1]'));
      expect(block, contains('[p.3]'));
      expect(block, contains('Living organisms reproduce.'));
    });

    test('skips empty pages without faking a marker', () {
      final block = chapter.toContextBlock();
      expect(block, isNot(contains('[p.2]')));
    });

    test('header names the source and the citation format', () {
      final block = chapter.toContextBlock();
      expect(block, contains('Class 11'));
      expect(block, contains('The Living World'));
      expect(block, contains('[p.N]'));
    });

    test('maxPages trims the injected context deterministically', () {
      final block = chapter.toContextBlock(maxPages: 2);
      expect(block, contains('[p.1]'));
      expect(block, isNot(contains('[p.3]')));
    });
  });

  group('NcertTextIndexService (real bundled assets)', () {
    final service = NcertTextIndexService();

    test('manifest lists the indexed chapters', () async {
      final ids = await service.indexedChapterIds();
      expect(ids, contains('bio_ch1'));
    });

    test('loaded chapter has pages and a matching context block', () async {
      final chapter = await service.load('bio_ch1');
      expect(chapter, isNotNull);
      expect(chapter!.pages, isNotEmpty);
      final block = chapter.toContextBlock();
      // First non-empty page marker must appear in the block.
      expect(
        block,
        contains(chapter.pages.where((p) => p.text.isNotEmpty).first.text),
      );
    });

    test('missing chapter resolves to null honestly', () async {
      final chapter = await service.load('no_such_chapter');
      expect(chapter, isNull);
    });

    test('catalog exposes exactly the chapters that are indexed', () async {
      final indexed = await service.indexedChapterIds();
      final inCatalog = NcertBookCatalog.allByChapterKey.keys.toSet();
      // Every mapped chapter must have an index file — otherwise grounding
      // silently fails for that chapter.
      expect(inCatalog.difference(indexed), isEmpty);
    });
  });
}
