/// Service to check question inventory availability per subject.
///
/// Used to gate full-length mocks and show readiness on home screen.
library question_inventory_service;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/question_repository.dart';

/// Required questions per source subject for each mock type.
class MockRequirements {
  /// NEET 2024: 200 questions (180 graded)
  /// Physics: 50, Chemistry: 50, Botany: 50, Zoology: 50
  static const Map<String, int> neet2024 = {
    'Physics': 50,
    'Chemistry': 50,
    'Botany': 50,
    'Zoology': 50,
  };

  /// Legacy NEET: 180 questions, 45 each
  static const Map<String, int> neetLegacy = {
    'Physics': 45,
    'Chemistry': 45,
    'Botany': 45,
    'Zoology': 45,
  };

  /// Practice: configurable
  static const Map<String, int> practice = {};
}

/// Result of inventory check for a mock configuration.
class MockInventoryResult {
  const MockInventoryResult({
    required this.mockName,
    required this.requirements,
    required this.available,
    required this.shortages,
    required this.isReady,
  });

  final String mockName;
  final Map<String, int> requirements;
  final Map<String, int> available;
  final Map<String, int> shortages;
  final bool isReady;

  /// Overall readiness percentage (0-100).
  int get readinessPercent {
    if (requirements.isEmpty) return 100;
    int totalRequired = requirements.values.fold(0, (a, b) => a + b);
    int totalAvailable = available.entries
        .where((e) => requirements.containsKey(e.key))
        .fold(
          0,
          (a, e) =>
              a +
              (e.value < requirements[e.key]! ? e.value : requirements[e.key]!),
        );
    return ((totalAvailable / totalRequired) * 100).round();
  }

  @override
  String toString() =>
      'MockInventoryResult($mockName: ready=$isReady, $readinessPercent%, shortages=$shortages)';
}

/// Service to count available questions per subject and validate mock readiness.
class QuestionInventoryService {
  QuestionInventoryService(this._repository);

  final QuestionRepository _repository;

  /// Returns count of valid, active questions per subject.
  Future<Map<String, int>> getSubjectCounts() async {
    final questions = await _repository.getAllQuestionsFromDb();
    final counts = <String, int>{};
    for (final q in questions) {
      counts[q.subject] = (counts[q.subject] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns detailed inventory for a specific mock configuration.
  Future<MockInventoryResult> checkMockInventory({
    required String mockName,
    required Map<String, int> requirements,
  }) async {
    final available = await getSubjectCounts();
    final shortages = <String, int>{};
    bool isReady = true;

    for (final entry in requirements.entries) {
      final subject = entry.key;
      final required = entry.value;
      final availableCount = available[subject] ?? 0;
      if (availableCount < required) {
        shortages[subject] = required - availableCount;
        isReady = false;
      }
    }

    return MockInventoryResult(
      mockName: mockName,
      requirements: requirements,
      available: available,
      shortages: shortages,
      isReady: isReady,
    );
  }

  /// Check NEET 2024 mock readiness.
  Future<MockInventoryResult> checkNeet2024Readiness() async {
    return checkMockInventory(
      mockName: 'NEET 2024 Mock',
      requirements: MockRequirements.neet2024,
    );
  }

  /// Check legacy NEET mock readiness.
  Future<MockInventoryResult> checkNeetLegacyReadiness() async {
    return checkMockInventory(
      mockName: 'NEET Legacy Mock',
      requirements: MockRequirements.neetLegacy,
    );
  }

  /// Get human-readable shortage messages.
  List<String> getShortageMessages(MockInventoryResult result) {
    return result.shortages.entries.map((e) {
      final have = result.available[e.key] ?? 0;
      return '${e.key}: have $have, need ${e.value + have} (short by ${e.value})';
    }).toList();
  }
}

/// Provider for question inventory service.
final questionInventoryServiceProvider = Provider<QuestionInventoryService>((
  ref,
) {
  // Counts come entirely from the repository, so this deliberately does not
  // watch `databaseProvider` — doing so would rebuild (and re-query) the
  // readiness check on every unrelated database write.
  return QuestionInventoryService(ref.watch(questionRepositoryProvider));
});

/// Provider for NEET 2024 mock readiness check.
final neet2024ReadinessProvider = FutureProvider<MockInventoryResult>((
  ref,
) async {
  final service = ref.watch(questionInventoryServiceProvider);
  return service.checkNeet2024Readiness();
});

/// Provider for subject-wise question counts.
final subjectQuestionCountsProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final service = ref.watch(questionInventoryServiceProvider);
  return service.getSubjectCounts();
});
