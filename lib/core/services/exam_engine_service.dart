import 'dart:math';
import '../models/question_model.dart';
import '../utils/answer_normalizer.dart';

enum ExamMode { neet, practice }

/// One block of an exam paper.
///
/// [presentedCount] (M) is how many questions are *shown* in the section.
/// [gradedCount] (N) is how many *count* toward the score. When they differ
/// the section is optional ("attempt any N of M") and answers beyond the first
/// N (in ascending question order) are discarded — not penalised. For a
/// compulsory section they are equal.
class ExamSection {
  final int index;
  final String name;
  final String sourceSubject;
  final int presentedCount;
  final int gradedCount;
  final int? durationSeconds;

  ExamSection({
    required this.index,
    required this.name,
    required this.sourceSubject,
    required this.presentedCount,
    int? gradedCount,
    this.durationSeconds,
  }) : gradedCount = gradedCount ?? presentedCount;

  bool get isOptional => gradedCount < presentedCount;

  /// Back-compat alias: the number of questions shown in this section.
  int get questionCount => presentedCount;

  Map<String, dynamic> toJson() => {
    'index': index,
    'name': name,
    'sourceSubject': sourceSubject,
    'presentedCount': presentedCount,
    'gradedCount': gradedCount,
    'durationSeconds': durationSeconds,
  };

  factory ExamSection.fromJson(Map<String, dynamic> json) => ExamSection(
    index: json['index'] as int,
    name: json['name'] as String,
    sourceSubject: json['sourceSubject'] as String? ?? '',
    presentedCount: (json['presentedCount'] ?? json['questionCount']) as int,
    gradedCount: json['gradedCount'] as int?,
    durationSeconds: json['durationSeconds'] as int?,
  );
}

class ExamConfig {
  final ExamMode mode;
  final String testType;
  final String topicId;
  final String subjectLabel;
  final int totalDurationSeconds;
  final bool sectionLock;
  final bool breaksEnabled;
  final int breakDurationSeconds;
  final int breakAfterSectionIndex;
  final int marksPerCorrect;
  final int marksPerWrong;

  /// Whether this is a full-length NEET simulation. Only full-length mocks
  /// surface a percentile/AIR estimate on the result screen (short practice
  /// tests hide it — too little signal to estimate a rank honestly).
  final bool isFullLengthMock;
  final List<ExamSection> sections;

  const ExamConfig({
    required this.mode,
    required this.testType,
    required this.topicId,
    required this.subjectLabel,
    required this.totalDurationSeconds,
    required this.sectionLock,
    required this.breaksEnabled,
    required this.breakDurationSeconds,
    required this.breakAfterSectionIndex,
    required this.marksPerCorrect,
    required this.marksPerWrong,
    required this.sections,
    this.isFullLengthMock = false,
  });

  /// Total questions shown across all sections.
  int get totalPresented => sections.fold(0, (s, x) => s + x.presentedCount);

  /// Back-compat alias for [totalPresented].
  int get totalQuestionSlots => totalPresented;

  /// Total questions that count toward the score (Σ gradedCount).
  int get totalGraded => sections.fold(0, (s, x) => s + x.gradedCount);

  /// Maximum achievable score based on the *graded* question count.
  int get maxScoreTotal => totalGraded * marksPerCorrect;

  /// Back-compat alias (presented-based) kept for older callers.
  int get marksPerCorrectTotal => totalPresented * marksPerCorrect;

  // ─────────────────────────────────────────────────────────────
  // Factories
  //
  // ⚠️ ACCURACY: The exam-pattern numbers below (duration, per-section
  // counts, marking scheme, optional-section rules, breaks) are configurable
  // *defaults*, not asserted facts. Verify them against the official NTA
  // information bulletin before each season and adjust here — the engine is
  // pattern-agnostic, only these factories pick the numbers.
  // ─────────────────────────────────────────────────────────────

