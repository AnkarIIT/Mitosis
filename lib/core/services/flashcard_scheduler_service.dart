/// SM-2 / Leitner hybrid scheduler for flashcard review sessions.
///
/// Mirrors the algorithm in [SpacedRepetitionService] but operates on
/// flashcard-specific data. Ratings map to a 4-button bar:
///   Again → incorrect   (reset interval, bump lapse)
///   Hard  → correct (hard)  (same interval, small ease penalty)
///   Good  → correct        (advance interval via ladder/SM-2)
///   Easy  → correct (easy)  (advance interval, extra ease bonus)
class FlashcardSchedulerService {
  static const double initialEaseFactor = 2.5;
  static const double minEaseFactor = 1.3;
  static const double maxEaseFactor = 3.0;
  static const double easeGainGood = 0.1;
  static const double easeGainEasy = 0.15;
  static const double easePenaltyHard = 0.15;
  static const double easePenaltyAgain = 0.32;
  static const int maxIntervalDays = 60;
  static const int maxBox = 4;

  /// The interval ladder for the first 4 correct repetitions.
  static const List<int> ladder = [1, 3, 7, 21];
}

/// Rating applied to a flashcard during a review session.
enum FlashcardRating { again, hard, good, easy }

/// Pure result of scheduling — no I/O, fully testable.
class FlashcardScheduleResult {
  const FlashcardScheduleResult({
    required this.box,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.lapses,
    required this.dueAt,
  });

  final int box;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final int lapses;
  final DateTime dueAt;

  @override
  String toString() =>
      'ScheduleResult(box=$box, ease=$easeFactor, interval=${intervalDays}d, due=$dueAt)';
}

/// Pure scheduler — no database or network calls.
class FlashcardScheduler {
  /// Computes the next card state after [rating].
  ///
  /// [box], [easeFactor], [intervalDays], [repetitions], [lapses] are the
  /// current stored values (all default to 0/2.5 on first review).
  static FlashcardScheduleResult review({
    required FlashcardRating rating,
    int box = 0,
    double easeFactor = FlashcardSchedulerService.initialEaseFactor,
    int intervalDays = 0,
    int repetitions = 0,
    int lapses = 0,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    var interval = intervalDays;
    var reps = repetitions;
    var b = box;
    var l = lapses;
    var ef = easeFactor;

    switch (rating) {
      case FlashcardRating.again:
        interval = 1;
        reps = 0;
        b = 0;
        l += 1;
        ef = (ef - FlashcardSchedulerService.easePenaltyAgain).clamp(
          FlashcardSchedulerService.minEaseFactor,
          FlashcardSchedulerService.maxEaseFactor,
        );

      case FlashcardRating.hard:
        // Keep same interval, small ease penalty, don't advance box.
        reps += 1;
        ef = (ef - FlashcardSchedulerService.easePenaltyHard).clamp(
          FlashcardSchedulerService.minEaseFactor,
          FlashcardSchedulerService.maxEaseFactor,
        );

      case FlashcardRating.good:
        if (reps < FlashcardSchedulerService.ladder.length) {
          interval = FlashcardSchedulerService.ladder[reps];
        } else {
          interval = (interval * ef)
              .round()
              .clamp(1, FlashcardSchedulerService.maxIntervalDays);
        }
        reps += 1;
        b = b < FlashcardSchedulerService.maxBox ? b + 1 : b;
        ef = (ef + FlashcardSchedulerService.easeGainGood).clamp(
          FlashcardSchedulerService.minEaseFactor,
          FlashcardSchedulerService.maxEaseFactor,
        );

      case FlashcardRating.easy:
        if (reps < FlashcardSchedulerService.ladder.length) {
          // Easy skips one step ahead on the ladder.
          final ladderIdx = (reps + 1).clamp(0, FlashcardSchedulerService.ladder.length - 1);
          interval = FlashcardSchedulerService.ladder[ladderIdx];
        } else {
          interval = (interval * ef * 1.2)
              .round()
              .clamp(1, FlashcardSchedulerService.maxIntervalDays);
        }
        reps += 1;
        b = b < FlashcardSchedulerService.maxBox ? b + 1 : b;
        ef = (ef + FlashcardSchedulerService.easeGainEasy).clamp(
          FlashcardSchedulerService.minEaseFactor,
          FlashcardSchedulerService.maxEaseFactor,
        );
    }

    return FlashcardScheduleResult(
      box: b,
      easeFactor: ef,
      intervalDays: interval,
      repetitions: reps,
      lapses: l,
      dueAt: t.add(Duration(days: interval)),
    );
  }

  static bool isDue(DateTime dueAt, {DateTime? now}) {
    return !(dueAt.isAfter(now ?? DateTime.now()));
  }
}
