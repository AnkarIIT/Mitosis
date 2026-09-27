import '../models/subject_model.dart';

class NcertBookEntry {
  final String subject;
  final String classLevel;
  final String bookName;
  final String assetPath;
  final int chapterNumber;
  final String chapterTitle;

  const NcertBookEntry({
    required this.subject,
    required this.classLevel,
    required this.bookName,
    required this.assetPath,
    required this.chapterNumber,
    required this.chapterTitle,
  });
}

/// Maps app chapters to their official NCERT textbook PDFs bundled under
/// `assets/ncert_books/`. Each PDF is one NCERT chapter (e.g. `kebo101.pdf`
/// is Biology Class 11, Chapter 1 — The Living World).
class NcertBookCatalog {
  static const String _base = 'assets/ncert_books';

  static const Map<String, String> _appChapterPdf = {
    // Biology Class 11
    'bio_ch1': '$_base/biology/Biology_Class_11/kebo101.pdf',
    'bio_ch2': '$_base/biology/Biology_Class_11/kebo102.pdf',
    'bio_ch3': '$_base/biology/Biology_Class_11/kebo103.pdf',
    'bio_ch4': '$_base/biology/Biology_Class_11/kebo104.pdf',
    'bio_ch8': '$_base/biology/Biology_Class_11/kebo108.pdf',
    'bio_ch9': '$_base/biology/Biology_Class_11/kebo109.pdf',
    'bio_ch10': '$_base/biology/Biology_Class_11/kebo110.pdf',
    'bio_ch13': '$_base/biology/Biology_Class_11/kebo111.pdf',
    'bio_ch14': '$_base/biology/Biology_Class_11/kebo112.pdf',
    // Biology Class 12
    'bio_ch3_12': '$_base/biology/Biology_Class_12/lebo103.pdf',
    'bio_ch5_12': '$_base/biology/Biology_Class_12/lebo105.pdf',
    'bio_ch6_12': '$_base/biology/Biology_Class_12/lebo106.pdf',
    'bio_ch7_12': '$_base/biology/Biology_Class_12/lebo107.pdf',
    'bio_ch8_12': '$_base/biology/Biology_Class_12/lebo108.pdf',
    'bio_ch11_12': '$_base/biology/Biology_Class_12/lebo111.pdf',
    'bio_ch13_12': '$_base/biology/Biology_Class_12/lebo113.pdf',
    'bio_ch14_12': '$_base/biology/Biology_Class_12/lebo114.pdf',
    'bio_ch15_12': '$_base/biology/Biology_Class_12/lebo115.pdf',
    // Chemistry Class 11
    'chem_ch1': '$_base/chemistry/Chemistry_Class_11_Part_1/kech101.pdf',
    'chem_ch2': '$_base/chemistry/Chemistry_Class_11_Part_1/kech102.pdf',
    // Physics Class 11
    'phys_ch2': '$_base/physics/Physics_Class_11_Part_1/keph102.pdf',
    'phys_ch3': '$_base/physics/Physics_Class_11_Part_1/keph103.pdf',
  };

  static final List<NcertBookEntry> _entries = _buildEntries();

  /// All known NCERT book entries in chapter order.
  static List<NcertBookEntry> get allEntries => List.unmodifiable(_entries);

  /// Find an entry by its chapter key (e.g., 'bio_ch1', 'chem_ch1', 'phys_ch2').
  static NcertBookEntry? entryByChapterKey(String chapterKey) {
    final path = _appChapterPdf[chapterKey];
    if (path == null) return null;
    try {
      return _entries.firstWhere((e) => e.assetPath == path);
    } catch (_) {
      return null;
    }
  }

  static List<NcertBookEntry> _buildEntries() {
    final list = <NcertBookEntry>[];

    void add(
      String subject,
      String classLevel,
      String bookName,
      String file,
      int number,
      String title,
    ) {
      list.add(
        NcertBookEntry(
          subject: subject,
          classLevel: classLevel,
          bookName: bookName,
          assetPath: '$_base/${subject.toLowerCase()}/$bookName/$file',
          chapterNumber: number,
          chapterTitle: title,
        ),
      );
    }

    // ---- Biology Class 11 ----
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo101.pdf',
      1,
      'The Living World',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo102.pdf',
      2,
      'Biological Classification',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo103.pdf',
      3,
      'Plant Kingdom',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo104.pdf',
      4,
      'Animal Kingdom',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo105.pdf',
      5,
      'Morphology of Flowering Plants',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo106.pdf',
      6,
      'Anatomy of Flowering Plants',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo107.pdf',
      7,
      'Structural Organisation in Animals',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo108.pdf',
      8,
      'Cell: The Unit of Life',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo109.pdf',
      9,
      'Biomolecules',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo110.pdf',
      10,
      'Cell Cycle and Cell Division',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo111.pdf',
      11,
      'Photosynthesis in Higher Plants',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo112.pdf',
      12,
      'Respiration in Plants',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo113.pdf',
      13,
      'Plant Growth and Development',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo114.pdf',
      14,
      'Breathing and Exchange of Gases',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo115.pdf',
      15,
      'Body Fluids and Circulation',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo116.pdf',
      16,
      'Excretory Products and their Elimination',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo117.pdf',
      17,
      'Locomotion and Movement',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo118.pdf',
      18,
      'Neural Control and Coordination',
    );
    add(
      'Biology',
      'Class 11',
      'Biology_Class_11',
      'kebo119.pdf',
      19,
      'Chemical Coordination and Integration',
    );