  /// Modern flat full-length mock: 180 compulsory questions (4×45), 180
  /// minutes, +4/−1, free navigation, no break. This is the default USP mock.
  static ExamConfig neet({
    int physicsCount = 45,
    int chemistryCount = 45,
    int botanyCount = 45,
    int zoologyCount = 45,
    int durationMinutes = 180,
    bool sectionLock = false,
    bool breaksEnabled = false,
    int breakMinutes = 5,
    int? physicsMinutes,
    int? chemistryMinutes,
    int? botanyMinutes,
    int? zoologyMinutes,
  }) {
    final defaultSectionSeconds = durationMinutes * 60 ~/ 4;
    final physicsSec = physicsMinutes != null
        ? physicsMinutes * 60
        : defaultSectionSeconds;
    final chemistrySec = chemistryMinutes != null
        ? chemistryMinutes * 60
        : defaultSectionSeconds;
    final botanySec = botanyMinutes != null
        ? botanyMinutes * 60
        : defaultSectionSeconds;
    final zoologySec = zoologyMinutes != null
        ? zoologyMinutes * 60
        : durationMinutes * 60 - physicsSec - chemistrySec - botanySec;
    return ExamConfig(
      mode: ExamMode.neet,
      testType: 'mock',
      topicId: 'mock_test',
      subjectLabel: 'NEET',
      totalDurationSeconds: durationMinutes * 60,
      sectionLock: sectionLock,
      breaksEnabled: breaksEnabled,
      breakDurationSeconds: breakMinutes * 60,
      breakAfterSectionIndex: breaksEnabled ? 1 : -1,
      marksPerCorrect: 4,
      marksPerWrong: -1,
      isFullLengthMock: true,
      sections: [
        ExamSection(
          index: 0,
          name: 'Physics',
          sourceSubject: 'Physics',
          presentedCount: physicsCount,
          durationSeconds: physicsSec,
        ),
        ExamSection(
          index: 1,
          name: 'Chemistry',
          sourceSubject: 'Chemistry',
          presentedCount: chemistryCount,
          durationSeconds: chemistrySec,
        ),
        ExamSection(
          index: 2,
          name: 'Botany',
          sourceSubject: 'Biology',
          presentedCount: botanyCount,
          durationSeconds: botanySec,
        ),
        ExamSection(
          index: 3,
          name: 'Zoology',
          sourceSubject: 'Biology',
          presentedCount: zoologyCount,
          durationSeconds: zoologySec,
        ),
      ],
    );
  }

  /// NTA NEET 2024 exact pattern: 200 questions (attempt 180), 200 minutes.
  ///
  /// Structure per official NTA Information Bulletin:
  /// - Physics: 35A + 15B (attempt 10 of 15)
  /// - Chemistry: 35A + 15B (attempt 10 of 15)
  /// - Botany: 35A + 15B (attempt 10 of 15)
  /// - Zoology: 35A + 15B (attempt 10 of 15)
  /// - Total: 140 compulsory + 60 optional = 200 presented, 180 graded
  /// - Duration: 200 minutes, NO per-section timing, NO scheduled breaks
  /// - Navigation: Free within Section A block (indices 0-3), free within
  ///   Section B block (indices 4-7). No cross-block nav until A is done.
  /// - Marking: +4 / -1 / 0
  static ExamConfig neet2024({
    int sectionACount = 35,
    int sectionBPresented = 15,
    int sectionBGraded = 10,
    int durationMinutes = 200,
    bool sectionLock = false, // Free nav within A-block and B-block
  }) {
    ExamSection sectionA(int index, String name, String source) => ExamSection(
      index: index,
      name: '$name · A',
      sourceSubject: source,
      presentedCount: sectionACount,
      gradedCount: sectionACount,
    );
    ExamSection sectionB(int index, String name, String source) => ExamSection(
      index: index,
      name: '$name · B',
      sourceSubject: source,
      presentedCount: sectionBPresented,
      gradedCount: sectionBGraded,
    );

    return ExamConfig(
      mode: ExamMode.neet,
      testType: 'mock',
      topicId: 'mock_test',
      subjectLabel: 'NEET',
      totalDurationSeconds: durationMinutes * 60,
      sectionLock: sectionLock, // Lock only between A-block and B-block
      breaksEnabled: false, // NTA NEET has NO scheduled breaks
      breakDurationSeconds: 0,
      breakAfterSectionIndex: -1,
      marksPerCorrect: 4,
      marksPerWrong: -1,
      isFullLengthMock: true,
      sections: [
        // Section A block (indices 0-3): all compulsory, free navigation within
        sectionA(0, 'Physics', 'Physics'),
        sectionA(1, 'Chemistry', 'Chemistry'),
        sectionA(2, 'Botany', 'Biology'),
        sectionA(3, 'Zoology', 'Biology'),
        // Section B block (indices 4-7): optional, free navigation within
        sectionB(4, 'Physics', 'Physics'),
        sectionB(5, 'Chemistry', 'Chemistry'),
        sectionB(6, 'Botany', 'Biology'),
        sectionB(7, 'Zoology', 'Biology'),
      ],
    );
  }

