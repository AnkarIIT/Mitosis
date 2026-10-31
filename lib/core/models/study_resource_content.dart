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
    diagrams: [
      'Mole map: mass ⇌ moles ⇌ particles with Avogadro\'s number (6.022 × 10²³) as the hub.',
      'Concentration ladder: molarity, molality, mole fraction and ppm — each with its denominator spelled out.',
      'Stoichiometry pipeline: balance the equation → find the limiting reagent → theoretical yield → % yield.',
      'Dilution visual: M₁V₁ = M₂V₂ as adding solvent (not solute) to an existing solution.',
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
    diagrams: [
      'SI base-quantity wheel: length, mass, time, current, temperature, amount of substance, luminous intensity.',
      'Error-propagation table: addition/subtraction → absolute errors add; multiplication/division → relative errors add.',
      'Dimensional-analysis flow: write the expression → substitute dimensions → check homogeneity across the equality.',
      'Measurement instruments strip: metre scale, vernier caliper, screw gauge with their least counts.',
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
  'bio_ch9': StudyResourceContent(
    chapterId: 'bio_ch9',
    overview:
        'Biomolecules maps the chemical composition of living tissue: micromolecules vs macromolecules, the four classes of biomacromolecules, and the enzyme machinery that drives metabolism.',
    keyFacts: [
      'Water is the most abundant chemical in living tissue; carbon, hydrogen, oxygen and nitrogen together make up most of the remaining mass.',
      'An acid-soluble pool yields micromolecules (amino acids, sugars, nucleotides); the acid-insoluble fraction is the macromolecular pool (proteins, nucleic acids, polysaccharides, lipids).',
      'An amino acid is a substituted methane: central carbon carries H, NH₂, COOH and a variable R group; at physiological pH it exists as a zwitterion.',
      'A peptide bond (–CO–NH–) links amino acids; protein structure has four levels: primary (sequence), secondary (α-helix, β-sheet via H-bonds), tertiary (3-D folding) and quaternary (multi-subunit, e.g. haemoglobin = 2α + 2β).',
      'Sucrose (glucose + fructose) is a non-reducing sugar; lactose = galactose + glucose; maltose = glucose + glucose; inulin is a polymer of fructose.',
      'Starch has α-glycosidic linkages and cellulose β-glycosidic linkages; glycogen is the highly branched animal storage polysaccharide.',
      'A nucleotide = nitrogenous base + pentose sugar + phosphate; a nucleoside lacks the phosphate. DNA has deoxyribose and thymine; RNA has ribose and uracil.',
      'Lipids are water-insoluble: simple lipids (fats: glycerol + fatty acids), compound lipids (phospholipids, glycolipids) and derived lipids (cholesterol, steroids).',
      'Enzymes are almost all proteins except ribozymes (RNA catalysts) and nucleic acids with enzyme-like activity.',
      'Enzymes lower activation energy; the substrate binds a specific active site forming the transient enzyme–substrate complex.',
      'Cofactors: a prosthetic group is organic and tightly bound (haeme in catalase/peroxidase), a coenzyme is organic and loosely bound (NAD, NADP), and metal activators include Zn²⁺ (carboxypeptidase), Mo (nitrogenase) and Ni (urease).',
      'Metabolism has catabolic (breakdown, releases energy) and anabolic (synthesis, consumes energy) pathways; ATP is the energy currency linking them.',
    ],
    formulas: [
      'Michaelis-style rate logic: rate rises with substrate till the active sites saturate (V_max plateau).',
      'Competitive inhibition: malonate mimics succinate and competes for succinate dehydrogenase.',
      'Glycosidic bond: monosaccharide + monosaccharide − H₂O → disaccharide.',
      'Ester bond: glycerol + 3 fatty acids − 3H₂O → triglyceride.',
    ],
    diagrams: [
      'Composition flowchart: tissue → acid-soluble (micromolecules) / acid-insoluble (macromolecules).',
      'Secondary structure: α-helix H-bonds within one chain segment; β-sheet H-bonds between neighbouring strands.',
      'Lock-and-key: substrate → active site → ES complex → product → free enzyme (unchanged).',
      'Nucleotide anatomy: base + sugar = nucleoside; + phosphate (phosphodiester links) = nucleic acid backbone.',
    ],
    pyqTraps: [
      'Haeme is a prosthetic group (organic + tightly bound), NOT a coenzyme — NAD/NADP are the coenzyme examples.',
      'The amino-acid count is edition-dependent: older printings say 20, revised NCERT says 21 — read the question key with the edition in mind.',
      'Do not interchange α (starch) with β (cellulose) glycosidic linkages — humans cannot digest β-linkages.',
      'Growth of crystals and increase in mass of non-living matter is NOT biological growth; only growth by cell division counts.',
      'Ribozymes are RNA, so "all enzymes are proteins" is false — a classic assertion–reason trap.',
    ],
    revisionRules: [
      'Build a one-page table: biomolecule class → monomer → bond → example.',
      'Memorise the enzyme-metal-ion cofactor pairs as flashcards (Zn–carboxypeptidase, Mo–nitrogenase, Ni–urease).',
      'Practise sorting sugars into reducing vs non-reducing before every mock.',
    ],
  ),
  'bio_ch10': StudyResourceContent(
    chapterId: 'bio_ch10',
    overview:
        'Cell Cycle and Cell Division sequences interphase and the M-phase, then contrasts mitosis (equational) with meiosis I (reductional) and meiosis II (equational).',
    keyFacts: [
      'A typical human cell cycle runs ~24 hours; yeast completes it in ~90 minutes.',
      'Interphase = G₁ (growth), S (DNA replication — DNA content doubles, chromosome number unchanged), G₂ (proteins for mitosis assembled).',
      'Cells such as heart cells withdraw from the cycle into the quiescent G₀ phase.',
      'Mitosis stages: prophase (condensation), metaphase (chromosomes at the equatorial plate, spindle attached to kinetochores), anaphase (centromeres split — shortest stage), telophase (nuclear envelope reforms).',
      'Cytokinesis is by cell plate formation in plants and by furrowing in animals; mitosis enables growth, repair and identical daughter cells.',
      'Meiosis I is reductional: leptotene → zygotene (synapsis, synaptonemal complex, bivalent/tetrad) → pachytene (crossing over via recombination nodules) → diplotene (chiasmata visible) → diakinesis (terminalisation).',
      'In human oocytes the prolonged diplotene arrest persists until ovulation — a favourite assertion–reason fact.',
      'Anaphase I separates homologous chromosomes with centromeres INTACT; interkinesis between the two divisions has NO DNA replication.',
      'Meiosis II is equational and mitosis-like: sister chromatids separate.',
      'Meiosis conserves the chromosome number across generations and creates genetic variability by crossing over and independent assortment.',
    ],
    formulas: [
      'After S phase: DNA content ×2 (4C), chromosome number unchanged (2n).',
      'After meiosis I: both DNA and chromosome number halved (2C, n).',
      'After meiosis II: chromosome number remains n; sister chromatids separate and the DNA content halves again.',
    ],
    diagrams: [
      'Cell-cycle pie: G₁, S, G₂ dominate; M-phase is a small slice.',
      'Prophase-I timeline with the five substages and what "appears" in each.',
      'Mitosis vs meiosis comparison ladder (chromosome behaviour at anaphase).',
    ],
    pyqTraps: [
      'Crossing over occurs at PACHYTENE, but chiasmata become visible only at DIPLOTENE.',
      'The centromere splits in anaphase of mitosis and anaphase II — NEVER in anaphase I.',
      'No DNA replication happens during interkinesis between meiosis I and II.',
      'In prophase I the synaptonemal complex forms at zygotene, not pachytene.',
      '"Daughter cells identical" describes mitosis; meiosis II daughter cells are only identical to the meiosis-I products, not to the parent cell.',
    ],
    revisionRules: [
      'Rehearse the prophase-I order as a fixed chant: Le-Zy-Pa-Di-Dia.',
      'Draw the anaphase-I vs anaphase-II contrast side by side until centromere behaviour is automatic.',
      'Tabulate G₁/S/G₂ events with DNA content and chromosome number for each phase.',
    ],
  ),
  'bio_ch6_12': StudyResourceContent(
    chapterId: 'bio_ch6_12',
    overview:
        'Molecular Basis of Inheritance is the highest-yield Genetics chapter: experiments proving DNA is the genetic material, double-helix structure, replication, transcription, the genetic code, translation, the lac operon and DNA fingerprinting.',
    keyFacts: [
      'Griffith (1928) found the "transforming principle"; Avery–MacLeod–McCarty confirmed it as DNA; Hershey–Chase proved DNA (³²P) enters bacteria while protein (³⁵S) does not.',
      'Watson–Crick double helix: right-handed, antiparallel, 3.4 nm pitch, 10 base pairs per turn, 0.34 nm rise per base pair; A=T with 2 hydrogen bonds, G≡C with 3.',
      'Central dogma: DNA → RNA → protein; retroviruses (e.g. HIV) add RNA → DNA reverse transcription.',
      'Replication is semi-conservative (Meselson–Stahl in E. coli); synthesis is 5′→3′ with a continuous leading strand and discontinuous lagging strand joined by DNA ligase.',
      'A transcription unit = promoter + structural gene + terminator; the template strand reads 3′→5′ and the coding strand 5′→3′ (mRNA matches the coding strand with U for T).',
      'Eukaryotic RNA polymerase II makes hnRNA, processed by capping (7-methylguanosine 5′), tailing (poly-A 3′) and splicing (introns out, exons joined) into mRNA.',
      'Genetic code: triplet, 61 sense + 3 stop codons; AUG both initiates and codes methionine; degenerate yet unambiguous; universal with rare exceptions; comma-less.',
      'tRNA is the adapter molecule: cloverleaf shape, anticodon loop and CCA amino-acid acceptor end.',
      'Translation: initiation (AUG + initiator tRNA), elongation (peptidyl transferase is a ribozyme — 23S rRNA in prokaryotes), translocation, termination by release factors.',
      'Lac operon is inducible: the Lac-I repressor is constitutive, allolactose is the inducer, and low glucose adds positive control via CAP–cAMP; the trp operon is its repressible mirror image.',
      'Human Genome Project: ~3 × 10⁹ base pairs, ~20,000–25,000 genes, <2% coding, plus ~1.4 million SNPs catalogued.',
      'DNA fingerprinting (Alec Jeffreys) exploits polymorphism in satellite DNA: VNTR (minisatellite) and STR (microsatellite) repeats.',
    ],
    formulas: [
      'Bases per helix turn: 10 bp × 0.34 nm = 3.4 nm pitch.',
      'Codons: 4³ = 64 total → 61 sense + 3 nonsense (stop).',
      'Complementarity: A=T (2 H-bonds) vs G≡C (3 H-bonds) → GC-rich DNA has a higher melting point.',
    ],
    diagrams: [
      'Central dogma with reverse-transcription dashed arrow for retroviruses.',
      'Replication fork: leading continuous vs lagging Okazaki fragments + ligase.',
      'Lac operon in both states: repressor ON (OFF state) and inducer-bound repressor released (ON state).',
      'Transcription unit anatomy: promoter, template vs coding strand, terminator.',
    ],
    pyqTraps: [
      'Hershey–Chase: ³⁵S labels PROTEIN and ³²P labels DNA — students routinely swap them.',
      'The mRNA sequence equals the CODING (sense) strand, not the template strand.',
      'RNA polymerase II transcribes hnRNA/mRNA; pol I makes rRNA and pol III makes tRNA — never mix these.',
      'AUG is BOTH the initiator codon and the codon for methionine — a pairing trap.',
      'In the lac operon the repressor gene is expressed constitutively; only the structural genes are inducible.',
      'Okazaki fragments are joined by DNA LIGASE, not by DNA polymerase.',
    ],
    revisionRules: [
      'Draw the lac operon in both states from memory before every mock.',
      'Keep a codon-table drill: stop codons, start codon, degeneracy examples.',
      'Tabulate the three RNA polymerases with their products once and re-read daily.',
    ],
  ),
  'bio_ch7_12': StudyResourceContent(
    chapterId: 'bio_ch7_12',
    overview:
        'Evolution traces the origin of life (chemical evolution, RNA world), the theories of evolution (Lamarck, Darwin, de Vries mutation theory), population genetics (Hardy–Weinberg) and the human-evolution timeline.',
    keyFacts: [
      'Universe formed ~13.8 billion years ago (Big Bang); Earth ~4.5 bya; the first self-replicating cells appeared roughly 3.8–4.0 bya; RNA world is the favoured first-genome hypothesis.',
      'Miller (1953) sparked CH₄ + NH₃ + H₂ + H₂O vapour and obtained amino acids — evidence for chemical evolution in a reducing atmosphere.',
      'Spontaneous generation was refuted by Louis Pasteur (swan-neck flask); panspermia places life’s origin in outer space.',
      'Lamarck: use/disuse and inheritance of acquired characters (giraffe neck) — discarded; Darwin: natural selection with survival of the fittest (term by Herbert Spencer) and branching descent.',
      'Hugo de Vries’ mutation theory (evening primrose) stressed saltation — sudden, large, discontinuous variations, an alternative to gradual Darwinian change.',
      'Hardy–Weinberg equilibrium: p² + 2pq + q² = 1 in an ideal large, randomly mating, unselected population; five forces disturb it — gene migration, mutation, genetic recombination, genetic drift and natural selection.',
      'Natural selection types: stabilising (favours the intermediate), directional (favours one extreme) and disruptive (favours both extremes).',
      'Industrial melanism of the peppered moth (Biston betularia) is the standard directional-selection example; Darwin’s finches and Australian marsupials illustrate adaptive radiation.',
      'Homology = common ancestry with divergent evolution (forelimbs of human/bat/whale; thorn of Bougainvillea vs tendril of Cucurbita); analogy = convergent evolution (wings of bird vs butterfly/bat-flap debates, eyes of octopus vs mammal).',
      'Vestigial organs: vermiform appendix, wisdom teeth, nictitating membrane — evolutionary leftovers.',
      'Human lineage: Dryopithecus/Ramapithecus → Australopithecus (~2 mya) → Homo habilis (650–800 cc brain) → Homo erectus (Java man, ~900 cc) → Neanderthal man (~1400 cc) → Cro-Magnon → modern Homo sapiens (last ice age).',
    ],
    formulas: [
      'Hardy–Weinberg: p + q = 1 and p² + 2pq + q² = 1.',
      'Heterozygote frequency = 2pq; homozygous dominant = p²; recessive phenotype = q².',
    ],
    diagrams: [
      'Hardy–Weinberg bar of genotype frequencies shifting toward disruptive/directional extremes.',
      'Darwin’s finch beak evolution tree (adaptive radiation).',
      'Human-evolution timeline with brain volumes on a scale.',
    ],
    pyqTraps: [
      'Wings of a bird and a butterfly are ANALOGOUS (convergent); thorn of Bougainvillea and tendril of Cucurbita are HOMOLOGOUS — both axial-position modifications.',
      'De Vries’ saltation is NOT the gradual accumulation Darwin described — MCQs love this contrast.',
      'Genetic drift is random and strongest in SMALL populations (founder effect, bottleneck).',
      'Hardy–Weinberg holds only with no selection, no mutation, no migration, random mating and an infinitely large population.',
      'Neanderthal and Cro-Magnon are not the same as modern man — order and brain volumes are tested directly.',
    ],
    revisionRules: [
      'Maintain a two-column analogy/homology example bank and add every new MCQ you meet.',
      'Practise 3–4 Hardy–Weinberg numericals: given q² find q, p and 2pq.',
      'Chant the human-evolution chain with brain volumes until it is rote.',
    ],
  ),
  'chem_ch2': StudyResourceContent(
    chapterId: 'chem_ch2',
    overview:
        'Structure of Atom takes the atomic model from Thomson and Rutherford to Bohr, de Broglie, Heisenberg and Schrödinger, ending with quantum numbers, orbital shapes and electron-configuration rules.',
    keyFacts: [
      'Rutherford’s α-scattering showed the atom is mostly empty with a tiny, dense, positive nucleus; Bohr quantised orbits; multi-electron spectra forced the quantum-mechanical model.',
      'Electromagnetic radiation: c = νλ and E = hν with h = 6.626 × 10⁻³⁴ J s; the photoelectric effect needs a threshold frequency ν₀ and ejects electrons with KE = hν − hν₀.',
      'Hydrogen spectrum series: Lyman (UV, to n=1), Balmer (visible, to n=2), Paschen, Brackett, Pfund (IR, to n=3,4,5).',
      'Bohr model: angular momentum mvr = nh/2π; radius rₙ = 0.529 n²/Z Å; energy Eₙ = −2.18 × 10⁻¹⁸ Z²/n² J; energy depends only on n for H, so 3s = 3p = 3d there.',
      'de Broglie: every particle has λ = h/mv = h/p; Heisenberg: Δx·Δp ≥ h/4π — position and momentum cannot both be exact.',
      'Schrödinger’s ψ² is the probability density; an orbital is the region of ~90–95% probability, NOT a fixed path.',
      'Quantum numbers: n (energy/size), l = 0…n−1 (s, p, d, f shapes), m = −l…+l (2l+1 orientations), s = ±½ (spin).',
      'Nodes: radial = n − l − 1, angular = l, total = n − 1 (e.g. 3p: 1 radial, 1 angular).',
      'Filling rules: Aufbau (lower n+l first), Pauli (no two electrons share all four quantum numbers), Hund (maximum multiplicity within a degenerate subshell).',
      'Exceptions to memorise: Cr = [Ar] 3d⁵ 4s¹ and Cu = [Ar] 3d¹⁰ 4s¹ — half-filled/fully-filled stability via exchange energy.',
      'Shell capacity: 2n² electrons, n² orbitals; subshell capacity 2(2l+1) → s=2, p=6, d=10, f=14.',
    ],
    formulas: [
      'E = hν = hc/λ (photon energy).',
      'Photoelectric: KE_max = hν − hν₀ = h(ν − ν₀).',
      'Rydberg: ν̄ = R_H Z² (1/n₁² − 1/n₂²), R_H ≈ 109,677 cm⁻¹.',
      'Bohr radius: rₙ = 0.529 n²/Z Å; Bohr energy: Eₙ = −2.18 × 10⁻¹⁸ Z²/n² J.',
      'de Broglie: λ = h/mv; Heisenberg: Δx·Δp ≥ h/4π.',
    ],
    diagrams: [
      'Model-progression sketch: Thomson → Rutherford → Bohr → quantum mechanical.',
      's (spherical), p (dumbbell), d (cloverleaf) orbital shapes with axis orientations.',
      'Energy-order diagram with n+l rule arrows (1s, 2s, 2p, 3s, 3p, 4s, 3d, 4p…).',
    ],
    pyqTraps: [
      '4s fills BEFORE 3d (n+l rule) but 4s is removed first on ionisation of transition metals.',
      'Bohr’s Eₙ depends ONLY on n for hydrogen-like species — 3s, 3p, 3d are equal in energy there, unlike multi-electron atoms.',
      'n = 3, l = 2, m = ±2 is a VALID (3d) set; l can never equal n and m can never exceed |l|.',
      'Number of radial nodes = n − l − 1 and angular = l; total nodes = n − 1 — students set 3d radial nodes to 1, it is 0.',
      'Zeeman and Stark effects (splitting in magnetic/electric fields) are limitations of the Bohr model, not confirmations.',
    ],
    revisionRules: [
      'Write configurations of the first 30 elements weekly; Cr and Cu must be instant recalls.',
      'Drill quantum-number validity: count orbits/orbitals/electrons for a given n and l.',
      'Convert between ν, λ and E units (J ↔ eV ↔ cm⁻¹) until automatic.',
    ],
  ),
  'phys_ch3': StudyResourceContent(
    chapterId: 'phys_ch3',
    overview:
        'Motion in a Straight Line builds the kinematic toolkit: distance vs displacement, average vs instantaneous velocity and acceleration, the three equations of motion, free fall and v–t graph reading.',
    keyFacts: [
      'Path length (distance) is a scalar and never decreases; displacement is a vector and can be zero or negative — |displacement| ≤ distance.',
      'Average velocity = Δx/Δt (can be zero on an out-and-back trip); average speed = path length/Δt (never below |avg velocity|).',
      'Instantaneous velocity is the slope of the x–t graph; instantaneous acceleration is the slope of the v–t graph.',
      'Uniform motion → straight-line x–t graph and horizontal v–t graph; uniformly accelerated motion → parabolic x–t graph and straight v–t graph.',
      'In a v–t graph the AREA under the curve is displacement (negative below the time axis) and the SLOPE is acceleration.',
      'Free fall: g ≈ 9.8 m s⁻²; fall time t = √(2h/g) independent of mass; thrown upward, max height H = u²/2g, rise time = u/g, total flight = 2u/g.',
      'Relative velocity: v_AB = v_A − v_B; two bodies move together when relative velocity is zero.',
      'Stopping distance grows with the square of speed — doubling speed quadruples the stopping distance (thinking time adds extra distance).',
    ],
    formulas: [
      'v = u + at',
      's = ut + ½at²',
      'v² = u² + 2as',
      'Distance in the nth second: sₙ = u + a(2n − 1)/2',
      'Free fall: h = ½gt², v = gt, v² = 2gh',
      'Projectile straight up: H = u²/2g, T_total = 2u/g',
    ],
    diagrams: [
      'Three-panel x–t: at rest / uniform / accelerating.',
      'v–t area-under-curve with negative shaded region for reverse motion.',
      'Journey sketch of a toss: velocity sign flips at the top, acceleration stays −g throughout.',
    ],
    pyqTraps: [
      'Acceleration does NOT become zero at the top of a vertical throw — velocity does; acceleration stays g downward.',
      'Average velocity can be zero while average speed is not (round trip).',
      'Area under v–t below the time axis is NEGATIVE displacement — include the sign.',
      'A body can have zero velocity and still be accelerating (top of throw, peak of oscillation).',
      'Do not assume instantaneous = average unless motion is uniform.',
    ],
    revisionRules: [
      'Sketch the v–t graph FIRST for every problem; nearly all quantities read off it.',
      'Substitute with units attached and check dimensional consistency of each term.',
      'Re-derive all three equations from the definition a = dv/dt as a self-test before mocks.',
    ],
  ),
  'bio_ch2': StudyResourceContent(
    chapterId: 'bio_ch2',
    overview:
        'Biological Classification runs through the five-kingdom system of Whittaker, the members of Monera/Protista/Fungi, and the acellular agents — viruses, viroids and prions.',
    keyFacts: [
      'Whittaker (1969) used five criteria: cell structure, body organisation, mode of nutrition, reproduction and phylogenetic relationships.',
      'Archaebacteria survive extremes: halophiles (salt), thermoacidophiles (hot springs) and methanogens (marshes and the rumen of cattle, producing methane).',
      'Cyanobacteria fix atmospheric nitrogen in specialised heterocysts (e.g. Anabaena, Nostoc); Mycoplasma is the smallest living cell and completely lacks a cell wall.',
      'Bacterial "sexual" reproduction is not true sexuality: conjugation transfers DNA without gamete formation; binary fission is the main multiplication mode.',
      'Protista are all unicellular eukaryotes: chrysophytes (diatoms, desmids), dinoflagellates (cause red tides), euglenoids, slime moulds and protozoans.',
      'Euglenoids have a protein-rich pellicle instead of a cellulose wall and are mixotrophic — photosynthetic in light,saprophytic in dark (Euglena classic).',
      'Slime moulds feed as an amoeboid plasmodium and reproduce via spores with cellulose walls borne in fruiting bodies.',
      'Fungi have chitin cell walls; classes run Phycomycetes (coenocytic, aquatic — Rhizopus, Mucor) → Ascomycetes (ascus with ascospores — yeast, Penicillium, Neurospora) → Basidiomycetes (basidiospores — rusts, smuts, mushrooms, puffballs) → Deuteromycetes (imperfect, sexual stage unknown).',
      'Lichen = alga (phycobiont, food producer) + fungus (mycobiont, shelter/minerals)/(poor examples clarified below); lichens are excellent pollution indicators.',
      'Viruses are obligate intracellular nucleoprotein parasites: plant viruses are mostly ssRNA (e.g. TMV), bacteriophages are usually dsDNA.',
      'Viroids are free infectious RNA without a protein coat (Diener — potato spindle tuber disease); prions are infectious PROTEINS (BSE mad-cow disease, scrapie).',
    ],
    diagrams: [
      'Five-kingdom ladder with the three criteria arrows (nutrition + organisation + cell type).',
      'Bacterial shapes strip: coccus, bacillus, vibrio, spirillum.',
      'Lichen cross-section: algal layer + fungal hyphae interwoven.',
      'Agent contrast table: virus (RNA/DNA + coat) vs viroid (naked RNA) vs prion (protein only).',
    ],
    pyqTraps: [
      'Methanogens live in the RUMEN of cattle and produce methane — marshes too; they are archaebacteria, not typical bacteria.',
      'Mycoplasma has NO cell wall, so wall-inhibiting antibiotics (penicillins) do not work on it.',
      'Euglena: pellicle is proteinaceous, NOT cellulose; it is photosynthetic but also facultatively heterotrophic.',
      'Slime moulds lack a cell wall in the vegetative plasmodium stage — the wall appears only on the spores.',
      'Prions are purely protein (no nucleic acid) — the exact reverse of viroids (naked RNA, no protein).',
      'Conjugation in bacteria is NOT sexual reproduction because male gametes are not produced.',
    ],
    revisionRules: [
      'Build one table per kingdom: category → wall chemistry → nutrition → one example.',
      'Chant the disease-agent pairs: malaria–Plasmodium, sleeping sickness–Trypanosoma, typhoid–Salmonella, whooping cough–Bordetella.',
      'Rehearse the virus/viroid/prion contrast as a three-row flashcard before every mock.',
    ],
  ),
  'bio_ch3': StudyResourceContent(
    chapterId: 'bio_ch3',
    overview:
        'Plant Kingdom classifies algae, bryophytes, pteridophytes and gymnosperms, then ties each group to its life-cycle pattern in the alternation of generations.',
    keyFacts: [
      'Algae classes by pigment: Chlorophyceae (green — Chlamydomonas, Volvox, Spirogyra, Ulothrix), Phaeophyceae (brown — fucoxanthin; Ectocarpus, Fucus, Sargassum; store mannitol/laminarin), Rhodophyceae (red — r-phycoerythrin; Gracilaria, Gelidium, Polysiphonia; store floridean starch).',
      'Commercial products: agar from Gelidium/Gracilaria (red algae); algin (brown); carrageen (red); Chlorella is a protein supplement and even a space-food candidate.',
      'Bryophytes are the amphibians of the plant world: the dominant phase is the gametophyte; mosses start life as a protonema and grow into the leafy gametophore stage.',
      'Bryophyte fertilisation needs water; the sporophyte (capsule on a seta) is short-lived and dependent on the gametophyte — forcibly in liverworts vs mosses producing a capsule that lifts the spores.',
      'Pteridophytes are the first terrestrial vascular plants: sporophyte is dominant and independent; the gametophyte is a small free-living prothallus; roots stem leaves all present; sporangia sit on sporophylls.',
      'Selaginella and Salvinia are heterosporous (micro + mega spores retained) — the forerunner of the seed habit.',
      'In pteridophytes xylem LACKS vessels and phloem LACKS companion cells.',
      'Gymnosperms: naked ovules/seeds, no fruit; Cycas has coralloid roots harbouring N₂-fixing cyanobacteria; Pinus roots team up with mycorrhizal fungi.',
      'Gymnosperm wood: mostly tracheids — xylem without vessels; phloem without sieve tubes or companion cells (sieve cells only).',
      'Life-cycle is haplontic in most algae, haplo-diplontic in bryophytes and pteridophytes, and diplontic (photosynthetic phase being the longer one) in seed plants.',
    ],
    diagrams: [
      'Algae colour strip: green/brown/red with pigment + stored food + 2 examples each.',
      'Alternation-of-generations H-diagram showing haplontic, diplontic and haplo-diplontic axes.',
      'Moss life cycle: protonema → leafy gametophore → antheridium/archegonium → capsule.',
      'Fern anatomy: sori on the underside of sporophylls.',
    ],
    pyqTraps: [
      'Agar is extracted from RED algae (Gelidium, Gracilaria) — never from brown algae.',
      'Coralloid roots with nitrogen-fixing cyanobacteria belong to CYCAS; mycorrhiza roots belong to PINUS — do not swap.',
      'In bryophytes the sporophyte is REDUCED and dependent; in pteridophytes it is independent — assertion–reason favourite.',
      'Gymnosperm xylem has NO vessels (tracheids only) and phloem has NO companion cells.',
      'Alternation: most algae haplontic; bryophytes/pteridophytes haplo-diplontic; seed plants diplontic.',
      'Selaginella het­erospory ADVERTISES the seed habit but seeds do not exist there.',
    ],
    revisionRules: [
      'Keep a 4-column algae flashcard: thallus form — pigment — stored food — economic use.',
      'Draw the three alternation axes without the book once a week.',
      'For each group, fix a "signature anatomy fact" (vessel-less xylem, dependent sporophyte, coralloid roots).',
    ],
  ),
  'bio_ch4': StudyResourceContent(
    chapterId: 'bio_ch4',
    overview:
        'Animal Kingdom walks the phylum ladder from Porifera to Chordata, fixing each phylum to its innovation (body plan, coelom, excretory and circulatory machinery) and its NEET-favourite examples.',
    keyFacts: [
      'Porifera: canal system with collar cells (choanocytes); skeleton of spicules or spongin; hermaphrodite with internal or external fertilisation; water flows in via ostia, out via osculum.',
      'Cnidaria: diploblastic with cnidocytes (cnidoblasts) on tentacles; alternation of polyp (sessile) and medusa (free) — Obelia shows both.',
      'Ctenophora: marine, diploblastic, externally ciliated with comb plates, bioluminescent, sexes separate, fertilisation external (Pleurobrachia, Ctenoplana).',
      'Platyhelminthes: flatworms, triploblastic acoelomate, flame-cell excretion, hooks/suckers as parasites; Planaria (regeneration), Fasciola (liver fluke), Taenia (tape worm).',
      'Aschelminthes (Nematoda): cylindrical, complete digestive tract (muscular pharynx), pseudocoelomate, sexes separate with sexual dimorphism (females longer) — Ascaris, Wuchereria (elephantiasis).',
      'Annelida: true coelom + metamerism, nephridia excrete, closed circulation; Nereis dioecious with parapodia, Pheretima (earthworm) and leech are monoecious.',
      'Arthropoda: largest phylum; jointed chitinous appendages, open circulation, Malpighian tubule excretion, compound eyes; Apis, Bombyx, Anopheles, Culex; Limulus is a living fossil with book gills.',
      'Mollusca: second largest; unsegmented soft body in a muscular mantle with radula; Pinctada (pearl oyster), Dentalium (tusk), Octopus, Pila (snail), Aplysia (sea hare).',
      'Echinodermata: water vascular system drives tube feet; endoskeleton of calcareous ossicles; adults secondary radial (larvae bilateral) — Asterias, Echinus, Antedon, Holothuria, Ophiura.',
      'Hemichordata is NOT chordata: its stomochord is not a notochord (Balanoglossus, Saccoglossus).',
      'Chordata hallmark set: notochord, dorsal hollow nerve cord, paired pharyngeal gill slits, post-anal tail.',
      'Protochordates: Urochordata (tunic; notochord only in larval tail — Herdmania) and Cephalochordata (notochord head to tail — Branchiostoma/Amphioxus).',
      'Vertebrate lower keys: Agnatha (jawless — Petromyzon); Chondrichthyes cartilaginous with placoid scales (Scoliodon, Pristis); Osteichthyes bony with cycloid/ctenoid scales and air bladder (Labeo rohu, Hippocampus).',
      'Class-level hearts: Amphibia & most Reptilia 3-chambered, crocodiles 4-chambered; Aves and Mammalia 4-chambered with double circulation.',
      'Mammalia: mammary glands; oviparous monotremes (Ornithorhynchus — platypus, Echidna); marsupials (Macropus — kangaroo); diaphragm splits thorax and abdomen.',
    ],
    diagrams: [
      'Phylum innovation ladder: each rung adds coelom, segmentation, jointed appendages, notochord…',
      'Water-vascular system of starfish with tube feet paths.',
      'Chordata pedigree: Uro/Cephalo/Agnatha/Gnathostome branches.',
      'Heart-evolution strip: 2 → 3 → 4 chambers (crocodile special-cased).',
    ],
    pyqTraps: [
      'Hemichordata was once under chordata — stomochord ≠ notochord; MCQs test exactly this.',
      'Echinoderm water vascular system drives the tube FEET, not the circulation of blood.',
      'The crocodile is the only fully 4-chambered reptile heart in the text.',
      'Monotremes (platypus, echidna) are mammals that LAY EGGS — "all mammals are viviparous" is false.',
      'Sexual dimorphism of Ascaris: the female is longer than the male.',
      'Nereis is dioecious while earthworm/leech are monoecious — an easy inversion trap.',
    ],
    revisionRules: [
      'One-line flashcard per phylum: signature innovaton + 2 example animals + 1 disease vector if any.',
      'Rebuild the phylum ladder from memory; stop where the rung order breaks.',
      'Maintain a "living-fossil / longest / largest" curiosity strip (Limulus, blue whale as the largest animal, etc.).',
    ],
  ),
  'bio_ch13': StudyResourceContent(
    chapterId: 'bio_ch13',
    overview:
        'Photosynthesis in Higher Plants dissects the light reaction (photosystems, Z-scheme, chemiosmosis) and the Calvin/Hatch–Slack dark phases, ending with photorespiration and limiting factors.',
    keyFacts: [
      'Chlorophyll a is the chief pigment: reaction centres sit at PS I (P700) and PS II (P680); chlorophyll b/xanthophyll/carotenoids harvest light as accessory pigments.',
      'PS II runs FIRST in electron flow despite its number; the Z-scheme is non-cyclic photophosphorylation (PS II → plastoquinone → b₆f → plastocyanin → PS I → ferredoxin → NADP⁺).',
      'Cyclic photophosphorylation uses only PS I, produces ATP ONLY — no NADPH and no O₂ released.',
      'Water splitting happens at PS II (photolysis — 2H₂O → 4H⁺ + 4e⁻ + O₂); the oxygen released comes only from this step.',
      'Chemiosmosis: electron transport pumps H⁺ into the thylakoid lumen; ATP synthase (CF₁ out of the membrane into the stroma) uses the gradient.',
      'Calvin cycle runs in the STROMA: carboxylation (RuBisCO), reduction (2 ATP + 2 NADPH per CO₂) and regeneration of RuBP (1 ATP) — 3 ATP + 2 NADPH per CO₂.',
      'RuBisCO is the most abundant enzyme/protein on earth and is bifunctional — carboxylase in normal CO₂/O₂, oxygenase when O₂ is high.',
      'Photorespiration (C₃ plants) converts RuBP + O₂ to 2-phosphoglycolate + 3-PGA, consumes energy, produces no ATP or sugar, and worsens with heat/low CO₂.',
      'C₄ pathway (Hatch–Slack): mesophyll fixes CO₂ into oxaloacetate via PEP carboxylase; Kranz anatomy has large bundle-sheath cells around the veins.',
      'C₄ plants (maize, sugarcane, sorghum) essentially eliminate photorespiration and out-yield C₃ in hot, dry, high-light habitats.',
      'Blackman’s law of limiting factors: the factor in shortest relative supply caps the rate.',
    ],
    formulas: [
      'Water splitting: 2H₂O → 4H⁺ + 4e⁻ + O₂ (at PS II).',
      'Calvin cost per CO₂ fixed: 3 ATP + 2 NADPH.',
      'Per glucose (6CO₂): 18 ATP + 12 NADPH.',
      'Non-cyclic flow net output per pair of electrons: 1 NADPH + ~1.5 ATP + ½ O₂.',
    ],
    diagrams: [
      'Z-scheme with P680 and P700, plastoquinone/b₆f/plastocyanin relays and NADP⁺ end.',
      'Calvin cycle wheel: carboxylation → reduction → RuBP regeneration.',
      'C₄ leaf cross-section: Kranz bundle sheath vs mesophyll with PEP-carboxylase arrow.',
      'Thylakoid cross-section: lumen proton accumulation and CF₁ protruding into the stroma.',
    ],
    pyqTraps: [
      'PS II acts BEFORE PS I in electron flow — the numbering follows discovery, not order.',
      'Cyclic photophosphorylation gives ATP only; it makes no NADPH and releases no oxygen.',
      'Photorespiration costs energy and fixes NOTHING useful — it is not a "mini-photosynthesis".',
      'Dark reactions occur in the stroma; the light reactions occur in the thylakoid membranes.',
      'In C₄ plants, mesophyll does the initial CO₂ capture and the bundle sheath fixes it via the Calvin cycle.',
      'Calvin demands MORE ATP than NADPH (3 vs 2 per CO₂) — inversions are MCQ bait.',
    ],
    revisionRules: [
      'Redraw the Z-scheme unaided until every arrow is automatic.',
      'Hold a C₃ vs C₄ table: first acceptor, enzyme, anatomy, photorespiration, examples.',
      'Recite the per-CO₂ and per-glucose ATP/NADPH costs weekly.',
    ],
  ),
  'bio_ch14': StudyResourceContent(
    chapterId: 'bio_ch14',
    overview:
        'Respiration in Plants follows glucose through glycolysis, the link reaction, the Krebs cycle and the ETC, and closes with fermentation, RQ and the amphibolic character of the Krebs cycle.',
    keyFacts: [
      'Glycolysis runs in the CYTOSOL, is universal to all living organisms, yasts net 2 ATP + 2 NADH per glucose; phosphofructokinase is its rate-limiting enzyme.',
      'The link reaction (pyruvate dehydrogenase) converts 2 pyruvate → 2 acetyl-CoA + 2 CO₂ + 2 NADH in the mitochondrial matrix.',
      'One Krebs turn yields 3 NADH + 1 FADH₂ + 1 GTP + 2 CO₂; two turns per glucose.',
      'Total yield: up to 36–38 ATP per glucose (prokaryotes ~38; eukaryotes less due to NADH shuttling).',
      'ETC order: Complex I (NADH dehydrogenase) → III (cyt bc₁) → IV (cytochrome oxidase); FADH₂ enters at Complex II (succinate dehydrogenase) and yields less ATP.',
      'Oxygen is the terminal electron acceptor — reduced to water; without it the chain stalls and fermentation begins.',
      'Fermentation: yeast → ethanol + CO₂; muscle → lactic acid; both yield only 2 ATP per glucose — vastly less efficient than respiration.',
      'RQ = CO₂ evolved / O₂ consumed; carbohydrate RQ = 1, fats < 1, organic acids > 1.',
      'The Krebs cycle is amphibolic — it both oxidises (catabolism) and supplies carbon skeletons (anabolism).',
      'ATP synthase couples the proton-motive force to ATP synthesis; the inner mitochondrial membrane houses the ETC.',
    ],
    formulas: [
      'Glycolysis net per glucose: 2 ATP + 2 NADH.',
      'Link step ×2: 2 acetyl-CoA + 2 CO₂ + 2 NADH.',
      'Krebs ×2: 6 NADH + 2 FADH₂ + 2 GTP + 4 CO₂.',
      'RQ = CO₂/O₂ (carb 1 · fat < 1 · organic acid > 1 · anaerobic undefined).',
    ],
    diagrams: [
      'Glycolysis staircase: glucose → G-6-P → F-6-P → … → pyruvate with the ATP/NADH payoffs.',
      'Krebs wheel with entry arrow from acetyl-CoA and the CO₂/ NADH/FADH₂ outputs per turn.',
      'ETC ladder: Complexes I–IV with the FADH₂ side-entry at II and proton direction.',
      'Energy account sheet per glucose: pathway × location × yield.',
    ],
    pyqTraps: [
      'FADH₂ upstreams at Complex II, so it generates LESS ATP than NADH (which enters at I).',
      'Glycolysis is cytosolic — only the link reaction onward is mitochondrial.',
      'Fermentation regenerates NAD⁺ but produces only 2 ATP per glucose, not 38.',
      'RQ of anaerobic metabolism is undefined/infinite — avoid inserting a number.',
      'Succinate dehydrogenase is BOTH a Krebs enzyme and ETC Complex II — one enzyme, two roles.',
    ],
    revisionRules: [
      'Make an ATP-weighing table: stage → location → ATP/NADH/FADH₂ per glucose.',
      'Recite the ETC order from I to IV while pointing at the proton source.',
      'Practice RQ questions with mixed substrates (fat + carb) every week.',
    ],
  ),
  'bio_ch3_12': StudyResourceContent(
    chapterId: 'bio_ch3_12',
    overview:
        'Human Reproduction details the male and female reproductive architectures, gametogenesis, the menstrual cycle, fertilisation, implantation, placental hormones and parturition.',
    keyFacts: [
      'Spermatogenesis (puberty onset, FSH + LH/ICSH control): spermatogonium (2n) → primary spermatocyte → two secondary spermatocytes (meiosis I) → four spermatids (meiosis II) → sperm (spermiogenesis).',
      'Sertoli cells nourish developing germ cells; Leydig (interstitial) cells secrete testosterone; spermiation is the release of sperm from Sertoli cells.',
      'Sperm anatomy: head (acrosome - a Golgi-derived cap holding hyaluronidase), middle piece (mitochondrial spiral) and a long principal-piece tail.',
      'Oogenesis: primordial follicles (~2 million primary oocytes at birth, dwindling to ~60,000–80,000 at puberty); the primary oocyte sits arrested in prophase-I.',
      'At ovulation the oocyte has completed meiosis I (first polar body released) and is a haploid secondary oocyte arrested at metaphase-II; meiosis II completes ONLY after sperm entry.',
      'The Graafian follicle carries the oocyte with zona pellucida and corona radiata; after rupture the follicle becomes the corpus luteum (progesterone).',
      'Menstrual cycle (~28 days): FSH recruits follicles; an LH SURGE around day 14 triggers ovulation; if the corpus luteum degenerates, progesterone drops and menstruation follows.',
      'Fertilisation happens at the ampullary–isthmic junction of the fallopian tube; the zygote cleaves to morula (8–16 cells) → blastocyst, which implants in the endometrium (~day 6–7).',
      'Placenta (chorionic villi + uterine tissue) supplies nutrition, respiration, excretion — and hormones: hCG, hPL, oestrogens, progestogens, relaxin.',
      'hCG sustains the corpus luteum early in pregnancy — the basis of pregnancy tests; parturition is triggered by foetal signals and driven by oxytocin in a positive-feedback loop; colostrum, the first milk, is rich in IgA antibodies.',
    ],
    diagrams: [
      'Spermatogenesis ladder with ploidy annotations (2n → n).',
      'Oogenesis cascade with the two arrest points (prophase-I, metaphase-II).',
      'Menstrual-cycle graph: hormone surges (LH peak ≈ day 14) against endometrial thickness.',
      'Implantation snapshot: trophoblast, inner cell mass, endometrium.',
    ],
    pyqTraps: [
      'Meiosis II of the oocyte completes AFTER sperm entry, not before — a one-mark scaffold.',
      'The oocyte is arrested in prophase-I for years and completes meiosis-I shortly before ovulation.',
      'LH surge causes ovulation; FSH alone does not.',
      'Fertilisation site = ampullary–isthmic junction; implantation site = upper uterus (endometrium).',
      'Pregnancy test detects hCG (which maintains the corpus luteum), not progesterone.',
      'Colostrum contains IgA immunoglobulins — passive immunity to the neonate.',
    ],
    revisionRules: [
      'Draw both gametogenesis ladders side by side with hormone arrows (FSH/LH top).',
      'Tabulate the placenta hormones and what each maintains.',
      'Rehearse the cycle dates: ovulation ~day 14, window ~day 14–16, menstruation without fertilisation.',
    ],
  ),
  'bio_ch5_12': StudyResourceContent(
    chapterId: 'bio_ch5_12',
    overview:
        'Principles of Inheritance and Variation runs the Mendelian laws, incomplete dominance and codominance, multiple alleles, linkage and recombination, sex determination, pedigree analysis and genetic disorders.',
    keyFacts: [
      'Mendel worked with garden pea (7 traits); the F₂ monohybrid ratio is 3:1 phenotypic and 1:2:1 genotypic; test-cross confirms the genotype.',
      'Dihybrid F₂ is 9:3:3:1 — the empirical proof of Law of Independent Assortment (recombination fraction 50% for unlinked genes).',
      'Incomplete dominance (Antirrhinum, 4-o’clock Mirabilis): heterozygote = intermediate; the F₂ phenotypic and genotypic ratios BOTH collapse to 1:2:1.',
      'Codominance (ABO blood group: Iᴬ, Iᴮ, i; also MN blood group): both alleles express — blood group AB has both A and B antigens.',
      'Multiple alleles: ABO (3 alleles), Rh (+/−); any individual carries only 2.',
      'Morgan’s Drosophila: genes closer together are more strongly linked (less recombination) — the basis of genetic mapping.',
      'X-linked recessive traits (haemophilia, red-green colour blindness) criss-cross: fathers cannot transmit to sons; mothers can be carriers.',
      'Pleiotropy: one gene, many effects (e.g. phenylketonuria).',
      'Sex determination: XY (humans, male heterogametic), ZW (birds — female heterogametic), haplo-diploidy in honeybee (males from unfertilised, haploid eggs).',
      'Numeric disorders: Down (trisomy 21), Klinefelter (XXY), Turner (XO); nondisjunction creates them in meiosis.',
      'Mendelian disorders: haemophilia (X-linked recessive), sickle-cell anaemia (autosomal recessive; HbS substitutes Val for Glu at position 6 of β-globin), thalassemia (autosomal recessive), phenylketonuria.',
      'Sickle-cell heterozygotes (HbAS) resist malaria — a heterozygote advantage case that THEORY questions love.',
    ],
    formulas: [
      'Chiasmata and base ratios belong to separate chapters; keep numeric genetics content out of this note.',
      'Recombination frequency ≈ map distance (cM); 50% = independent.',
      'Probability of a given F₂ dihybrid phenotype class = classic 9:3:3:1 counts.',
    ],
    diagrams: [
      'Monohybrid and dihybrid Punnett grids with both ratio systems.',
      'Pedigree symbol sheet (square/circle, shading, carrier dot).',
      'Linked vs unlinked gene mapping sketch (smaller distance = fewer recombinants).',
      'Nondisjunction outcomes annotated onto meiosis-I and meiosis-II. ',
    ],
    pyqTraps: [
      'Sickle-cell heterozygotes carry BOTH HbA and HbS (codominance at molecular level) but clinically show resistance, not disease.',
      'A colour-blind father CANNOT pass the trait to his sons; every daughter of an affected father is a carrier.',
      'Incomplete dominance is not "blending inheritance" — the parental alleles persist and reappear in F₂.',
      'Down syndrome is trisomy 21; Klinefelter is XXY (male, tall, infertile); Turner is XO (female, sterile).',
      'Honeybee males (drones) arise from UNFERTILISED haploid eggs; females (workers, queens) come from fertilised diploids.',
    ],
    revisionRules: [
      'Rehearse test-cross logic until you can infer a genotype ratio from cross data.',
      'Build a pedigree drill: Part 1 read, Part 2 predict the next generation.',
      'Keep the disorder table (dominant/recessive/sex-linked) refreshed before every mock.',
    ],
  ),
  'bio_ch8_12': StudyResourceContent(
    chapterId: 'bio_ch8_12',
    overview:
        'Human Health and Disease catalogues the major infectious agents, the two arms of immunity, vaccination, allergy, cancer biology and substance abuse — with the exam’s standard pairs and assays.',
    keyFacts: [
      'Signature pairs to memorise: typhoid–Salmonella typhi (Widal test); pneumonia–Streptococcus pneumoniae/Haemophilus influenzae; common cold–Rhinovirus; malaria–Plasmodium via female Anopheles; amoebiasis–Entamoeba histolytica; ascariasis–Ascaris; elephantiasis–Wuchereria via Culex; dengue/chikungunya–Aedes aegypti; ringworm–Microsporum/Trichophyton/Epidermophyton.',
      'AIDS is caused by HIV, a retrovirus that weakens helper T (TH) cells; screening ELISA followed by Western blot for confirmation.',
      'Innate immunity has four barriers: physical (skin, mucosa), physiological (pH, saliva, tears), cellular (phagocytes — PMNL-neutrophils, macrophages) and cytokine barriers.',
      'Acquired immunity: humoral (B cells → antibodies) and cell-mediated (T cells; cytotoxic T cells kill tumour/virus-infected cells); antibodies include IgG (crosses placenta), IgA (colostrum), IgM, IgE (allergy), IgD.',
      'Active immunity = own antibody synthesis (vaccination, infection); passive = ready-made antibodies (colostrum IGs, antiserum) — memory differs.',
      'Allergy: IgE-mediated mast-cell histamine release; managed with antihistamines/adrenaline.',
      'Cancer: transformation of normal cells to cancerous; oncogenic viruses and physical/chemical carcinogens; metastasis is the spread; diagnosis via biopsy and histopathology; treatments include surgery, radiation, chemotherapy and immunotherapy.',
      'Substance abuse: opioids (opium, morphine, heroin — "smack"), cannabinoids (hashish, charas, ganja, marijuana), coca alkaloids (cocaine, crack), LSD-like hallucinogens; smoking—nicotine—drives lung/laryngeal cancer and chronic bronchitis.',
      'Chronic alcoholism leads to liver cirrhosis and hepatitis; drug rehabilitation involves counselling and detox programmes.',
      'Mosquito control and sanitation remain the highest-leverage public health measures against vector-borne disease.',
    ],
    diagrams: [
      'Antibody Y-shape with the antigen-binding arms.',
      'Two-arm immunity tree: humoral vs cell-mediated.',
      'Pathogen strip: each disease with vector + diagnostic test.',
      'Cancer-to-metastasis flow chart with the treatment branch points.',
    ],
    pyqTraps: [
      'The MALARIA vector is the FEMALE Anopheles only — males do not bite.',
      'HIV diagnosis: ELISA (screen) then Western blot (confirm) — never the reverse.',
      'IgG crosses the placenta; IgA is in colostrum — do not swap.',
      'Wuchereria (roundworm/filarial) travels via Culex, اجتماع not Aedes.',
      'AIDS weakens Helper-T (TH) cells; the immune collapse follows, not the virus number.',
      'Cancer is not a "foreign invasion" — it is the body’s own cells gone rogue.',
    ],
    revisionRules: [
      'Re-do the pathogen line-up as flashcards until instant.',
      'Draw the antibody classes table (location + function + special fact).',
      'Keep one therapy page: chemo vs radiation vs immunotherapy differences.',
    ],
  ),
  'bio_ch11_12': StudyResourceContent(
    chapterId: 'bio_ch11_12',
    overview:
        'Biotechnology: Principles and Processes covers restriction enzymes and palindromes, vectors and their parts, the transformation/composition techniques, PCR and the bioreactor + downstream pipeline.',
    keyFacts: [
      'First restriction endonuclease: Hind II (from Haemophilus influenzae) — cuts at a specific site (RS = recognition sequence).',
      'EcoRI recognises the palindrome GAATTC and cuts between G and A leaving sticky ends (5′-AATT).',
      'Plasmid vectors need: ori (copy number), selectable marker (e.g. ampᴿ, tetᴿ on pBR322), unique cloning sites (polylinker) and often a reporter (lacZ — blue/white screening).',
      'Natural vectors: Ti plasmid of Agrobacterium tumefaciens (disarmed for plants); retroviruses for animals; lambda phage/cosmid for larger inserts.',
      'Making host cells competent: CaCl₂ + brief heat shock; other methods — electroporation, microinjection, biolistics (gene gun), liposome-mediated transfer.',
      'cDNA library is built from reverse-transcribed mRNA; the genomic library contains the whole genome fragments.',
      'PCR (in vitro amplification): denaturation (~94–95 °C) → annealing (~50–60 °C) → extension (~72 °C with Taq polymerase from Thermus aquaticus); PCR products double exponentially.',
      'Recombinant DNA must contain the insert + vector; restriction + ligase are the cutting-and-joining pair.',
      'Bioreactors (mostly stirred-tank) control temperature, pH, agitation and dissolved O₂; downstream processing separates, purifies and formulates the product.',
      'Signature biotech products: human insulin (Humulin — chains A and B), hGH, hepatitis-B vaccine, blood-clotting factors.',
    ],
    diagrams: [
      'pBR322 map: ampᴿ and tetᴿ flanks, ori, and the restriction sites',
      'Sticky-end formation via EcoRI palindrome scanning.',
      'PCR thermal-cycle curve showing the three steps per cycle.',
      'Stirred-tank bioreactor anatomy with sensor arrows.',
    ],
    pyqTraps: [
      'EcoRI cuts between G and A of GAATTC — mis-cuts are a classic diagram question.',
      'Hind II is FIRST in sequence; EcoRI is just the most-familiar one.',
      'Taq polymerase works at ~72 °C because it comes from a thermophile (Thermus aquaticus), not a mesophile.',
      'PCR order is denature → anneal → extend; everything else is a wrong-order trap.',
      'The ori controls copy number; the selectable marker controls survival on media — the two are not interchangeable.',
      'Agrobacterium’s Ti plasmid is DISARMED of tumour genes before being used as a plant vector.',
    ],
    revisionRules: [
      'Draw pBR322 features from memory.',
      'Recite tools vs vectors as a two-column table before every mock.',
      'Rebuild the PCR cycle with temperatures repeatably.',
    ],
  ),
  'bio_ch13_12': StudyResourceContent(
    chapterId: 'bio_ch13_12',
    overview:
        'Organisms and Populations covers abiotic adaptation (conformers, regulators, migration), population attributes, growth mathematics (exponential vs logistic) and the grand five interactions (mutualism, competition, predation, parasitism, commensalism).',
    keyFacts: [
      'Abiotic factors: temperature, water, light, soil; eurythermal species tolerate wide ranges, stenothermal species tolerate narrow ranges.',
      'Responses: conformers track the environment; regulators (humans) hold constant internal states via thermoregulation/osmoregulation; partial regulators sit between.',
      'Escape strategies: migration (seasonal movement), hibernation/winter sleep, aestivation/summer sleep, diapause (many zooplankton).',
      'Population attributes: size/density (N), birth rate (b), death rate (d), sex ratio, age structure (pyramids) and the dispersions.',
      'Mark–recapture (Lincoln index style): N ≈ (marked in first catch × total in second catch) ÷ marked recaptured.',
      'Exponential growth dN/dt = rN (J-curve); logistic growth dN/dt = rN (K − N)/K (S-curve with K = carrying capacity).',
      'r-strategists (unstable habitats): many small offspring, short life; K-strategists (stable habitats): few large, heavily invested offspring.',
      'Mutualism: mycorrhizae, lichens, Rhizobium in legumes, fig-wasp specificity (one-to-one coevolution), plant–pollinator mutualisms.',
      'Competition: Gause’s competitive exclusion with Paramecium caudatum vs P. aurelia (aurelia wins in lab); competitive release in the field.',
      'Predation keeps prey populations in check; biological control uses ladybirds on aphids and dragonflies on mosquitoes; plants defend with calotropin, thorns and spines.',
      'Commensalism benefits one partner only: cattle egret with cattle, epiphytic orchid on a mango branch.',
      'Brood parasitism: the koel lays eggs in a crow’s nest; the crow incubates and rears koel chicks.',
    ],
    formulas: [
      'Exponential: dN/dt = rN; solution Nₜ = N₀ e^(rt).',
      'Logistic: dN/dt = rN (K − N)/K; sigmoid to a carrying capacity.',
      'Mark-recapture estimate: N = (M × C) / R (M = first marked, C = second capture, R = recaptured marks).',
    ],
    diagrams: [
      'J-curve vs S-curve overlaid with K marked.',
      'The logistic-equation ladder showing r, N and K roles.',
      'Age-pyramid trio: expanding, stable, declining.',
      'Interaction matrix: how each of the five pairs (+/−/0) reads.',
    ],
    pyqTraps: [
      'Stenothermal species live in NARROW temperature bands; eurythermal in WIDE — do not invert.',
      'Regulators maintain internal constancy AT A COST; conformers do nothing and drift with the habitat.',
      'K (carrying capacity) caps the logistic curve; exponential has no ceiling.',
      'The logistic equation slows as (K − N)/K shrinks; r stays constant.',
      'Gause’s principle says two species with the same niche cannot stably coexist.',
      'Commensalism is (+,0); mutualism (+,+); parasitism (+,−); competition (−,−) — the matrix signs are MCQ gold.',
    ],
    revisionRules: [
      'Sketch J and S curves side by side weekly.',
      'Recite the sign matrix of the five interactions as a chant.',
      'Practise 2–3 logistic/dN-dt numericals with K assignment.',
    ],
  ),
  'bio_ch14_12': StudyResourceContent(
    chapterId: 'bio_ch14_12',
    overview:
        'Ecosystem tracks energy and matter: productivity (GPP/NPP), trophic structure, the 10% law and pyramids, food chains including the detrital route, succession and the biogeochemical cycles plus ecosystem services.',
    keyFacts: [
      'Productivity: GPP is gross primary production; NPP = GPP − respiration (R) and is what is available to consumers; secondary productivity is the consumer side.',
      'The strongest ecosystems are tropical rainforests and coral reefs; the weakest are deserts and deep-sea plankton-poor zones.',
      'Lindeman’s 10% law: about one-tenth of usable energy flows to the next trophic level — the reason food chains rarely exceed 4–5 levels.',
      'Pyramids of energy are ALWAYS upright; pyramids of biomass and numbers can be inverted (a tree supporting many parasites, or marine biomass).',
      'Standing crop = live mass at a trophic level; standing state = nutrients in the abiotic pool.',
      'Two food chains connect in most ecosystems: the grazing chain and the DETRITUS chain (dead organic matter first).',
      'Succession: primary (barerock/volcanic) vs secondary (post-disturbance); xerarch starts in dry rock with lichens; hydrarch starts in water with phytoplankton; climax is the stable end-state.',
      'Biogeochemical cycles: gaseous (carbon, nitrogen) vs sedimentary (phosphorus — slow, no atmospheric phase).',
      'Phosphorus usually cycles slowly because it has no significant gaseous form and binds to soil/minerals.',
      'Ecosystem services are vital but often unpriced: nutrient cycling, climate regulation, pollination, water purification; landmark estimate by Costanza put global value at ~US\$33 trillion/year.',
      'Decomposers close the loop by converting detritus back to the standing state.',
    ],
    formulas: [
      'NPP = GPP − R.',
      'Trophic transfer efficiency ≈ 10 % of available energy.',
      'Number of trophic levels rarely > 4–5 given 10% shrinkage.',
    ],
    diagrams: [
      'Energy pyramid with 10% steps labelled.',
      'GPP→NPP flow with R deducted.',
      'Xerarch vs hydrarch succession lanes converging on the climax.',
      'Carbon vs phosphorus cycle side-by-side (atmospheric pathway highlighted).',
    ],
    pyqTraps: [
      'Energy pyramids are ALWAYS upright; number/biomass pyramids can invert.',
      'Secondary productivity is consumer production, not plant-side.',
      'Succession pioneer in xerarch is LICHEN; in hydrarch it is phytoplankton.',
      'The phosphorus cycle is sedimentary and LACKS a notable gaseous phase (CO₂/N₂-driven cycles are gaseous).',
      'NPP, not GPP, is what the herbivores can actually consume.',
    ],
    revisionRules: [
      'Rebuild the 10% law sample: 1 000 kJ producers → 100 → 10 → 1.',
      'Practise pyramid inversions with one tree ecosystem and one marine case.',
      'Make a cycle-trait table (gaseous vs sedimentary, speed, reservoir).',
    ],
  ),
  'bio_ch15_12': StudyResourceContent(
    chapterId: 'bio_ch15_12',
    overview:
        'Biodiversity and Conservation quantifies species richness, explains why tropics hold the record, lists the biodiversity hotspots, and contrasts in-situ vs ex-situ conservation.',
    keyFacts: [
      'Biodiversity spans three levels: genetic, species and ecosystem; alpha/beta/gamma diversity frame the comparison.',
      'Only ~1.5 million species are formally described; realistic estimates go into the 7–20 million range.',
      'Tropics are richest due to long evolutionary time, stable warm climate, high productivity and low past glaciation; latitudinal gradients are the pattern.',
      'Biodiversity hotspots = high species richness + high endemism + heavy threat. India has three: Western Ghats (incl. Sri Lanka group), Indo-Burma and Eastern Himalaya.',
      'India holds ~2.4% of the world’s land but roughly 8% of recorded species — one of the mega-diversity countries.',
      'In-situ conservation: biosphere reserves, national parks, sanctuaries, sacred groves (Khasi/Jaintia tradition in Meghalaya).',
      'Ex-situ conservation: seed/gene banks, tissue culture, cryopreservation, botanical gardens, zoological parks; tissue-culturing helps endangered plants.',
      'Species–area relation: S = C·A^z with z ≈ 0.1–0.2 in continents and 0.2–0.35 in islands — used to predict extinctions from habitat loss.',
      'Major extinction drivers per Wilson: habitat loss/fragmentation, overexploitation, alien species invasions (water hyacinth Eichhornia, Lantana camara, Prosopis?ju­liflora), co-extinctions.',
      'Ethical framing: Wilson’s "biophilia" — humans are wired to care for nature; conservation is also a duty, not just economics.',
    ],
    formulas: [
      'Species–area: S = C·A^z; log S = log C + z·log A.',
      'z ranges ~0.1–0.2 (mainlands) and ~0.2–0.35 (islands).',
    ],
    diagrams: [
      'Log-log species–area curve with mainland vs island slopes.',
      'Hotspot map spotlight on the three Indian regions.',
      'Conservation hierarchy: in-situ box vs ex-situ box with examples.',
      'Threats ladder: each driver tagged with a real Indian example.',
    ],
    pyqTraps: [
      'A hotspot needs BOTH endemism AND heavy threat — richness alone is not enough.',
      'In-situ preserves the habitat; ex-situ preserves the species (seed banks, zoos, tissue culture) — never swap.',
      'Invasive species listed include water hyacinth (Eichhornia crassipes) and Lantana camara — the standard example pair.',
      'Sacred groves are an IN-SITU, community-driven conservation tool, not ex-situ.',
      'Hotspot count is edition-dependent (NCERT used 25; newer lists show more) — read the question stem carefully.',
    ],
    revisionRules: [
      'Hold the S = C·A^z equation and recompute z from two data points.',
      'Keep 2 in-situ and 2 ex-situ techniques at instant recall.',
      'Track the Indian hotspots until you can list them without hesitation.',
    ],
  ),  'bio_ch5': StudyResourceContent(
    chapterId: 'bio_ch5',
    overview: 'Morphology of Flowering Plants describes roots, stems, leaves, inflorescences, flowers, fruits and seeds and their functions.',
    keyFacts: [
      'Tap roots (mustard, carrot) arise from the radicle; fibrous roots (wheat) replace the primary root; adventitious roots (banyan prop, maize stilt) arise from organs other than the radicle.',
      'Placentation types: marginal (pea), axile (tomato, lemon), parietal (mustard, Argemone), free-central (Dianthus, Primrose) and basal (sunflower, marigold).',
      'Aestivation types: valvate, twisted (red chilli, cotton), imbricate (Cassia, gulmohur) and vexillary (pea, bean).',
      'Fabaceae flowers are zygomorphic and papilionaceous with diadelphous (9+1) stamens and a superior, monocarpellary ovary.',
      'Fruit develops from the ovary; in Parthenocarpic fruits (banana) seedless fruits form without fertilisation.',
    ],
    diagrams: [
      'Root-modification map: storage roots (taproot carrot, fibrous Asparagus, adventitious sweet potato) versus supportive roots (prop banyan, stilt maize, buttress Bombax).',
      'Flower longitudinal flow: calyx > corolla > androecium > gynoecium, with placentation cross-sections (marginal, axile, parietal, free-central, basal).',
    ],
    pyqTraps: [
      'Aleurone layer (protein-rich, secretes enzymes into the endosperm) is often confused with the seed coat in monocot grain questions.',
      'Do not mix apocarpous (Michelia, Rununculus) with syncarpous (papaya) gynoecium; vexillary versus imbricate aestivation pairs recur as distractors.',
    ],
    revisionRules: [
      'Write the floral formula (Ebr, K, C, A, G notation) for fabaceae, solanaceae and liliaceae from memory, then verify against the NCERT figures.',
      'For every family recall one modification example (tendril in pea, bulbil in Agave, prop roots in banyan) before attempting assertion-reason PYQs.',
    ],
  ),
  'bio_ch6': StudyResourceContent(
    chapterId: 'bio_ch6',
    overview: 'Anatomy of Flowering Plants studies tissues, tissue systems, primary and secondary growth and vascular organisation.',
    keyFacts: [
      'Dicot stems and roots possess cambium and undergo secondary growth; monocots lack secondary growth entirely.',
      'Xylem is endarch in stems and exarch in roots; phloem parenchyma is absent in monocots.',
      'Periderm originates from phellogen (cork cambium) which produces phellem (cork, dead, suberised) outward and phelloderm inward.',
      'Kranz anatomy with large bundle-sheath cells around vascular bundles is typical of C4 monocot leaves such as maize.',
    ],
    diagrams: [
      'Dicot-root transverse section sequence: epiblema with root hairs > cortex > endodermis with Casparian strips > pericycle > phloem > exarch xylem.',
      'Secondary growth timeline: cambial ring forms > secondary xylem inward, secondary phloem outward > bark, heartwood versus sapwood rings.',
    ],
    pyqTraps: [
      'Bulliform (motor) cells lie only on the adaxial surface of monocot leaves; their presence/absence flips options in leaf-anatomy sets.',
      'Heartwood (non-functional, loaded with tannins/resins) versus sapwood (functional water conduction) is a classic mismatch trap.',
    ],
    revisionRules: [
      'Draw TS of dicot and monocot stems side by side weekly, labelling each ring and bundle count difference.',
      'Trace every tissue to the meristem origin it develops from before matching-type PYQs.',
    ],
  ),
  'bio_ch7': StudyResourceContent(
    chapterId: 'bio_ch7',
    overview: 'Structural Organisation in Animals covers organ level organisation in invertebrates and chordates with emphasis on systems.',
    keyFacts: [
      'Earthworm (Pheretima): closed circulatory system, metamerism, septal nephridia from 15th segment onward, urea as the excretory product and a typhlosole for absorption.',
      'Cockroach: open circulatory system with haemocoel, 10 pairs of spiracles (3 thoracic + 7 abdominal), Malpighian tubule excretion and compound eyes.',
      'Frogs undergo cutaneous respiration in water and pulmonary on land; ten cranial nerves; hibernation in winter and aestivation in summer.',
      'The liver fluke (Fasciola) needs two hosts: a snail (Lymnaea) intermediate host and a sheep as the definitive host.',
    ],
    diagrams: [
      'Earthworm longitudinal section: pharynx > gizzard > stomach > intestine with a typhlosole; label septal and pharyngeal nephridia rows.',
      'Cockroach alimentary canal: crop > gizzard with teeth > midgut/hepatopancreatic caeca > hindgut with Malpighian tubules and the tracheal system of spiracles.',
    ],
    pyqTraps: [
      'Do not flip closed (earthworm) versus open (cockroach) circulatory systems;the same trap applies to heart chambers and blood-forward flow direction.',
      'Fasciola\'s intermediate host is the snail and the definitive host is sheep/cattle; swapping them is a favourite option trap.',
    ],
    revisionRules: [
      'Tabulate organ systems by phylum in one sitting and write the cockroach NCERT figure labels from memory.',
      'Rehearse \'common structure\' stems (septal nephridia, Malpighian tubule analogies) before matching PYQs.',
    ],
  ),
  'bio_ch15': StudyResourceContent(
    chapterId: 'bio_ch15',
    overview: 'Body Fluids and Circulation examines blood composition, lymph, heart structure, double circulation and blood pressure regulation.',
    keyFacts: [
      'Blood is ~55% plasma and 45% formed elements; plasma proteins are fibrinogen, globulins and albumins; Ca2+ acts as Factor IV in clotting.',
      'The conduction path is SA node > AV node > bundle of His > bundle branches > Purkinje fibres; cardiac output = stroke volume x heart rate (~5 L/min at rest).',
      'Oxygen is transported mostly as oxyhaemoglobin (~97%) while CO2 travels primarily as bicarbonate (~70%).',
      'Lymph is protein-poor interstitial fluid re-entering vessels through larger lymphatics and reaching the thoracic duct.',
    ],
    diagrams: [
      'Human-heart flow arrows: SVC/IVC > right atrium > tricuspid > right ventricle > pulmonary artery to lungs > pulmonary veins > left atrium > bicuspid > left ventricle > aorta.',
      'ECG annotations: P wave (atrial depolarisation), QRS complex (ventricular depolarisation), T wave (ventricular repolarisation).',
    ],
    pyqTraps: [
      'First heart sound (lub) comes from bicuspid/tricuspid valve closure; second (dub) from semilunar closure - flipped assertions are common.',
      'The pulmonary vein carries oxygenated blood; options frequently invert this to test blind colour-coding habits.',
    ],
    revisionRules: [
      'Recite the conduction pathway and each ECG letter as one memorised sentence.',
      'Summarise clotting (Ca2+ + thrombin > fibrinogen > fibrin) before reading the actual PYQ options.',
    ],
  ),
  'bio_ch17': StudyResourceContent(
    chapterId: 'bio_ch17',
    overview: 'Locomotion and Movement explains musculoskeletal system, skeletal elements and mechanism of muscle contraction and relaxation.',
    keyFacts: [
      'Sliding-filament theory: cross-bridges powered by ATP; calcium binds troponin to expose myosin-binding sites on actin.',
      'The axial skeleton has 80 bones (22 skull bones, 6 ear ossicles, hyoid, vertebral column, ribs/sternum); the appendicular skeleton has 126 bones.',
      'Joints: fibrous (sutures), cartilaginous (pubic symphysis) and synovial (ball-and-socket, hinge, pivot, saddle, gliding).',
      'Rigor mortis results from ATP depletion; muscle fatigue is associated with lactic-acid buildup.',
    ],
    diagrams: [
      'Sarcomere labels: Z-line, I-band (thin filaments), A-band (thick overlap), H-zone (thick only) and how each changes during contraction.',
      'Pelvic/thoracic girdle articulation with the femur head plus the knee-joint meniscus sketch.',
    ],
    pyqTraps: [
      'A-band and myosin length stay constant during contraction while the I-band, H-zone and sarcomere shorten - reversals are frequent.',
      'Do not rely on memorising every bone count; NCERT faithfulness lies in axial numbers (skull 22, vertebrae 26).',
    ],
    revisionRules: [
      'Recite the sliding-filament cycle in five steps ending with ATP for detachment.',
      'Practise naming each joint type with a real body example before PYQ matching.',
    ],
  ),
  'bio_ch18': StudyResourceContent(
    chapterId: 'bio_ch18',
    overview: 'Neural Control and Coordination studies neurons, nerve impulse conduction, central and peripheral nervous system and reflexes.',
    keyFacts: [
      'Neuron types: multipolar (typical CNS), bipolar (retina) and unipolar (embryo); myelinated axons show saltatory conduction.',
      'Resting potential ~-70 mV, threshold ~-55 mV, depolarisation is Na+ influx and repolarisation is K+ efflux.',
      'Synapses can be electrical (gap junctions) or chemical (neurotransmitters such as acetylcholine, dopamine, serotonin).',
      'Brain compartments: forebrain (cerebrum, thalamus, hypothalamus), midbrain (corpora quadrigemina), hindbrain (pons, medulla, cerebellum) and meninges (dura/arachnoid/pia).',
    ],
    diagrams: [
      'Neuron flow: dendrites > soma > axon hillock > myelin > nodes of Ranvier > axon terminal vesicles.',
      'Reflex arc strip: receptor > sensory neuron > CNS interneuron > motor neuron > effector.',
    ],
    pyqTraps: [
      'Saltatory conduction jumps at nodes of Ranvier, not within myelin; assertions frequently invert it.',
      'Optic nerve fibres decussate partially at the chiasma by visual field, not per eye - flipping this distorts perception questions.',
    ],
    revisionRules: [
      'Draw the action-potential curve and annotate every phase from memory each week.',
      'For every phase note the responsible ion movement before doing assertion-reason sets.',
    ],
  ),
  'bio_ch19': StudyResourceContent(
    chapterId: 'bio_ch19',
    overview: 'Chemical Coordination and Integration covers endocrine glands, hormone action mechanisms, feedback regulation and plant hormones.',
    keyFacts: [
      'Pituitary hormones: anterior (GH, TSH, ACTH, FSH, LH, prolactin) versus posterior (ADH and oxytocin, both synthesized in the hypothalamus).',
      'Thyroid: T3/T4 from follicular cells and calcitonin from parafollicular C-cells; iodine is essential for thyroxine synthesis.',
      'Adrenal cortex zones (glomerulosa, fasciculata, reticularis) release mineralocorticoids, glucocorticoids and androgens; medulla secretes adrenaline and noradrenaline.',
      'Pancreatic islets: alpha cells release glucagon (hyperglycemic), beta cells release insulin (hypoglycemic); thymus involutes after puberty.',
    ],
    diagrams: [
      'Hypothalamic-pituitary portal arrows to target glands (thyroid, adrenal cortex, gonads).',
      'Insulin-glucagon feedback loop arrows to hepatic glycogen storage and release.',
    ],
    pyqTraps: [
      'ADH and oxytocin are synthesized in the HYPOTHALAMUS, not in the posterior pituitary gland itself.',
      'Mineralocorticoid action (aldosterone on Na+/K+) must not be confused with glucocorticoid action (cortisol on glucose).',
    ],
    revisionRules: [
      'Rebuild the complete gland-hormone-target-effect table from memory and verify it row by row.',
      'Note hypothalamic releasing/inhibiting hormone exceptions right before PYQ sets.',
    ],
  ),
  'bio_ch1_12': StudyResourceContent(
    chapterId: 'bio_ch1_12',
    overview: 'Reproduction in Organisms covers asexual and sexual reproduction, life cycles and reproductive strategies across major groups.',
    keyFacts: [
      'Asexual propagules: runners (strawberry), offsets (water hyacinth, Pistia), suckers (banana, pineapple), tubers (potato), rhizome (ginger), bulbils (Agave) and gemmae in liverworts.',
      'Water hyacinth (Eichhornia crassipes) is an invasive aquatic weed that spreads by offsets.',
      'Bamboo species flower once in many years then die; Strobilanthes kunthiana (Neelakurinji) flowers every 12 years.',
      'Life cycles: haplontic in most algae, diplontic in seed plants and haplo-diplontic in bryophytes and pteridophytes.',
    ],
    diagrams: [
      'Vegetative-propagation map: runners, offsets, suckers, rhizomes, corms (Colocasia), bulbs (onion) and bulbils (Agave).',
      'Life-cycle strip comparing haplontic, diplontic and haplo-diplontic phases with gametophyte/sporophyte dominance.',
    ],
    pyqTraps: [
      'Bamboo is monocarpic (flowers once) while Strobilanthes flowers every 12 years - swapping them is a common trap.',
      'Oestrus cycles occur in non-primate mammals while primates (including humans) show menstrual cycles.',
    ],
    revisionRules: [
      'Give one life-cycle mnemonic per group and recite it before assertion sets.',
      'Match one vegetative propagule per species with its family as a daily drill.',
    ],
  ),
  'bio_ch2_12': StudyResourceContent(
    chapterId: 'bio_ch2_12',
    overview: 'Sexual Reproduction in Flowering Plants deals with flower structure, pollination, fertilisation, apomixis and seed development.',
    keyFacts: [
      'Outbreeding devices prevent self-pollination: dichogamy, herkogamy, unisexuality and self-sterility.',
      'Pollination modes: anemophily (wind, wasteful), hydrophily (Vallisneria, Zostera) and entomophily with sticky-rough pollen.',
      'Double fertilisation: syngamy produces the diploid zygote and triple fusion produces the triploid (3n) primary endosperm nucleus.',
      'Apomixis (e.g. Citrus, many Asteraceae) forms seeds without meiosis or fertilisation; polyembryony is common in Citrus and Mango.',
    ],
    diagrams: [
      'Anther TS: four microsporangia with tapetum nourishing sporogenous tissue, pollen mother cells undergoing meiosis to tetrads.',
      'Eight-nucleate embryo sac: egg apparatus (egg + 2 synergids), central cell with 2 polar nuclei and 3 antipodals.',
    ],
    pyqTraps: [
      'Endosperm is 3n (triploid) while the zygote is 2n (diploid) - reversing the ploidies is the top MCQ trap.',
      'Wind-pollinated grasses release light, dry, non-sticky pollen; pairing heavy sticky pollen with wind is a frequent distractor.',
    ],
    revisionRules: [
      'Draw a correct 8-nucleate embryo sac from memory labelling each cell type.',
      'Sequence double fertilisation steps with ploidy noted beside each before attempting PYQs.',
    ],
  ),
  'bio_ch4_12': StudyResourceContent(
    chapterId: 'bio_ch4_12',
    overview: 'Reproductive Health discusses population control, STIs, infertility, assisted reproductive technologies and safe sex practices.',
    keyFacts: [
      'Reproductive health covers STI prevention, fertility regulation and safe motherhood beyond contraception alone.',
      'Natural methods: periodic abstinence, coitus interruptus and lactational amenorrhoea (effective only up to six months post-partum).',
      'IUD classes: non-medicated (Lippes loop), copper-releasing (CuT, Cu7, Multiload 375) and hormone-releasing (LNG-20).',
      'MTP is relatively safe within the first trimester (~12 weeks); amniocentesis is legal only for detecting foetal abnormalities, never sex selection.',
    ],
    diagrams: [
      'ART decision tree: IVF (uterus transfer), GIFT (gamete transfer to fallopian tube), ZIFT (zygote transfer), ICSI and artificial insemination.',
      'Contraceptive-mechanism card: oral pills suppress ovulation; IUDs make the uterus unsuitable for implantation; barriers block gamete transport.',
    ],
    pyqTraps: [
      'IVF transfers an embryo into the uterus, GIFT transfers gametes and ZIFT transfers a zygote into the fallopian tube - mixing them is a classic trap.',
      'Saheli is a non-steroidal, once-a-week oral contraceptive pill; combined steroidal pills differ in dose and schedule.',
    ],
    revisionRules: [
      'Build one contraceptive table (barrier/hormonal/IUD/surgical) with a named example in each row.',
      'Draw the ART tree by fertilisation site and transfer destination before PYQ drills.',
    ],
  ),
  'bio_ch9_12': StudyResourceContent(
    chapterId: 'bio_ch9_12',
    overview: 'Strategies for Enhancement in Food Production covers plant and animal improvement, tissue culture, hybridisation and single-cell protein.',
    keyFacts: [
      'Green-revolution releases: semi-dwarf wheat varieties Sonalika and Kalyan Sona; IR-8 semi-dwarf rice; Mexican semi-dwarf wheat by Norman Borlaug\'s group.',
      'Plant breeding steps: collection of germplasm > hybridisation > selection and testing > release and commercialisation.',
      'Milch breeds (Gir, Sahiwal) give high milk yield; Hariana and Tharparkar serve as dual-purpose; Malvi is a draught breed.',
      'Inbreeding depression lowers vigour; outcrossing, cross-breeding and interspecific hybridisation (mule = mare x donkey) counteract it.',
    ],
    diagrams: [
      'Plant-breeding chain: germplasm collection > parents > superior hybrids > evaluation > release.',
      'Animal-breeding map: outcrossing versus cross-breeding versus interspecific hybrids with named examples.',
    ],
    pyqTraps: [
      'Sonalika/Kalyan Sona are wheat releases from the semi-dwarf programme - mixing them with IR-8 (rice) is a recurring trap.',
      'Spirulina is a single-cell protein source; options that swap yeasts or mycoproteins in its place are deliberate distractors.',
    ],
    revisionRules: [
      'List each breeding example as a breed-variety paire (variety species outcome) in one sitting.',
      'Practise distinction questions between hybridisation, mutation breeding and polyploidy.',
    ],
  ),
  'bio_ch10_12': StudyResourceContent(
    chapterId: 'bio_ch10_12',
    overview: 'Microbes in Human Welfare explores fermentation, antibiotics, biogas, bio-fertilisers and microbial role in industry and agriculture.',
    keyFacts: [
      'Lactic-acid bacteria (Lactobacillus) curdle milk into curd; Saccharomyces produces ethanol while Acetobacter converts it to vinegar.',
      'Industrial products: citric acid (Aspergillus niger), lactic acid (Lactobacillus), acetic acid (Acetobacter), ethanol (Saccharomyces).',
      'Biofertilisers: Rhizobium in legume root nodules, free-living Azotobacter and Azospirillum, cyanobacteria such as Anabaena and Nostoc; Azolla hosts Anabaena.',
      'Biogas is 50-70% methane produced by obligate anaerobic methanogens (e.g. Methanobacterium) inside sludge digesters.',
    ],
    diagrams: [
      'Fermenter cross-section with broth, pH/thermometer probes, heating coils and impeller aeration.',
      'Biogas plant sketch: mixing tank > inlet > digester chamber > gas holder dome > sludge outlet.',
    ],
    pyqTraps: [
      'Statins from Monascus purpureus act as competitive inhibitors of the enzyme involved in cholesterol biosynthesis - confusing the organism with Streptomyces is a trap.',
      'Azolla (a fern) hosts Anabaena (a cyanobacterium); many MCQs reverse this with Azotobacter - keep the pairing straight.',
    ],
    revisionRules: [
      'Recite a microbe-to-product one-liner list daily before assertion sets.',
      'Draw the fermentation/biogas plant flow once and annotate operations step by step.',
    ],
  ),
  'bio_ch12_12': StudyResourceContent(
    chapterId: 'bio_ch12_12',
    overview: 'Biotechnology and its Applications covers genetically modified organisms, bioprocess technology, patents, biosafety and ethical concerns.',
    keyFacts: [
      'Restriction endonucleases cut phosphodiester bonds at palindromic sites; EcoRI (G^AATTC) leaves 5\' AATT sticky overhangs.',
      'Cloning vectors need an ori, selectable markers (antibiotic resistance such as ampR/tetR in pBR322) and a multiple cloning site.',
      'Competent bacterial hosts are made permeable with CaCl2 (and heat shock/electroporation) for transformation.',
      'Bt toxins (cry proteins from Bacillus thuringiensis) are protoxins activated in the alkaline insect midgut; Bt cotton and Bt corn express them.',
    ],
    diagrams: [
      'Cloning-vector map: ori, multiple cloning site (EcoRI, HindIII, BamHI), ampR and tetR selectable markers.',
      'Agrobacterium Ti plasmid transfer flow: T-DNA excision > plant nuclear genome integration.',
    ],
    pyqTraps: [
      'EcoRI produces 5\' AATT overhangs; any option quoting a different overhang or cut position is a deliberate trap.',
      'Bt protoxin activates in the ALKALINE pH of the insect gut - options that say acidic or \'plant pH\' invert the fact.',
    ],
    revisionRules: [
      'List vector criteria in order and label which marker enables selection versus maintenance.',
      'Recall one restriction enzyme name, palindrome and overhang set before PYQ drills.',
    ],
  ),

};