    // ---- Biology Class 12 ----
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo101.pdf',
      1,
      'Reproduction in Organisms',
    );
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo102.pdf',
      2,
      'Sexual Reproduction in Flowering Plants',
    );
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo103.pdf',
      3,
      'Human Reproduction',
    );
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo104.pdf',
      4,
      'Reproductive Health',
    );
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo105.pdf',
      5,
      'Principles of Inheritance and Variation',
    );
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo106.pdf',
      6,
      'Molecular Basis of Inheritance',
    );
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo107.pdf',
      7,
      'Evolution',
    );
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo108.pdf',
      8,
      'Human Health and Disease',
    );
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo109.pdf',
      9,
      'Strategies for Enhancement in Food Production',
    );
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo110.pdf',
      10,
      'Microbes in Human Welfare',
    );
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo111.pdf',
      11,
      'Biotechnology: Principles and Processes',
    );
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo112.pdf',
      12,
      'Biotechnology and its Applications',
    );
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo113.pdf',
      13,
      'Organisms and Populations',
    );
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo114.pdf',
      14,
      'Ecosystem',
    );
    add(
      'Biology',
      'Class 12',
      'Biology_Class_12',
      'lebo115.pdf',
      15,
      'Biodiversity and Conservation',
    );

    // ---- Chemistry Class 11 ----
    add(
      'Chemistry',
      'Class 11',
      'Chemistry_Class_11_Part_1',
      'kech101.pdf',
      1,
      'Some Basic Concepts of Chemistry',
    );
    add(
      'Chemistry',
      'Class 11',
      'Chemistry_Class_11_Part_1',
      'kech102.pdf',
      2,
      'Structure of Atom',
    );
    add(
      'Chemistry',
      'Class 11',
      'Chemistry_Class_11_Part_1',
      'kech103.pdf',
      3,
      'Classification of Elements and Periodicity in Properties',
    );
    add(
      'Chemistry',
      'Class 11',
      'Chemistry_Class_11_Part_1',
      'kech104.pdf',
      4,
      'Chemical Bonding and Molecular Structure',
    );
    add(
      'Chemistry',
      'Class 11',
      'Chemistry_Class_11_Part_1',
      'kech105.pdf',
      5,
      'States of Matter',
    );
    add(
      'Chemistry',
      'Class 11',
      'Chemistry_Class_11_Part_1',
      'kech106.pdf',
      6,
      'Thermodynamics',
    );
    add(
      'Chemistry',
      'Class 11',
      'Chemistry_Class_11_Part_1',
      'kech107.pdf',
      7,
      'Equilibrium',
    );
    add(
      'Chemistry',
      'Class 11',
      'Chemistry_Class_11_Part_2',
      'kech201.pdf',
      8,
      'Redox Reactions',
    );
    add(
      'Chemistry',
      'Class 11',
      'Chemistry_Class_11_Part_2',
      'kech202.pdf',
      9,
      'Hydrogen',
    );
    add(
      'Chemistry',
      'Class 11',
      'Chemistry_Class_11_Part_2',
      'kech203.pdf',
      10,
      'The s-Block Elements',
    );
    add(
      'Chemistry',
      'Class 11',
      'Chemistry_Class_11_Part_2',
      'kech204.pdf',
      11,
      'The p-Block Elements',
    );
    add(
      'Chemistry',
      'Class 11',
      'Chemistry_Class_11_Part_2',
      'kech205.pdf',
      12,
      'Organic Chemistry - Some Basic Principles and Techniques',
    );
    add(
      'Chemistry',
      'Class 11',
      'Chemistry_Class_11_Part_2',
      'kech206.pdf',
      13,
      'Hydrocarbons',
    );
    add(
      'Chemistry',
      'Class 11',
      'Chemistry_Class_11_Part_2',
      'kech207.pdf',
      14,
      'Environmental Chemistry',
    );

    // ---- Chemistry Class 12 ----
    add(
      'Chemistry',
      'Class 12',
      'Chemistry_Class_12_Part_1',
      'lech101.pdf',
      1,
      'The Solid State',
    );
    add(
      'Chemistry',
      'Class 12',
      'Chemistry_Class_12_Part_1',
      'lech102.pdf',
      2,
      'Solutions',
    );
    add(
      'Chemistry',
      'Class 12',
      'Chemistry_Class_12_Part_1',
      'lech103.pdf',
      3,
      'Electrochemistry',
    );
    add(
      'Chemistry',
      'Class 12',
      'Chemistry_Class_12_Part_1',
      'lech104.pdf',
      4,
      'Chemical Kinetics',
    );
    add(
      'Chemistry',
      'Class 12',
      'Chemistry_Class_12_Part_1',
      'lech105.pdf',
      5,
      'Surface Chemistry',
    );
    add(
      'Chemistry',
      'Class 12',
      'Chemistry_Class_12_Part_1',
      'lech106.pdf',
      6,
      'General Principles and Processes of Isolation of Elements',
    );
    add(
      'Chemistry',
      'Class 12',
      'Chemistry_Class_12_Part_1',
      'lech107.pdf',
      7,
      'The p-Block Elements',
    );
    add(
      'Chemistry',
      'Class 12',
      'Chemistry_Class_12_Part_2',
      'lech201.pdf',
      8,
      'The d- and f-Block Elements',
    );
    add(
      'Chemistry',
      'Class 12',
      'Chemistry_Class_12_Part_2',
      'lech202.pdf',
      9,
      'Coordination Compounds',
    );
    add(
      'Chemistry',
      'Class 12',
      'Chemistry_Class_12_Part_2',
      'lech203.pdf',
      10,
      'Haloalkanes and Haloarenes',
    );
    add(
      'Chemistry',
      'Class 12',
      'Chemistry_Class_12_Part_2',
      'lech204.pdf',
      11,
      'Alcohols, Phenols and Ethers',
    );
    add(
      'Chemistry',
      'Class 12',
      'Chemistry_Class_12_Part_2',
      'lech205.pdf',
      12,
      'Aldehydes, Ketones and Carboxylic Acids',
    );
    add(
      'Chemistry',
      'Class 12',
      'Chemistry_Class_12_Part_2',
      'lech206.pdf',
      13,
      'Amines',
    );
    add(
      'Chemistry',
      'Class 12',
      'Chemistry_Class_12_Part_2',
      'lech207.pdf',
      14,
      'Biomolecules',
    );

    // ---- Physics Class 11 ----
    add(
      'Physics',
      'Class 11',
      'Physics_Class_11_Part_1',
      'keph101.pdf',
      1,
      'Physical World',
    );
    add(
      'Physics',
      'Class 11',
      'Physics_Class_11_Part_1',
      'keph102.pdf',
      2,
      'Units and Measurements',
    );
    add(
      'Physics',
      'Class 11',
      'Physics_Class_11_Part_1',
      'keph103.pdf',
      3,
      'Motion in a Straight Line',
    );
    add(
      'Physics',
      'Class 11',
      'Physics_Class_11_Part_1',
      'keph104.pdf',
      4,
      'Motion in a Plane',
    );
    add(
      'Physics',
      'Class 11',
      'Physics_Class_11_Part_1',
      'keph105.pdf',
      5,
      'Laws of Motion',
    );
    add(
      'Physics',
      'Class 11',
      'Physics_Class_11_Part_1',
      'keph106.pdf',
      6,
      'Work, Energy and Power',
    );
    add(
      'Physics',
      'Class 11',
      'Physics_Class_11_Part_1',
      'keph107.pdf',
      7,
      'System of Particles and Rotational Motion',
    );
    add(
      'Physics',
      'Class 11',
      'Physics_Class_11_Part_2',
      'keph201.pdf',
      8,
      'Gravitation',
    );
    add(
      'Physics',
      'Class 11',
      'Physics_Class_11_Part_2',
      'keph202.pdf',
      9,
      'Mechanical Properties of Solids',
    );
    add(
      'Physics',
      'Class 11',
      'Physics_Class_11_Part_2',
      'keph203.pdf',
      10,
      'Mechanical Properties of Fluids',
    );
    add(
      'Physics',
      'Class 11',
      'Physics_Class_11_Part_2',
      'keph204.pdf',
      11,
      'Thermal Properties of Matter',
    );
    add(
      'Physics',
      'Class 11',
      'Physics_Class_11_Part_2',
      'keph205.pdf',
      12,
      'Thermodynamics',
    );
    add(
      'Physics',
      'Class 11',
      'Physics_Class_11_Part_2',
      'keph206.pdf',
      13,
      'Kinetic Theory',
    );
    add(
      'Physics',
      'Class 11',
      'Physics_Class_11_Part_2',
      'keph207.pdf',
      14,
      'Oscillations',
    );

    // ---- Physics Class 12 ----
    add(
      'Physics',
      'Class 12',
      'Physics_Class_12_Part_1',
      'leph101.pdf',
      1,
      'Electric Charges and Fields',
    );
    add(
      'Physics',
      'Class 12',
      'Physics_Class_12_Part_1',
      'leph102.pdf',
      2,
      'Electrostatic Potential and Capacitance',
    );
    add(
      'Physics',
      'Class 12',
      'Physics_Class_12_Part_1',
      'leph103.pdf',
      3,
      'Current Electricity',
    );
    add(
      'Physics',
      'Class 12',
      'Physics_Class_12_Part_1',
      'leph104.pdf',
      4,
      'Moving Charges and Magnetism',
    );
    add(
      'Physics',
      'Class 12',
      'Physics_Class_12_Part_1',
      'leph105.pdf',
      5,
      'Magnetism and Matter',
    );
    add(
      'Physics',
      'Class 12',
      'Physics_Class_12_Part_1',
      'leph106.pdf',
      6,
      'Electromagnetic Induction',
    );
    add(
      'Physics',
      'Class 12',
      'Physics_Class_12_Part_1',
      'leph107.pdf',
      7,
      'Alternating Current',
    );
    add(
      'Physics',
      'Class 12',
      'Physics_Class_12_Part_2',
      'leph201.pdf',
      8,
      'Electromagnetic Waves',
    );
    add(
      'Physics',
      'Class 12',
      'Physics_Class_12_Part_2',
      'leph202.pdf',
      9,
      'Ray Optics and Optical Instruments',
    );
    add(
      'Physics',
      'Class 12',
      'Physics_Class_12_Part_2',
      'leph203.pdf',
      10,
      'Wave Optics',
    );
    add(
      'Physics',
      'Class 12',
      'Physics_Class_12_Part_2',
      'leph204.pdf',
      11,
      'Dual Nature of Radiation and Matter',
    );
    add(
      'Physics',
      'Class 12',
      'Physics_Class_12_Part_2',
      'leph205.pdf',
      12,
      'Atoms',
    );
    add(
      'Physics',
      'Class 12',
      'Physics_Class_12_Part_2',
      'leph206.pdf',
      13,
      'Nuclei',
    );
    add(
      'Physics',
      'Class 12',
      'Physics_Class_12_Part_2',
      'leph207.pdf',
      14,
      'Semiconductor Electronics: Materials, Devices and Simple Circuits',
    );

    return list;
  }

  /// Resolves the official NCERT PDF for an app chapter.
  static NcertBookEntry? entryFor(Chapter chapter) {
    final direct = _appChapterPdf[chapter.id];
    if (direct != null) {
      return _entries.where((e) => e.assetPath == direct).firstOrNull;
    }
    return _matchByName(chapter);
  }

  static bool isAvailable(Chapter chapter) => entryFor(chapter) != null;

  /// All chapters belonging to the same physical book as [entry], in NCERT
  /// chapter order (used for the in-reader chapter sidebar).
  static List<NcertBookEntry> chaptersOfBook(NcertBookEntry entry) {
    final chapters = _entries
        .where(
          (e) => e.subject == entry.subject && e.classLevel == entry.classLevel,
        )
        .toList();
    chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    return chapters;
  }

  static NcertBookEntry? _matchByName(Chapter chapter) {
    final appName = _normalize(chapter.name);
    if (appName.length < 5) return null;
    final entries = _entries.where(
      (e) =>
          e.subject == subjectNameFor(chapter.subjectId) &&
          e.classLevel == chapter.classLevel,
    );
    for (final e in entries) {
      final title = _normalize(e.chapterTitle);
      if (appName == title ||
          title.contains(appName) ||
          appName.contains(title)) {
        return e;
      }
    }
    return null;
  }

  static String subjectNameFor(String subjectId) {
    switch (subjectId) {
      case 'bio':
        return 'Biology';
      case 'chem':
        return 'Chemistry';
      case 'phys':
        return 'Physics';
      default:
        return subjectId;
    }
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