  /// Legacy 180-question pattern (pre-2020). Kept for backward compatibility.
  static ExamConfig neetLegacy({
    int physicsCount = 45,
    int chemistryCount = 45,
    int botanyCount = 45,
    int zoologyCount = 45,
    int durationMinutes = 180,
    bool sectionLock = false,
    bool breaksEnabled = false,
    int breakMinutes = 5,
    int? physicsMinutes,
    int? chemistryMinutes,
    int? botanyMinutes,
    int? zoologyMinutes,
  }) {
    final defaultSectionSeconds = durationMinutes * 60 ~/ 4;
    final physicsSec = physicsMinutes != null
        ? physicsMinutes * 60
        : defaultSectionSeconds;
    final chemistrySec = chemistryMinutes != null
        ? chemistryMinutes * 60
        : defaultSectionSeconds;
    final botanySec = botanyMinutes != null
        ? botanyMinutes * 60
        : defaultSectionSeconds;
    final zoologySec = zoologyMinutes != null
        ? zoologyMinutes * 60
        : durationMinutes * 60 - physicsSec - chemistrySec - botanySec;
    return ExamConfig(
      mode: ExamMode.neet,
      testType: 'mock',
      topicId: 'mock_test',
      subjectLabel: 'NEET',
      totalDurationSeconds: durationMinutes * 60,
      sectionLock: sectionLock,
      breaksEnabled: breaksEnabled,
      breakDurationSeconds: breakMinutes * 60,
      breakAfterSectionIndex: breaksEnabled ? 1 : -1,
      marksPerCorrect: 4,
      marksPerWrong: -1,
      isFullLengthMock: true,
      sections: [
        ExamSection(
          index: 0,
          name: 'Physics',
          sourceSubject: 'Physics',
          presentedCount: physicsCount,
          durationSeconds: physicsSec,
        ),
        ExamSection(
          index: 1,
          name: 'Chemistry',
          sourceSubject: 'Chemistry',
          presentedCount: chemistryCount,
          durationSeconds: chemistrySec,
        ),
        ExamSection(
          index: 2,
          name: 'Botany',
          sourceSubject: 'Biology',
          presentedCount: botanyCount,
          durationSeconds: botanySec,
        ),
        ExamSection(
          index: 3,
          name: 'Zoology',
          sourceSubject: 'Biology',
          presentedCount: zoologyCount,
          durationSeconds: zoologySec,
        ),
      ],
    );
  }

