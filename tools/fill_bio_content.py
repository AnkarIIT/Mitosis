"""Fill placeholder StudyResourceContent entries (bio chapters) with authored
revision content, meeting the quality floor locked by
test/study_resource_content_test.dart: overview + keyFacts + diagrams +
pyqTraps + revisionRules all non-empty, NCERT-accurate.
"""
import re

PATH = r"C:\Codes\Mitosis\lib\core\models\study_resource_content.dart"

# NCERT XI/XII Biology revision content. Short, exam-facing, accurate.
CONTENT = {
    "bio_ch5": {
        "keyFacts": [
            "Tap roots (mustard, carrot) arise from the radicle; fibrous roots (wheat) replace the primary root; adventitious roots (banyan prop, maize stilt) arise from organs other than the radicle.",
            "Placentation types: marginal (pea), axile (tomato, lemon), parietal (mustard, Argemone), free-central (Dianthus, Primrose) and basal (sunflower, marigold).",
            "Aestivation types: valvate, twisted (red chilli, cotton), imbricate (Cassia, gulmohur) and vexillary (pea, bean).",
            "Fabaceae flowers are zygomorphic and papilionaceous with diadelphous (9+1) stamens and a superior, monocarpellary ovary.",
            "Fruit develops from the ovary; in Parthenocarpic fruits (banana) seedless fruits form without fertilisation.",
        ],
        "diagrams": [
            "Root-modification map: storage roots (taproot carrot, fibrous Asparagus, adventitious sweet potato) versus supportive roots (prop banyan, stilt maize, buttress Bombax).",
            "Flower longitudinal flow: calyx > corolla > androecium > gynoecium, with placentation cross-sections (marginal, axile, parietal, free-central, basal).",
        ],
        "pyqTraps": [
            "Aleurone layer (protein-rich, secretes enzymes into the endosperm) is often confused with the seed coat in monocot grain questions.",
            "Do not mix apocarpous (Michelia, Rununculus) with syncarpous (papaya) gynoecium; vexillary versus imbricate aestivation pairs recur as distractors.",
        ],
        "revisionRules": [
            "Write the floral formula (Ebr, K, C, A, G notation) for fabaceae, solanaceae and liliaceae from memory, then verify against the NCERT figures.",
            "For every family recall one modification example (tendril in pea, bulbil in Agave, prop roots in banyan) before attempting assertion-reason PYQs.",
        ],
    },
    "bio_ch6": {
        "keyFacts": [
            "Dicot stems and roots possess cambium and undergo secondary growth; monocots lack secondary growth entirely.",
            "Xylem is endarch in stems and exarch in roots; phloem parenchyma is absent in monocots.",
            "Periderm originates from phellogen (cork cambium) which produces phellem (cork, dead, suberised) outward and phelloderm inward.",
            "Kranz anatomy with large bundle-sheath cells around vascular bundles is typical of C4 monocot leaves such as maize.",
        ],
        "diagrams": [
            "Dicot-root transverse section sequence: epiblema with root hairs > cortex > endodermis with Casparian strips > pericycle > phloem > exarch xylem.",
            "Secondary growth timeline: cambial ring forms > secondary xylem inward, secondary phloem outward > bark, heartwood versus sapwood rings.",
        ],
        "pyqTraps": [
            "Bulliform (motor) cells lie only on the adaxial surface of monocot leaves; their presence/absence flips options in leaf-anatomy sets.",
            "Heartwood (non-functional, loaded with tannins/resins) versus sapwood (functional water conduction) is a classic mismatch trap.",
        ],
        "revisionRules": [
            "Draw TS of dicot and monocot stems side by side weekly, labelling each ring and bundle count difference.",
            "Trace every tissue to the meristem origin it develops from before matching-type PYQs.",
        ],
    },
    "bio_ch7": {
        "keyFacts": [
            "Earthworm (Pheretima): closed circulatory system, metamerism, septal nephridia from 15th segment onward, urea as the excretory product and a typhlosole for absorption.",
            "Cockroach: open circulatory system with haemocoel, 10 pairs of spiracles (3 thoracic + 7 abdominal), Malpighian tubule excretion and compound eyes.",
            "Frogs undergo cutaneous respiration in water and pulmonary on land; ten cranial nerves; hibernation in winter and aestivation in summer.",
            "The liver fluke (Fasciola) needs two hosts: a snail (Lymnaea) intermediate host and a sheep as the definitive host.",
        ],
        "diagrams": [
            "Earthworm longitudinal section: pharynx > gizzard > stomach > intestine with a typhlosole; label septal and pharyngeal nephridia rows.",
            "Cockroach alimentary canal: crop > gizzard with teeth > midgut/hepatopancreatic caeca > hindgut with Malpighian tubules and the tracheal system of spiracles.",
        ],
        "pyqTraps": [
            "Do not flip closed (earthworm) versus open (cockroach) circulatory systems;这也 applies to heart chambers and blood-forward flow direction.",
            "Fasciola's intermediate host is the snail and the definitive host is sheep/cattle; swapping them is a favourite option trap.",
        ],
        "revisionRules": [
            "Tabulate organ systems by phylum in one sitting and write the cockroach NCERT figure labels from memory.",
            "Rehearse 'common structure' stems (septal nephridia, Malpighian tubule analogies) before matching PYQs.",
        ],
    },
    "bio_ch15": {
        "keyFacts": [
            "Blood is ~55% plasma and 45% formed elements; plasma proteins are fibrinogen, globulins and albumins; Ca2+ acts as Factor IV in clotting.",
            "The conduction path is SA node > AV node > bundle of His > bundle branches > Purkinje fibres; cardiac output = stroke volume x heart rate (~5 L/min at rest).",
            "Oxygen is transported mostly as oxyhaemoglobin (~97%) while CO2 travels primarily as bicarbonate (~70%).",
            "Lymph is protein-poor interstitial fluid re-entering vessels through larger lymphatics and reaching the thoracic duct.",
        ],
        "diagrams": [
            "Human-heart flow arrows: SVC/IVC > right atrium > tricuspid > right ventricle > pulmonary artery to lungs > pulmonary veins > left atrium > bicuspid > left ventricle > aorta.",
            "ECG annotations: P wave (atrial depolarisation), QRS complex (ventricular depolarisation), T wave (ventricular repolarisation).",
        ],
        "pyqTraps": [
            "First heart sound (lub) comes from bicuspid/tricuspid valve closure; second (dub) from semilunar closure - flipped assertions are common.",
            "The pulmonary vein carries oxygenated blood; options frequently invert this to test blind colour-coding habits.",
        ],
        "revisionRules": [
            "Recite the conduction pathway and each ECG letter as one memorised sentence.",
            "Summarise clotting (Ca2+ + thrombin > fibrinogen > fibrin) before reading the actual PYQ options.",
        ],
    },
    "bio_ch17": {
        "keyFacts": [
            "Sliding-filament theory: cross-bridges powered by ATP; calcium binds troponin to expose myosin-binding sites on actin.",
            "The axial skeleton has 80 bones (22 skull bones, 6 ear ossicles, hyoid, vertebral column, ribs/sternum); the appendicular skeleton has 126 bones.",
            "Joints: fibrous (sutures), cartilaginous (pubic symphysis) and synovial (ball-and-socket, hinge, pivot, saddle, gliding).",
            "Rigor mortis results from ATP depletion; muscle fatigue is associated with lactic-acid buildup.",
        ],
        "diagrams": [
            "Sarcomere labels: Z-line, I-band (thin filaments), A-band (thick overlap), H-zone (thick only) and how each changes during contraction.",
            "Pelvic/thoracic girdle articulation with the femur head plus the knee-joint meniscus sketch.",
        ],
        "pyqTraps": [
            "A-band and myosin length stay constant during contraction while the I-band, H-zone and sarcomere shorten - reversals are frequent.",
            "Do not rely on memorising every bone count; NCERT faithfulness lies in axial numbers (skull 22, vertebrae 26).",
        ],
        "revisionRules": [
            "Recite the sliding-filament cycle in five steps ending with ATP for detachment.",
            "Practise naming each joint type with a real body example before PYQ matching.",
        ],
    },
    "bio_ch18": {
        "keyFacts": [
            "Neuron types: multipolar (typical CNS), bipolar (retina) and unipolar (embryo); myelinated axons show saltatory conduction.",
            "Resting potential ~-70 mV, threshold ~-55 mV, depolarisation is Na+ influx and repolarisation is K+ efflux.",
            "Synapses can be electrical (gap junctions) or chemical (neurotransmitters such as acetylcholine, dopamine, serotonin).",
            "Brain compartments: forebrain (cerebrum, thalamus, hypothalamus), midbrain (corpora quadrigemina), hindbrain (pons, medulla, cerebellum) and meninges (dura/arachnoid/pia).",
        ],
        "diagrams": [
            "Neuron flow: dendrites > soma > axon hillock > myelin > nodes of Ranvier > axon terminal vesicles.",
            "Reflex arc strip: receptor > sensory neuron > CNS interneuron > motor neuron > effector.",
        ],
        "pyqTraps": [
            "Saltatory conduction jumps at nodes of Ranvier, not within myelin; assertions frequently invert it.",
            "Optic nerve fibres decussate partially at the chiasma by visual field, not per eye - flipping this distorts perception questions.",
        ],
        "revisionRules": [
            "Draw the action-potential curve and annotate every phase from memory each week.",
            "For every phase note the responsible ion movement before doing assertion-reason sets.",
        ],
    },
    "bio_ch19": {
        "keyFacts": [
            "Pituitary hormones: anterior (GH, TSH, ACTH, FSH, LH, prolactin) versus posterior (ADH and oxytocin, both synthesized in the hypothalamus).",
            "Thyroid: T3/T4 from follicular cells and calcitonin from parafollicular C-cells; iodine is essential for thyroxine synthesis.",
            "Adrenal cortex zones (glomerulosa, fasciculata, reticularis) release mineralocorticoids, glucocorticoids and androgens; medulla secretes adrenaline and noradrenaline.",
            "Pancreatic islets: alpha cells release glucagon (hyperglycemic), beta cells release insulin (hypoglycemic); thymus involutes after puberty.",
        ],
        "diagrams": [
            "Hypothalamic-pituitary portal arrows to target glands (thyroid, adrenal cortex, gonads).",
            "Insulin-glucagon feedback loop arrows to hepatic glycogen storage and release.",
        ],
        "pyqTraps": [
            "ADH and oxytocin are synthesized in the HYPOTHALAMUS, not in the posterior pituitary gland itself.",
            "Mineralocorticoid action (aldosterone on Na+/K+) must not be confused with glucocorticoid action (cortisol on glucose).",
        ],
        "revisionRules": [
            "Rebuild the complete gland-hormone-target-effect table from memory and verify it row by row.",
            "Note hypothalamic releasing/inhibiting hormone exceptions right before PYQ sets.",
        ],
    },
    "bio_ch1_12": {
        "keyFacts": [
            "Asexual propagules: runners (strawberry), offsets (water hyacinth, Pistia), suckers (banana, pineapple), tubers (potato), rhizome (ginger), bulbils (Agave) and gemmae in liverworts.",
            "Water hyacinth (Eichhornia crassipes) is an invasive aquatic weed that spreads by offsets.",
            "Bamboo species flower once in many years then die; Strobilanthes kunthiana (Neelakurinji) flowers every 12 years.",
            "Life cycles: haplontic in most algae, diplontic in seed plants and haplo-diplontic in bryophytes and pteridophytes.",
        ],
        "diagrams": [
            "Vegetative-propagation map: runners, offsets, suckers, rhizomes, corms (Colocasia), bulbs (onion) and bulbils (Agave).",
            "Life-cycle strip comparing haplontic, diplontic and haplo-diplontic phases with gametophyte/sporophyte dominance.",
        ],
        "pyqTraps": [
            "Bamboo is monocarpic (flowers once) while Strobilanthes flowers every 12 years - swapping them is a common trap.",
            "Oestrus cycles occur in non-primate mammals while primates (including humans) show menstrual cycles.",
        ],
        "revisionRules": [
            "Give one life-cycle mnemonic per group and recite it before assertion sets.",
            "Match one vegetative propagule per species with its family as a daily drill.",
        ],
    },
    "bio_ch2_12": {
        "keyFacts": [
            "Outbreeding devices prevent self-pollination: dichogamy, herkogamy, unisexuality and self-sterility.",
            "Pollination modes: anemophily (wind, wasteful), hydrophily (Vallisneria, Zostera) and entomophily with sticky-rough pollen.",
            "Double fertilisation: syngamy produces the diploid zygote and triple fusion produces the triploid (3n) primary endosperm nucleus.",
            "Apomixis (e.g. Citrus, many Asteraceae) forms seeds without meiosis or fertilisation; polyembryony is common in Citrus and Mango.",
        ],
        "diagrams": [
            "Anther TS: four microsporangia with tapetum nourishing sporogenous tissue, pollen mother cells undergoing meiosis to tetrads.",
            "Eight-nucleate embryo sac: egg apparatus (egg + 2 synergids), central cell with 2 polar nuclei and 3 antipodals.",
        ],
        "pyqTraps": [
            "Endosperm is 3n (triploid) while the zygote is 2n (diploid) - reversing the ploidies is the top MCQ trap.",
            "Wind-pollinated grasses release light, dry, non-sticky pollen; pairing heavy sticky pollen with wind is a frequent distractor.",
        ],
        "revisionRules": [
            "Draw a correct 8-nucleate embryo sac from memory labelling each cell type.",
            "Sequence double fertilisation steps with ploidy noted beside each before attempting PYQs.",
        ],
    },
    "bio_ch4_12": {
        "keyFacts": [
            "Reproductive health covers STI prevention, fertility regulation and safe motherhood beyond contraception alone.",
            "Natural methods: periodic abstinence, coitus interruptus and lactational amenorrhoea (effective only up to six months post-partum).",
            "IUD classes: non-medicated (Lippes loop), copper-releasing (CuT, Cu7, Multiload 375) and hormone-releasing (LNG-20).",
            "MTP is relatively safe within the first trimester (~12 weeks); amniocentesis is legal only for detecting foetal abnormalities, never sex selection.",
        ],
        "diagrams": [
            "ART decision tree: IVF (uterus transfer), GIFT (gamete transfer to fallopian tube), ZIFT (zygote transfer), ICSI and artificial insemination.",
            "Contraceptive-mechanism card: oral pills suppress ovulation; IUDs make the uterus unsuitable for implantation; barriers block gamete transport.",
        ],
        "pyqTraps": [
            "IVF transfers an embryo into the uterus, GIFT transfers gametes and ZIFT transfers a zygote into the fallopian tube - mixing them is a classic trap.",
            "Saheli is a non-steroidal, once-a-week oral contraceptive pill; combined steroidal pills differ in dose and schedule.",
        ],
        "revisionRules": [
            "Build one contraceptive table (barrier/hormonal/IUD/surgical) with a named example in each row.",
            "Draw the ART tree by fertilisation site and transfer destination before PYQ drills.",
        ],
    },
    "bio_ch9_12": {
        "keyFacts": [
            "Green-revolution releases: semi-dwarf wheat varieties Sonalika and Kalyan Sona; IR-8 semi-dwarf rice; Mexican semi-dwarf wheat by Norman Borlaug's group.",
            "Plant breeding steps: collection of germplasm > hybridisation > selection and testing > release and commercialisation.",
            "Milch breeds (Gir, Sahiwal) give high milk yield; Hariana and Tharparkar serve as dual-purpose; Malvi is a draught breed.",
            "Inbreeding depression lowers vigour; outcrossing, cross-breeding and interspecific hybridisation (mule = mare x donkey) counteract it.",
        ],
        "diagrams": [
            "Plant-breeding chain: germplasm collection > parents > superior hybrids > evaluation > release.",
            "Animal-breeding map: outcrossing versus cross-breeding versus interspecific hybrids with named examples.",
        ],
        "pyqTraps": [
            "Sonalika/Kalyan Sona are wheat releases from the semi-dwarf programme - mixing them with IR-8 (rice) is a recurring trap.",
            "Spirulina is a single-cell protein source; options that swap yeasts or mycoproteins in its place are deliberate distractors.",
        ],
        "revisionRules": [
            "List each breeding example as a breed-variety paire (variety species outcome) in one sitting.",
            "Practise distinction questions between hybridisation, mutation breeding and polyploidy.",
        ],
    },
    "bio_ch10_12": {
        "keyFacts": [
            "Lactic-acid bacteria (Lactobacillus) curdle milk into curd; Saccharomyces produces ethanol while Acetobacter converts it to vinegar.",
            "Industrial products: citric acid (Aspergillus niger), lactic acid (Lactobacillus), acetic acid (Acetobacter), ethanol (Saccharomyces).",
            "Biofertilisers: Rhizobium in legume root nodules, free-living Azotobacter and Azospirillum, cyanobacteria such as Anabaena and Nostoc; Azolla hosts Anabaena.",
            "Biogas is 50-70% methane produced by obligate anaerobic methanogens (e.g. Methanobacterium) inside sludge digesters.",
        ],
        "diagrams": [
            "Fermenter cross-section with broth, pH/thermometer probes, heating coils and impeller aeration.",
            "Biogas plant sketch: mixing tank > inlet > digester chamber > gas holder dome > sludge outlet.",
        ],
        "pyqTraps": [
            "Statins from Monascus purpureus act as competitive inhibitors of the enzyme involved in cholesterol biosynthesis - confusing the organism with Streptomyces is a trap.",
            "Azolla (a fern) hosts Anabaena (a cyanobacterium); many MCQs reverse this with Azotobacter - keep the pairing straight.",
        ],
        "revisionRules": [
            "Recite a microbe-to-product one-liner list daily before assertion sets.",
            "Draw the fermentation/biogas plant flow once and annotate operations step by step.",
        ],
    },
    "bio_ch12_12": {
        "keyFacts": [
            "Restriction endonucleases cut phosphodiester bonds at palindromic sites; EcoRI (G^AATTC) leaves 5' AATT sticky overhangs.",
            "Cloning vectors need an ori, selectable markers (antibiotic resistance such as ampR/tetR in pBR322) and a multiple cloning site.",
            "Competent bacterial hosts are made permeable with CaCl2 (and heat shock/electroporation) for transformation.",
            "Bt toxins (cry proteins from Bacillus thuringiensis) are protoxins activated in the alkaline insect midgut; Bt cotton and Bt corn express them.",
        ],
        "diagrams": [
            "Cloning-vector map: ori, multiple cloning site (EcoRI, HindIII, BamHI), ampR and tetR selectable markers.",
            "Agrobacterium Ti plasmid transfer flow: T-DNA excision > plant nuclear genome integration.",
        ],
        "pyqTraps": [
            "EcoRI produces 5' AATT overhangs; any option quoting a different overhang or cut position is a deliberate trap.",
            "Bt protoxin activates in the ALKALINE pH of the insect gut - options that say acidic or 'plant pH' invert the fact.",
        ],
        "revisionRules": [
            "List vector criteria in order and label which marker enables selection versus maintenance.",
            "Recall one restriction enzyme name, palindrome and overhang set before PYQ drills.",
        ],
    },
}


