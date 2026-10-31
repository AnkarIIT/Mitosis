enum QuestionBand { easy, medium, hard }

class AdaptiveEngineService {
  /// Determines the next question difficulty band based on current band and correctness.
  static QuestionBand nextBand(QuestionBand current, bool correct) {
    return switch ((current, correct)) {
      (QuestionBand.easy, true) => QuestionBand.medium,
      (QuestionBand.medium, true) => QuestionBand.hard,
      (QuestionBand.hard, true) => QuestionBand.hard,
      (QuestionBand.easy, false) => QuestionBand.easy,
      (QuestionBand.medium, false) => QuestionBand.easy,
      (QuestionBand.hard, false) => QuestionBand.medium,
    };
  }

  /// Calculates subject difficulty progression for a sequence of answers.
  static QuestionBand evaluateSession(List<bool> correctnessHistory, {QuestionBand initialBand = QuestionBand.medium}) {
    QuestionBand current = initialBand;
    for (final correct in correctnessHistory) {
      current = nextBand(current, correct);
    }
    return current;
  }
}
