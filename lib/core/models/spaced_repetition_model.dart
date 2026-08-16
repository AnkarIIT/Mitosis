/// Roll-up of the spaced-repetition schedule used by the home screen and
/// review entry points.
class SpacedRepetitionSummary {
  const SpacedRepetitionSummary({
    required this.totalCards,
    required this.dueCount,
    required this.inLearning,
    required this.mastered,
  });

  final int totalCards;
  final int dueCount;

  /// Cards still near the start of the ladder (box 0-1).
  final int inLearning;

  /// Cards that reached the top of the Leitner ladder (box 4).
  final int mastered;

  bool get isEmpty => totalCards == 0;
}