  static ExamConfig practice({
    required int questionCount,
    required int durationMinutes,
    String subjectLabel = 'Practice',
    bool sectionLock = false,
  }) {
    return ExamConfig(
      mode: ExamMode.practice,
      testType: 'practice',
      topicId: 'cbt_practice',
      subjectLabel: subjectLabel,
      totalDurationSeconds: durationMinutes * 60,
      sectionLock: sectionLock,
      breaksEnabled: false,
      breakDurationSeconds: 0,
      breakAfterSectionIndex: -1,
      marksPerCorrect: 4,
      marksPerWrong: -1,
      isFullLengthMock: false,
      sections: [
        ExamSection(
          index: 0,
          name: 'All Subjects',
          sourceSubject: '',
          presentedCount: questionCount,
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'testType': testType,
    'topicId': topicId,
    'subjectLabel': subjectLabel,
    'totalDurationSeconds': totalDurationSeconds,
    'sectionLock': sectionLock,
    'breaksEnabled': breaksEnabled,
    'breakDurationSeconds': breakDurationSeconds,
    'breakAfterSectionIndex': breakAfterSectionIndex,
    'marksPerCorrect': marksPerCorrect,
    'marksPerWrong': marksPerWrong,
    'isFullLengthMock': isFullLengthMock,
    'sections': sections.map((s) => s.toJson()).toList(),
  };

  factory ExamConfig.fromJson(Map<String, dynamic> json) => ExamConfig(
    mode: ExamMode.values.firstWhere(
      (m) => m.name == json['mode'],
      orElse: () => ExamMode.practice,
    ),
    testType: json['testType'] as String,
    topicId: json['topicId'] as String,
    subjectLabel: json['subjectLabel'] as String,
    totalDurationSeconds: json['totalDurationSeconds'] as int,
    sectionLock: json['sectionLock'] as bool,
    breaksEnabled: json['breaksEnabled'] as bool,
    breakDurationSeconds: json['breakDurationSeconds'] as int,
    breakAfterSectionIndex: json['breakAfterSectionIndex'] as int,
    marksPerCorrect: json['marksPerCorrect'] as int,
    marksPerWrong: json['marksPerWrong'] as int,
    isFullLengthMock: json['isFullLengthMock'] as bool? ?? false,
    sections: (json['sections'] as List)
        .map((s) => ExamSection.fromJson((s as Map).cast<String, dynamic>()))
        .toList(),
  );
}

class QuestionResult {
  final Question question;
  final String? selectedAnswer;
  final int marks;

  /// Whether this answer counts toward the score. Compulsory questions always
  /// count; optional (N-of-M) questions answered beyond the graded cap do not.
  final bool counted;

  const QuestionResult({
    required this.question,
    required this.selectedAnswer,
    required this.marks,
    this.counted = true,
  });

  bool get isCorrect =>
      counted &&
      selectedAnswer != null &&
      ExamEngineService.isAnswerCorrect(selectedAnswer, question);

  bool get isIncorrect =>
      counted &&
      selectedAnswer != null &&
      !ExamEngineService.isAnswerCorrect(selectedAnswer, question);

  bool get isUnanswered => selectedAnswer == null;

  /// Answered but beyond an optional section's graded cap: 0 marks, no penalty.
  bool get isDiscarded => selectedAnswer != null && !counted;
}

class ExamScore {
  final ExamConfig config;
  final List<QuestionResult> results;

  /// Maximum achievable score for the *actual* allocation, capped per section
  /// at min(gradedCount, allocatedLength). Computed by [ExamEngineService.grade].
  final int maxScore;

  /// Section index for each result, parallel to [results]. Lets the result
  /// screen break scores down by section name (e.g. Botany vs Zoology).
  final List<int> sectionIndexByResult;

  const ExamScore({
    required this.config,
    required this.results,
    required this.maxScore,
    this.sectionIndexByResult = const [],
  });

  int get correct => results.where((r) => r.isCorrect).length;

  int get incorrect => results.where((r) => r.isIncorrect).length;

  int get unanswered => results.where((r) => r.isUnanswered).length;

  int get discarded => results.where((r) => r.isDiscarded).length;

  int get attempted => correct + incorrect;

  int get rawScore => results.fold(0, (sum, r) => sum + r.marks);

  double get accuracy => attempted == 0 ? 0 : (correct / attempted) * 100;

  double get answeredAccuracy =>
      maxScore == 0 ? 0 : (rawScore / maxScore * 100);

  List<QuestionResult> resultsFor(String subject) =>
      results.where((r) => r.question.subject == subject).toList();

  /// Results belonging to section [index].
  List<QuestionResult> resultsForSection(int index) {
    if (sectionIndexByResult.length != results.length) return const [];
    return [
      for (int i = 0; i < results.length; i++)
        if (sectionIndexByResult[i] == index) results[i],
    ];
  }
}

class ExamEngineService {
  /// Normalised answer comparison used everywhere scoring happens (grading and
  /// the error-book/spaced-repetition re-grade), so they can never disagree.
  static bool isAnswerCorrect(String? answer, Question q) {
    return AnswerNormalizer.isCorrect(answer, q);
  }

  /// Drops questions that can't be graded fairly: empty text, fewer than two
  /// usable options, or a correct answer that isn't among the options (after
  /// trimming). Returns the clean list so a launcher can refuse an unusable
  /// pool instead of starting a test that would mis-grade or crash.
  static List<Question> validatePool(List<Question> pool) {
    return pool.where((q) {
      if (q.questionText.trim().isEmpty) return false;
      final opts = q.options
          .map((o) => o.trim())
          .where((o) => o.isNotEmpty)
          .toList();
      if (opts.length < 2) return false;
      if (!AnswerNormalizer.isCorrect(q.correctAnswer, q)) return false;
      return true;
    }).toList();
  }

  static List<Question> sampleQuestions(
    List<Question> pool,
    int count, {
    int? seed,
  }) {
    final shuffled = List<Question>.from(pool);
    shuffled.shuffle(Random(seed ?? DateTime.now().millisecondsSinceEpoch));
    return shuffled.take(count).toList();
  }

  static List<List<Question>> allocateQuestions(
    List<Question> pool,
    ExamConfig config, {
    int? seed,
    Set<String>? excludedIds,
  }) {
    var remaining = pool
        .where((q) => excludedIds == null || !excludedIds.contains(q.id))
        .toList();
    if (remaining.isEmpty) remaining = List<Question>.from(pool);
    remaining.shuffle(Random(seed ?? DateTime.now().millisecondsSinceEpoch));
    final allocated = List.generate(
      config.sections.length,
      (_) => <Question>[],
    );
    final takenIds = <String>{};

    for (int s = 0; s < config.sections.length; s++) {
      final section = config.sections[s];
      final taken = <Question>[];
      for (final q in remaining) {
        if (taken.length >= section.presentedCount) break;
        if (takenIds.contains(q.id)) continue;
        if (section.sourceSubject.isNotEmpty) {
          final qSub = q.subject.toLowerCase();
          final sSub = section.sourceSubject.toLowerCase();
          final matches =
              qSub == sSub ||
              (sSub == 'biology' && (qSub == 'botany' || qSub == 'zoology')) ||
              (sSub == 'botany' && qSub == 'biology') ||
              (sSub == 'zoology' && qSub == 'biology');
          if (!matches) continue;
        }
        taken.add(q);
        takenIds.add(q.id);
      }
      allocated[s] = taken;
    }
    return allocated;
  }

  static bool hasSufficientPool(
    List<Question> pool,
    ExamConfig config, {
    int? seed,
  }) {
    final allocation = allocateQuestions(pool, config, seed: seed);
    if (allocation.length != config.sections.length) return false;
    for (var i = 0; i < allocation.length; i++) {
      if (allocation[i].length < config.sections[i].presentedCount) {
        return false;
      }
    }
    return true;
  }

  static List<Question> flattenAllocated(List<List<Question>> sections) => [
    for (final section in sections) ...section,
  ];

  /// Grades an attempt against the *actual* allocation so section boundaries
  /// and optional N-of-M caps are respected.
  ///
  /// [sectionQuestions] is the per-section allocation (same order as
  /// [ExamConfig.sections]); [answersByIndex] is keyed by the flattened global
  /// index (section 0 first, then section 1, …). Per section: among answered
  /// questions in ascending order, the first `min(gradedCount, allocated)`
  /// count; answers beyond that are discarded (0 marks, no penalty); unanswered
  /// score 0.
  static ExamScore grade({
    required ExamConfig config,
    required List<List<Question>> sectionQuestions,
    required Map<int, String?> answersByIndex,
  }) {
    final results = <QuestionResult>[];
    final sectionIndexByResult = <int>[];
    int maxScore = 0;
    int globalIndex = 0;

    for (int s = 0; s < sectionQuestions.length; s++) {
      final secQs = sectionQuestions[s];
      final gradedCount = s < config.sections.length
          ? config.sections[s].gradedCount
          : secQs.length;
      final cap = gradedCount < secQs.length ? gradedCount : secQs.length;
      maxScore += cap * config.marksPerCorrect;

      int answeredSoFar = 0;
      for (int j = 0; j < secQs.length; j++) {
        final q = secQs[j];
        final raw = answersByIndex[globalIndex];
        final answer = (raw == null || raw.isEmpty) ? null : raw;

        bool counted;
        int marks;
        if (answer == null) {
          counted = true;
          marks = 0;
        } else {
          answeredSoFar++;
          if (answeredSoFar <= cap) {
            counted = true;
            marks = isAnswerCorrect(answer, q)
                ? config.marksPerCorrect
                : config.marksPerWrong;
          } else {
            // Beyond the graded cap of an optional section → discarded.
            counted = false;
            marks = 0;
          }
        }

        results.add(
          QuestionResult(
            question: q,
            selectedAnswer: answer,
            marks: marks,
            counted: counted,
          ),
        );
        sectionIndexByResult.add(s);
        globalIndex++;
      }
    }

    return ExamScore(
      config: config,
      results: results,
      maxScore: maxScore,
      sectionIndexByResult: sectionIndexByResult,
    );
  }

  /// Returns true if the exam config uses the NTA NEET 2024 A/B block structure.
  static bool isNeet2024(ExamConfig config) {
    if (!config.isFullLengthMock || config.mode != ExamMode.neet) return false;
    if (config.sections.length != 8) return false;
    // Sections 0-3 should be A (graded == presented), 4-7 should be B (graded < presented)
    for (int i = 0; i < 4; i++) {
      if (config.sections[i].gradedCount != config.sections[i].presentedCount)
        return false;
    }
    for (int i = 4; i < 8; i++) {
      if (config.sections[i].gradedCount >= config.sections[i].presentedCount)
        return false;
    }
    return true;
  }

  /// For NEET 2024: determines which block a section index belongs to.
  /// 0 = Section A block (indices 0-3), 1 = Section B block (indices 4-7), -1 = other.
  static int getNeet2024Block(int sectionIndex) {
    if (sectionIndex >= 0 && sectionIndex <= 3) return 0;
    if (sectionIndex >= 4 && sectionIndex <= 7) return 1;
    return -1;
  }
}
