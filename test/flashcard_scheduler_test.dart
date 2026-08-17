import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/services/flashcard_scheduler_service.dart';

void main() {
  final fixedNow = DateTime(2026, 8, 17, 12);

  group('FlashcardScheduler', () {
    test('first "good" review uses ladder[0] = 1 day', () {
      final result = FlashcardScheduler.review(
        rating: FlashcardRating.good,
        now: fixedNow,
      );
      expect(result.intervalDays, 1);
      expect(result.repetitions, 1);
      expect(result.box, 1);
      expect(result.lapses, 0);
      expect(result.dueAt, fixedNow.add(const Duration(days: 1)));
    });

    test('three consecutive "good" reviews climb the ladder 1→3→7', () {
      var r = FlashcardScheduler.review(rating: FlashcardRating.good, now: fixedNow);
      r = FlashcardScheduler.review(
        rating: FlashcardRating.good,
        box: r.box,
        easeFactor: r.easeFactor,
        intervalDays: r.intervalDays,
        repetitions: r.repetitions,
        lapses: r.lapses,
        now: fixedNow,
      );
      r = FlashcardScheduler.review(
        rating: FlashcardRating.good,
        box: r.box,
        easeFactor: r.easeFactor,
        intervalDays: r.intervalDays,
        repetitions: r.repetitions,
        lapses: r.lapses,
        now: fixedNow,
      );
      expect(r.intervalDays, 7);
      expect(r.repetitions, 3);
      expect(r.box, 3);
    });

    test('"again" resets interval to 1, bumps lapses, resets box', () {
      final result = FlashcardScheduler.review(
        rating: FlashcardRating.again,
        box: 3,
        easeFactor: 2.6,
        intervalDays: 7,
        repetitions: 3,
        lapses: 0,
        now: fixedNow,
      );
      expect(result.intervalDays, 1);
      expect(result.repetitions, 0);
      expect(result.box, 0);
      expect(result.lapses, 1);
      expect(result.easeFactor, closeTo(2.28, 0.01));
    });

    test('"hard" keeps interval, penalises ease, does not advance box', () {
      final result = FlashcardScheduler.review(
        rating: FlashcardRating.hard,
        box: 2,
        easeFactor: 2.5,
        intervalDays: 3,
        repetitions: 2,
        now: fixedNow,
      );
      expect(result.intervalDays, 3);
      expect(result.repetitions, 3);
      expect(result.box, 2);
      expect(result.easeFactor, closeTo(2.35, 0.01));
    });

    test('"easy" advances ladder one step ahead', () {
      final result = FlashcardScheduler.review(
        rating: FlashcardRating.easy,
        box: 0,
        easeFactor: 2.5,
        intervalDays: 0,
        repetitions: 0,
        now: fixedNow,
      );
      expect(result.intervalDays, 3);
      expect(result.repetitions, 1);
      expect(result.box, 1);
      expect(result.easeFactor, closeTo(2.65, 0.01));
    });

    test('ease factor is clamped to [1.3, 3.0]', () {
      var r = FlashcardScheduler.review(
        rating: FlashcardRating.again,
        easeFactor: 1.3,
        now: fixedNow,
      );
      expect(r.easeFactor, 1.3);

      r = FlashcardScheduler.review(
        rating: FlashcardRating.easy,
        easeFactor: 2.95,
        box: 3,
        repetitions: 4,
        intervalDays: 21,
        now: fixedNow,
      );
      expect(r.easeFactor, 3.0);
    });

    test('box is capped at 4', () {
      final result = FlashcardScheduler.review(
        rating: FlashcardRating.good,
        box: 4,
        easeFactor: 2.5,
        intervalDays: 21,
        repetitions: 4,
        now: fixedNow,
      );
      expect(result.box, 4);
    });

    test('interval is capped at 60 days', () {
      final result = FlashcardScheduler.review(
        rating: FlashcardRating.good,
        box: 4,
        easeFactor: 3.0,
        intervalDays: 55,
        repetitions: 10,
        now: fixedNow,
      );
      expect(result.intervalDays, lessThanOrEqualTo(60));
    });

    test('isDue returns true for past due dates', () {
      expect(FlashcardScheduler.isDue(fixedNow.subtract(const Duration(days: 1)), now: fixedNow), true);
      expect(FlashcardScheduler.isDue(fixedNow, now: fixedNow), true);
      expect(FlashcardScheduler.isDue(fixedNow.add(const Duration(days: 1)), now: fixedNow), false);
    });
  });
}
