import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../models/spaced_repetition_model.dart';
import '../database/drift_database.dart' as db;
import '../services/spaced_repetition_service.dart';
import 'core_providers.dart';
import 'content_providers.dart';
import 'quiz_providers.dart';

// ============= SPACED REPETITION =============
final spacedRepetitionCardsProvider =
    FutureProvider<List<db.SpacedRepetitionData>>(
      (ref) => ref.watch(databaseProvider).getSpacedRepetitionCards(),
    );

final spacedRepetitionSummaryProvider = FutureProvider<SpacedRepetitionSummary>(
  (ref) async {
    final cards = await ref.watch(spacedRepetitionCardsProvider.future);
    final now = DateTime.now();
    return SpacedRepetitionSummary(
      totalCards: cards.length,
      dueCount: cards.where((c) => !c.dueAt.isAfter(now)).length,
      inLearning: cards.where((c) => c.box <= 1).length,
      mastered: cards.where((c) => c.box >= 4).length,
    );
  },
);

final dueCardsProvider = FutureProvider<List<Question>>((ref) async {
  final dbInstance = ref.watch(databaseProvider);
  final due = await dbInstance.getDueSpacedRepetition(DateTime.now());
  if (due.isEmpty) return const [];
  final allQuestions = await ref.watch(allQuestionsProvider.future);
  final byId = {for (final q in allQuestions) q.id: q};
  return due
      .map((card) => byId[card.questionId])
      .whereType<Question>()
      .toList();
});

final spacedReviewRecorderProvider = Provider<SpacedReviewRecorder>((ref) {
  return SpacedReviewRecorder(ref);
});

class SpacedReviewRecorder {
  SpacedReviewRecorder(this._ref);
  final Ref _ref;

  Future<void> recordAnswer({
    required String questionId,
    required bool isCorrect,
  }) async {
    final dbInstance = _ref.read(databaseProvider);
    final card = await dbInstance.getSpacedRepetition(questionId);
    final next = SpacedRepetitionService.review(
      questionId: questionId,
      card: card,
      isCorrect: isCorrect,
    );
    await dbInstance.upsertSpacedRepetition(next);
    if (isCorrect) {
      await dbInstance.removeFromErrorBook(questionId);
    } else {
      await dbInstance.addToErrorBook(db.ErrorBookCompanion.insert(
        questionId: questionId,
        addedAt: DateTime.now(),
      ));
    }
    _ref.invalidate(spacedRepetitionCardsProvider);
    _ref.invalidate(dueCardsProvider);
    _ref.invalidate(spacedRepetitionSummaryProvider);
    _ref.invalidate(errorBookProvider);
  }
}
