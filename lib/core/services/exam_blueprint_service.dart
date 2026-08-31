import '../models/question_model.dart';
import 'unified_question_pool_service.dart';
import 'exam_engine_service.dart';

/// Blueprint enforcement for Exam Engine.
/// Ensures the exam follows the official NEET blueprint with chapter quotas.
class ExamBlueprintService {
  // NEET 2025 Official Blueprint - Chapter-wise question distribution
  // Based on NTA Information Bulletin and historical analysis
  static const Map<String, Map<String, int>> _neetBlueprint = {
    'Physics': {
      'Mechanics': 10,
      'Electrodynamics': 9,
      'Modern Physics': 8,
      'Optics': 7,
      'Thermodynamics': 7,
      'Waves': 6,
      'SHM': 5,
      'Semiconductors': 6,
      'Communication Systems': 4,
    },
    'Chemistry': {
      'Chemical Bonding': 10,
      'Coordination Compounds': 8,
      'p-Block Elements': 8,
      'd- and f-Block Elements': 7,
      'Organic Chemistry - Basic Principles': 9,
      'Hydrocarbons': 8,
      'Alcohols, Phenols, Ethers': 7,
      'Aldehydes, Ketones, Carboxylic Acids': 7,
      'Biomolecules': 6,
      'Polymers': 5,
      'Chemistry in Everyday Life': 4,
      'Electrochemistry': 7,
      'Chemical Kinetics': 6,
      'Surface Chemistry': 5,
      'Solutions': 6,
      'Solid State': 5,
      'Thermodynamics': 7,
      'Equilibrium': 7,
    },
    'Botany': {
      'Plant Physiology': 10,
      'Genetics and Evolution': 10,
      'Ecology': 9,
      'Cell Biology': 8,
      'Biotechnology': 7,
      'Plant Reproduction': 6,
      'Microbes in Human Welfare': 5,
      'Biomolecules': 8,
    },
    'Zoology': {
      'Human Physiology': 12,
      'Human Reproduction': 7,
      'Genetics and Evolution': 10,
      'Ecology': 9,
      'Cell Biology': 8,
      'Biotechnology': 7,
      'Biomolecules': 8,
    },
  };

  /// Validates if a question allocation matches the NEET blueprint.
  /// Returns a map of chapter -> (expected, actual) for chapters that don't match.
  Map<String, (int expected, int actual)> validateAllocation(
    List<List<Question>> sectionQuestions,
    List<String> sectionSubjects,
  ) {
    final actualCounts = <String, int>{};
    
    for (int i = 0; i < sectionQuestions.length; i++) {
      final subject = sectionSubjects[i];
      for (final q in sectionQuestions[i]) {
        actualCounts[q.chapter] = (actualCounts[q.chapter] ?? 0) + 1;
      }
    }

    final mismatches = <String, (int, int)>{};
    for (final subjectEntry in _neetBlueprint.entries) {
      final subject = subjectEntry.key;
      final blueprint = subjectEntry.value;
      
      for (final chapterEntry in blueprint.entries) {
        final chapter = chapterEntry.key;
        final expected = chapterEntry.value;
        final actual = actualCounts[chapter] ?? 0;
        
        if (actual != expected) {
          mismatches[chapter] = (expected, actual);
        }
      }
    }

    return mismatches;
  }

  /// Generates a blueprint-compliant question allocation.
  /// Uses the unified question pool service to select questions per chapter.
  Future<List<List<Question>>> generateBlueprintAllocation({
    required UnifiedQuestionPoolService poolService,
    required int physicsCount,
    required int chemistryCount,
    required int botanyCount,
    required int zoologyCount,
    Set<String>? excludedIds,
  }) async {
    final sections = <List<Question>>[];
    
    // Physics sections
    if (physicsCount > 0) {
      sections.add(await _selectForSubject(
        poolService,
        'Physics',
        physicsCount,
        excludedIds,
      ));
    }
    
    // Chemistry sections
    if (chemistryCount > 0) {
      sections.add(await _selectForSubject(
        poolService,
        'Chemistry',
        chemistryCount,
        excludedIds,
      ));
    }
    
    // Botany sections
    if (botanyCount > 0) {
      sections.add(await _selectForSubject(
        poolService,
        'Botany',
        botanyCount,
        excludedIds,
      ));
    }
    
    // Zoology sections
    if (zoologyCount > 0) {
      sections.add(await _selectForSubject(
        poolService,
        'Zoology',
        zoologyCount,
        excludedIds,
      ));
    }

    return sections;
  }