def dart_block(cid: str) -> str:
    c = CONTENT[cid]
    out = ["    keyFacts: ["]
    for kf in c["keyFacts"]:
        out.append(f"      '{kf}',")
    out.append("    ],")
    out.append("    diagrams: [")
    for dg in c["diagrams"]:
        out.append(f"      '{dg}',")
    out.append("    ],")
    out.append("    pyqTraps: [")
    for pt in c["pyqTraps"]:
        out.append(f"      '{pt}',")
    out.append("    ],")
    out.append("    revisionRules: [")
    for rr in c["revisionRules"]:
        out.append(f"      '{rr}',")
    out.append("    ],")
    return "\n".join(out)


with open(PATH, encoding="utf-8") as f:
    src = f.read()

filled = 0
for cid in CONTENT:
    pattern = re.compile(
        r"'%s': StudyResourceContent\((.*?)\n  \),\n" % re.escape(cid), re.S
    )
    m = pattern.search(src)
    if not m:
        print(f"WARN: entry not found: {cid}")
        continue
    body = m.group(1)
    if "keyFacts" in body:
        print(f"SKIP (already filled): {cid}")
        continue
    old = m.group(0)
    rewritten = old.replace(
        "\n  ),\n", "\n" + dart_block(cid) + "\n  ),\n"
    )
    src = src.replace(old, rewritten, 1)
    filled += 1

with open(PATH, "w", encoding="utf-8") as f:
    f.write(src)
print(f"filled {filled} entries (#={len(CONTENT)})")
