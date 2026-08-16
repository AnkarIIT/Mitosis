import '../database/drift_database.dart' as db;

/// SM-2 / Leitner hybrid scheduler for MCQ retention.
///
/// A card is created when a question is first answered incorrectly. Correct
/// reviews walk the interval ladder 1 → 3 → 7 → 21 days and then multiply by
/// the ease factor (SM-2) with a 60-day ceiling, while the Leitner box climbs
/// 0 → 4. Incorrect reviews reset to day 1, drop the box to 0, and increment
/// the lapse count so repeated failures are resurfaced immediately.
///
/// All logic is pure (no I/O) so it can be unit-tested in isolation.
class SpacedRepetitionService {
  static const double initialEaseFactor = 2.5;
  static const double minEaseFactor = 1.3;
  static const double maxEaseFactor = 3.0;
  static const double easeGain = 0.1;
  static const double easePenalty = 0.32;
  static const int maxIntervalDays = 60;
  static const int maxBox = 4;

  /// The interval ladder applied for consecutive correct reviews.
  static const List<int> ladder = [1, 3, 7, 21];

  /// Computes the next card state after answering [isCorrect].
  ///
  /// [card] is the current stored card, or null when the question is being
  /// scheduled for the first time (always treated as an incorrect answer).
  static db.SpacedRepetitionData review({
    required int questionId,
    required db.SpacedRepetitionData? card,
    required bool isCorrect,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final base = card ??
        db.SpacedRepetitionData(
          questionId: questionId,
          box: 0,
          easeFactor: initialEaseFactor,
          intervalDays: 0,
          repetitions: 0,
          lapses: 0,
          dueAt: t,
        );

    var interval = base.intervalDays;
    var repetitions = base.repetitions;
    var box = base.box;
    var lapses = base.lapses;
    var easeFactor = base.easeFactor;

    if (isCorrect) {
      if (repetitions < ladder.length) {
        interval = ladder[repetitions];
      } else {
        interval = (interval * easeFactor).round().clamp(1, maxIntervalDays);
      }
      repetitions += 1;
      box = box < maxBox ? box + 1 : box;
      easeFactor = (easeFactor + easeGain).clamp(
        minEaseFactor,
        maxEaseFactor,
      );
    } else {
      interval = 1;
      repetitions = 0;
      box = 0;
      lapses += 1;
      easeFactor = (easeFactor - easePenalty).clamp(
        minEaseFactor,
        maxEaseFactor,
      );
    }

    return db.SpacedRepetitionData(
      questionId: questionId,
      box: box,
      easeFactor: easeFactor,
      intervalDays: interval,
      repetitions: repetitions,
      lapses: lapses,
      dueAt: t.add(Duration(days: interval)),
      lastReviewedAt: t,
      updatedAt: t,
    );
  }

  static bool isDue(db.SpacedRepetitionData card, {DateTime? now}) {
    final t = now ?? DateTime.now();
    return !card.dueAt.isAfter(t);
  }
}
