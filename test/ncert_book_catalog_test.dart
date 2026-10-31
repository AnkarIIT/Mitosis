import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/constants/neet_sample_data.dart';
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
      // Rationalised NCERT dropped "Reproduction in Organisms", so app
      // chapter 3 is file lebo102, not lebo103.
      expect(humanReproduction.assetPath, endsWith('lebo102.pdf'));

      final inheritance = NcertBookCatalog.entryFor(
        _chapter(
          'bio_ch5_12',
          'Principles of Inheritance and Variation',
          'bio',
          'Class 12',
        ),
      )!;
      expect(inheritance.assetPath, endsWith('lebo104.pdf'));

      final biodiversity = NcertBookCatalog.entryFor(
        _chapter(
          'bio_ch15_12',
          'Biodiversity and Conservation',
          'bio',
          'Class 12',
        ),
      )!;
      expect(biodiversity.assetPath, endsWith('lebo113.pdf'));
    });

    test('resolves app Physics and Chemistry chapters', () {
      final units = NcertBookCatalog.entryFor(
        _chapter('phys_ch2', 'Units & Measurements', 'phys', 'Class 11'),
      )!;
      // "Physical World" was removed, so Units and Measurements is ch 1.
      expect(units.assetPath, endsWith('keph101.pdf'));
      expect(units.chapterNumber, 1);

      final motion = NcertBookCatalog.entryFor(
        _chapter('phys_ch3', 'Motion in a Straight Line', 'phys', 'Class 11'),
      )!;
      expect(motion.assetPath, endsWith('keph102.pdf'));
      expect(motion.chapterNumber, 2);

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
      expect(entry!.assetPath, endsWith('keph101.pdf'));
    });

    test('chapters removed from the current syllabus have no PDF', () {
      // Both were dropped by the rationalised NCERT: showing a PDF for them
      // would serve the wrong chapter. UI must hide the PDF action instead.
      for (final removed in [
        _chapter('bio_ch1_12', 'Reproduction in Organisms', 'bio', 'Class 12'),
        _chapter(
          'bio_ch9_12',
          'Strategies for Enhancement in Food Production',
          'bio',
          'Class 12',
        ),
      ]) {
        expect(NcertBookCatalog.entryFor(removed), isNull, reason: removed.id);
        expect(NcertBookCatalog.isAvailable(removed), isFalse, reason: removed.id);
      }
    });

    test('placeholder chapters have no PDF', () {
      for (final id in ['bio_ch20', 'bio_ch21', 'bio_ch22']) {
        expect(
          NcertBookCatalog.entryFor(_chapter(id, 'Chapter 20', 'bio', 'Class 11')),
          isNull,
          reason: id,
        );
      }
    });

    test('shipped chapter data carries the rationalised-removal flag', () {
      final all = [for (final s in subjects) ...s.chapters];

      final removed = all
          .where((c) => c.isRemovedFromSyllabus)
          .map((c) => c.id)
          .toSet();
      expect(removed, {'bio_ch1_12', 'bio_ch9_12'});

      for (final c in all.where((c) => c.isRemovedFromSyllabus)) {
        expect(NcertBookCatalog.entryFor(c), isNull, reason: c.id);
      }

      // The empty "Chapter 20/21/22" placeholders must not ship at all.
      expect(all.any((c) => c.name.startsWith('Chapter 2')), isFalse);
      for (final id in ['bio_ch20', 'bio_ch21', 'bio_ch22']) {
        expect(all.any((c) => c.id == id), isFalse, reason: id);
      }
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
