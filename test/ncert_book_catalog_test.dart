import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/subject_model.dart';
import 'package:neet_mitos/core/services/ncert_book_catalog.dart';

Chapter _chapter(String id, String name, String subjectId, String? classLevel) {
  return Chapter(
    id: id,
    name: name,
    subjectId: subjectId,
    classLevel: classLevel,
    topics: const [],
  );
}

void main() {
  group('NcertBookCatalog', () {
    test('resolves app Biology chapters to official NCERT PDFs', () {
      final livingWorld = NcertBookCatalog.entryFor(
        _chapter('bio_ch1', 'The Living World', 'bio', 'Class 11'),
      )!;
      expect(livingWorld.assetPath, endsWith('kebo101.pdf'));
      expect(livingWorld.chapterNumber, 1);

      final cellCycle = NcertBookCatalog.entryFor(
        _chapter('bio_ch10', 'Cell Cycle and Cell Division', 'bio', 'Class 11'),
      )!;
      expect(cellCycle.assetPath, endsWith('kebo110.pdf'));

      // App chapter 13 = Photosynthesis, which is NCERT chapter 11.
      final photosynthesis = NcertBookCatalog.entryFor(
        _chapter(
          'bio_ch13',
          'Photosynthesis in Higher Plants',
          'bio',
          'Class 11',
        ),
      )!;
      expect(photosynthesis.assetPath, endsWith('kebo111.pdf'));

      final humanReproduction = NcertBookCatalog.entryFor(
        _chapter('bio_ch3_12', 'Human Reproduction', 'bio', 'Class 12'),
      )!;
      expect(humanReproduction.assetPath, endsWith('lebo103.pdf'));
    });

    test('resolves app Physics and Chemistry chapters', () {
      final units = NcertBookCatalog.entryFor(
        _chapter('phys_ch2', 'Units & Measurements', 'phys', 'Class 11'),
      )!;
      expect(units.assetPath, endsWith('keph102.pdf'));
      expect(units.chapterNumber, 2);

      final motion = NcertBookCatalog.entryFor(
        _chapter('phys_ch3', 'Motion in a Straight Line', 'phys', 'Class 11'),
      )!;
      expect(motion.assetPath, endsWith('keph103.pdf'));

      final atom = NcertBookCatalog.entryFor(
        _chapter('chem_ch2', 'Structure of Atom', 'chem', 'Class 11'),
      )!;
      expect(atom.assetPath, endsWith('kech102.pdf'));
    });

    test('falls back to name matching when chapter id is unknown', () {
      final entry = NcertBookCatalog.entryFor(
        Chapter(
          id: 'custom_ch1',
          name: 'Some Basic Concepts of Chemistry',
          subjectId: 'chem',
          classLevel: 'Class 11',
          topics: const [],
        ),
      );
      expect(entry, isNotNull);
      expect(entry!.assetPath, endsWith('kech101.pdf'));
    });

    test('normalizes & to and for name fallback', () {
      final entry = NcertBookCatalog.entryFor(
        Chapter(
          id: 'custom_ch1',
          name: 'Units & Measurements',
          subjectId: 'phys',
          classLevel: 'Class 11',
          topics: const [],
        ),
      );
      expect(entry, isNotNull);
      expect(entry!.assetPath, endsWith('keph102.pdf'));
    });

    test('returns null for unknown chapters', () {
      final entry = NcertBookCatalog.entryFor(
        _chapter('unknown', 'Totally Fake Chapter', 'bio', 'Class 11'),
      );
      expect(entry, isNull);
    });

    test('chaptersOfBook returns all chapters in NCERT order', () {
      final cell = NcertBookCatalog.entryFor(
        _chapter('bio_ch8', 'Cell: The Unit of Life', 'bio', 'Class 11'),
      )!;
      final book = NcertBookCatalog.chaptersOfBook(cell);
      expect(book.length, 19);
      expect(book.first.chapterNumber, 1);
      expect(book.last.chapterNumber, 19);
      expect(book.first.chapterTitle, 'The Living World');
    });

    test('isAvailable is true for mapped chapters and false otherwise', () {
      expect(
        NcertBookCatalog.isAvailable(
          _chapter('bio_ch1', 'The Living World', 'bio', 'Class 11'),
        ),
        isTrue,
      );
      expect(
        NcertBookCatalog.isAvailable(
          _chapter('x', 'Unknown', 'bio', 'Class 11'),
        ),
        isFalse,
      );
    });
  });
}
