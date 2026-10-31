import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/services/adaptive_engine_service.dart';

void main() {
  group('AdaptiveEngineService V0 Tests', () {
    test('Correct answer moves up difficulty band', () {
      expect(AdaptiveEngineService.nextBand(QuestionBand.easy, true), QuestionBand.medium);
      expect(AdaptiveEngineService.nextBand(QuestionBand.medium, true), QuestionBand.hard);
      expect(AdaptiveEngineService.nextBand(QuestionBand.hard, true), QuestionBand.hard);
    });

    test('Incorrect answer moves down or clamps difficulty band', () {
      expect(AdaptiveEngineService.nextBand(QuestionBand.easy, false), QuestionBand.easy);
      expect(AdaptiveEngineService.nextBand(QuestionBand.medium, false), QuestionBand.easy);
      expect(AdaptiveEngineService.nextBand(QuestionBand.hard, false), QuestionBand.medium);
    });

    test('Session evaluation correctly tracks progression', () {
      // Start medium, correct -> hard, correct -> hard, incorrect -> medium
      final finalBand = AdaptiveEngineService.evaluateSession(
        [true, true, false],
        initialBand: QuestionBand.medium,
      );
      expect(finalBand, QuestionBand.medium);
    });
  });
}
