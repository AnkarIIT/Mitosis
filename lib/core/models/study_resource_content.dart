class StudyResourceContent {
  final String chapterId;
  final String overview;
  final List<String> keyFacts;
  final List<String> formulas;
  final List<String> diagrams;
  final List<String> pyqTraps;
  final List<String> revisionRules;

  const StudyResourceContent({
    required this.chapterId,
    required this.overview,
    this.keyFacts = const [],
    this.formulas = const [],
    this.diagrams = const [],
    this.pyqTraps = const [],
    this.revisionRules = const [],
  });

  bool get hasAuthoredContent =>
      keyFacts.isNotEmpty ||
      formulas.isNotEmpty ||
      diagrams.isNotEmpty ||
      pyqTraps.isNotEmpty ||
      revisionRules.isNotEmpty;
}

const studyResourceContent = <String, StudyResourceContent>{
  'bio_ch1': StudyResourceContent(
    chapterId: 'bio_ch1',
    overview:
        'The Living World links the defining properties of life with the tools used to identify and classify biodiversity.',
    keyFacts: [
      'Metabolism is the sum total of all chemical reactions in a living organism.',
      'Growth by cell division is a defining property; crystal growth is not biological growth.',
      'Species is the basic unit of classification and a taxonomic category.',
      'A scientific name has a generic name followed by a specific epithet.',
    ],
    diagrams: [
      'Taxonomic hierarchy: Kingdom → Phylum/Division → Class → Order → Family → Genus → Species.',
      'Herbarium workflow: collection → pressing → drying → mounting → labelling → preservation.',
    ],
    pyqTraps: [
      'Do not confuse a taxonomic category (species) with the taxon (a group of organisms).',
      'Reproduction is not an all-inclusive defining property because mules and worker bees do not reproduce.',
    ],
    revisionRules: [
      'Read NCERT examples of taxonomic aids before attempting assertion questions.',
      'Memorise the hierarchy in both directions and practise identifying the immediate higher category.',
    ],
  ),
  'bio_ch8': StudyResourceContent(
    chapterId: 'bio_ch8',
    overview:
        'Cell: The Unit of Life compares prokaryotic and eukaryotic organisation and connects organelle structure to function.',
    keyFacts: [
      'Prokaryotes lack a membrane-bound nucleus and membrane-bound organelles.',
      'Ribosomes are non-membranous; 70S occur in prokaryotes and 80S in eukaryotic cytoplasm.',
      'Mitochondria and chloroplasts contain their own DNA and 70S ribosomes.',
      'The plasma membrane follows the fluid mosaic model and is selectively permeable.',
    ],
    diagrams: [
      'Prokaryotic cell labels: capsule, cell wall, plasma membrane, nucleoid, ribosomes, pili and flagellum.',
      'Endomembrane flow: ER → transport vesicle → Golgi → secretory vesicle/lysosome.',
    ],
    pyqTraps: [
      'Mesosome descriptions in older NCERT text should not be treated as a modern independent organelle.',
      'Do not interchange lysosome digestion with peroxisome oxidation and hydrogen peroxide breakdown.',
    ],
    revisionRules: [
      'Make a two-column organelle table: structure, membrane count, and primary function.',
      'Practise diagram labelling without looking at the textbook before reviewing mistakes.',
    ],
  ),
  'chem_ch1': StudyResourceContent(
    chapterId: 'chem_ch1',
    overview:
        'Basic Concepts of Chemistry builds the mole framework used in stoichiometry, concentration and limiting-reagent questions.',
    keyFacts: [
      'One mole contains 6.022 × 10²³ specified entities.',
      'Molarity is moles of solute per litre of solution; it changes with temperature.',
      'Molality is moles of solute per kilogram of solvent; it is temperature independent.',
      'The limiting reagent is consumed first and determines the maximum product formed.',
    ],
    formulas: [
      'n = given mass / molar mass',
      'M = moles of solute / volume of solution in litre',
      'm = moles of solute / mass of solvent in kilogram',
      'M₁V₁ = M₂V₂ for dilution of the same solute',
      '% yield = (actual yield / theoretical yield) × 100',
    ],
    pyqTraps: [
      'Use solvent mass for molality and solution volume for molarity.',
      'Balance the chemical equation before applying mole ratios.',
    ],
    revisionRules: [
      'Write units beside every quantity before substituting into a formula.',
      'Check whether the question asks for atoms, molecules, ions or moles before converting.',
    ],
  ),
  'phys_ch2': StudyResourceContent(
    chapterId: 'phys_ch2',
    overview:
        'Units and Measurements provides the dimensional and uncertainty tools used to validate every Physics calculation.',
    keyFacts: [
      'A dimensionally correct equation is necessary but not sufficient to prove an equation correct.',
      'Relative error is absolute error divided by the measured value.',
      'In addition and subtraction, absolute errors are added; in multiplication and division, relative errors are added.',
      'Significant figures communicate the precision justified by a measurement.',
    ],
    formulas: [
      '[velocity] = LT⁻¹ and [acceleration] = LT⁻²',
      '[force] = MLT⁻² and [work] = ML²T⁻²',
      '% relative error = (absolute error / measured value) × 100',
      'For z = xᵃyᵇ, Δz/z = |a|Δx/x + |b|Δy/y',
    ],
    pyqTraps: [
      'Do not use dimensional analysis to determine dimensionless numerical constants such as 2 or π.',
      'Round only at the final step unless the question explicitly specifies a precision.',
    ],
    revisionRules: [
      'Keep a one-page SI base-unit and derived-unit table.',
      'Use dimensions as a fast check after solving, not as a replacement for the physical argument.',
    ],
  ),
};