  Future<List<Question>> _selectForSubject(
    UnifiedQuestionPoolService poolService,
    String subject,
    int count,
    Set<String>? excludedIds,
  ) async {
    final blueprint = _neetBlueprint[subject];
    if (blueprint == null) {
      // Fallback to simple selection
      return poolService.getQuestions(request: QuestionRequest(
        subjects: [subject],
        count: count,
      ));
    }

    // Calculate target per chapter based on blueprint proportions
    final totalBlueprint = blueprint.values.fold(0, (a, b) => a + b);
    final targets = <String, int>{};
    
    for (final entry in blueprint.entries) {
      final proportion = entry.value / totalBlueprint;
      targets[entry.key] = (count * proportion).round();
    }

    // Adjust to match exact count
    final diff = count - targets.values.fold<int>(0, (a, b) => a + b);
    if (diff != 0 && targets.isNotEmpty) {
      final firstKey = targets.keys.first;
      targets[firstKey] = (targets[firstKey] ?? 0) + diff;
    }

    final selected = <Question>[];
    final usedIds = <String>{};
    if (excludedIds != null) {
      usedIds.addAll(excludedIds);
    }

    for (final entry in targets.entries) {
      final chapter = entry.key;
      final target = entry.value;
      if (target <= 0) continue;

      final questions = await poolService.getQuestions(request: QuestionRequest(
        subjects: [subject],
        chapterId: chapter,
        count: target + 5, // Get extra for filtering
        excludeRecent: true,
        applyCooldown: true,
      ));

      for (final q in questions) {
        if (selected.length >= count) break;
        if (usedIds.contains(q.id)) continue;
        if (q.chapter != chapter) continue;
        selected.add(q);
        usedIds.add(q.id);
      }
    }

    // Backfill if short
    if (selected.length < count) {
      final remaining = await poolService.getQuestions(request: QuestionRequest(
        subjects: [subject],
        count: count - selected.length + 10,
        excludeRecent: true,
        applyCooldown: true,
      ));
      
      for (final q in remaining) {
        if (selected.length >= count) break;
        if (usedIds.contains(q.id)) continue;
        selected.add(q);
        usedIds.add(q.id);
      }
    }

    return selected.take(count).toList();
  }

  /// Gets the expected blueprint for a subject.
  Map<String, int> getBlueprint(String subject) {
    return Map.from(_neetBlueprint[subject] ?? {});
  }

  /// Gets all blueprints.
  Map<String, Map<String, int>> getAllBlueprints() {
    return Map.from(_neetBlueprint);
  }
}

/// Extension to add blueprint support to ExamConfig
extension ExamConfigBlueprint on ExamConfig {
  /// Returns a blueprint-compliant configuration for NEET.
  static ExamConfig neetBlueprint({
    int physicsCount = 45,
    int chemistryCount = 45,
    int botanyCount = 45,
    int zoologyCount = 45,
    int durationMinutes = 180,
    bool sectionLock = false,
    bool breaksEnabled = false,
    int breakMinutes = 5,
  }) {
    return ExamConfig.neet(
      physicsCount: physicsCount,
      chemistryCount: chemistryCount,
      botanyCount: botanyCount,
      zoologyCount: zoologyCount,
      durationMinutes: durationMinutes,
      sectionLock: sectionLock,
      breaksEnabled: breaksEnabled,
      breakMinutes: breakMinutes,
    );
  }
}