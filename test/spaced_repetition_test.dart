import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/services/spaced_repetition_service.dart';

void main() {
  group('SpacedRepetitionService (SM-2 variant)', () {
    test('first incorrect answer creates a card due tomorrow', () {
      final now = DateTime(2026, 8, 17, 10);
      final card = SpacedRepetitionService.review(
        questionId: '1',
        card: null,
        isCorrect: false,
        now: now,
      );

      expect(card.questionId, '1');
      expect(card.box, 0);
      expect(card.repetitions, 0);
      expect(card.intervalDays, 1);
      expect(card.lapses, 1);
      expect(card.dueAt, now.add(const Duration(days: 1)));
      expect(card.lastReviewedAt, now);
      expect(card.easeFactor, closeTo(2.18, 0.001));
    });

    test('consecutive correct answers climb the 1→3→7→21 ladder', () {
      var now = DateTime(2026, 8, 17, 10);
      SpacedRepetitionData? card;

      final expectedIntervals = [1, 3, 7, 21];
      var expectedRepetitions = 0;
      var expectedBox = 0;
      for (final expected in expectedIntervals) {
        now = now.add(Duration(days: expected));
        card = SpacedRepetitionService.review(
          questionId: '1',
          card: card,
          isCorrect: true,
          now: now,
        );
        expectedRepetitions += 1;
        expectedBox += 1;
        expect(card.intervalDays, expected);
        expect(card.repetitions, expectedRepetitions);
        expect(card.box, expectedBox);
      }
    });

    test('correct answers advance box and ease factor', () {
      final now = DateTime(2026, 8, 17, 10);
      final base = SpacedRepetitionService.review(
        questionId: '1',
        card: null,
        isCorrect: false,
        now: now,
      );

      var card = SpacedRepetitionService.review(
        questionId: '1',
        card: base,
        isCorrect: true,
        now: now.add(const Duration(days: 1)),
      );
      expect(card.box, 1);
      expect(card.easeFactor, closeTo(2.28, 0.001));

      card = SpacedRepetitionService.review(
        questionId: '1',
        card: card,
        isCorrect: true,
        now: now.add(const Duration(days: 4)),
      );
      expect(card.box, 2);
      expect(card.easeFactor, closeTo(2.38, 0.001));
    });

    test('after the ladder, interval is multiplied by ease factor', () {
      final now = DateTime(2026, 8, 17, 10);
      final card = SpacedRepetitionData(
        questionId: '1',
        box: 4,
        easeFactor: 2.5,
        intervalDays: 21,
        repetitions: 4,
        lapses: 0,
        dueAt: now,
      );

      final next = SpacedRepetitionService.review(
        questionId: '1',
        card: card,
        isCorrect: true,
        now: now,
      );
      expect(next.intervalDays, (21 * 2.5).round()); // 53
    });

    test('interval growth is capped at 60 days', () {
      final now = DateTime(2026, 8, 17, 10);
      final card = SpacedRepetitionData(
        questionId: '1',
        box: 4,
        easeFactor: 3.0,
        intervalDays: 40,
        repetitions: 6,
        lapses: 0,
        dueAt: now,
      );

      final next = SpacedRepetitionService.review(
        questionId: '1',
        card: card,
        isCorrect: true,
        now: now,
      );
      expect(next.intervalDays, 60);
    });

    test('incorrect answers reset interval and increment lapses', () {
      final now = DateTime(2026, 8, 17, 10);
      final card = SpacedRepetitionData(
        questionId: '1',
        box: 3,
        easeFactor: 2.5,
        intervalDays: 21,
        repetitions: 3,
        lapses: 0,
        dueAt: now,
      );

      final next = SpacedRepetitionService.review(
        questionId: '1',
        card: card,
        isCorrect: false,
        now: now,
      );
      expect(next.box, 0);
      expect(next.intervalDays, 1);
      expect(next.repetitions, 0);
      expect(next.lapses, 1);
      expect(next.easeFactor, closeTo(2.18, 0.001));
    });

    test('ease factor is clamped to [1.3, 3.0]', () {
      final now = DateTime(2026, 8, 17, 10);
      final low = SpacedRepetitionData(
        questionId: '1',
        box: 0,
        easeFactor: 1.3,
        intervalDays: 1,
        repetitions: 0,
        lapses: 5,
        dueAt: now,
      );
      final afterPenalty = SpacedRepetitionService.review(
        questionId: '1',
        card: low,
        isCorrect: false,
        now: now,
      );
      expect(afterPenalty.easeFactor, 1.3);

      final high = SpacedRepetitionData(
        questionId: '1',
        box: 4,
        easeFactor: 3.0,
        intervalDays: 21,
        repetitions: 5,
        lapses: 0,
        dueAt: now,
      );
      final afterGain = SpacedRepetitionService.review(
        questionId: '1',
        card: high,
        isCorrect: true,
        now: now,
      );
      expect(afterGain.easeFactor, 3.0);
    });

    test('isDue returns true when dueAt is in the past or now', () {
      final now = DateTime(2026, 8, 17, 10);
      final past = SpacedRepetitionData(
        questionId: '1',
        box: 0,
        easeFactor: 2.5,
        intervalDays: 1,
        repetitions: 0,
        lapses: 0,
        dueAt: now.subtract(const Duration(minutes: 1)),
      );
      final future = SpacedRepetitionData(
        questionId: '1',
        box: 0,
        easeFactor: 2.5,
        intervalDays: 1,
        repetitions: 0,
        lapses: 0,
        dueAt: now.add(const Duration(minutes: 1)),
      );
      final exact = SpacedRepetitionData(
        questionId: '1',
        box: 0,
        easeFactor: 2.5,
        intervalDays: 1,
        repetitions: 0,
        lapses: 0,
        dueAt: now,
      );

      expect(SpacedRepetitionService.isDue(past, now: now), isTrue);
      expect(SpacedRepetitionService.isDue(future, now: now), isFalse);
      expect(SpacedRepetitionService.isDue(exact, now: now), isTrue);
    });
  });

  group('SpacedRepetition database (v18)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('upsert keeps a single card per question', () async {
      final now = DateTime(2026, 8, 17, 10);
      await db.upsertSpacedRepetition(
        SpacedRepetitionService.review(
          questionId: '1',
          card: null,
          isCorrect: false,
          now: now,
        ),
      );
      await db.upsertSpacedRepetition(
        SpacedRepetitionService.review(
          questionId: '1',
          card: SpacedRepetitionService.review(
            questionId: '1',
            card: null,
            isCorrect: false,
            now: now,
          ),
          isCorrect: true,
          now: now.add(const Duration(days: 1)),
        ),
      );

      final cards = await db.getSpacedRepetitionCards();
      expect(cards.length, 1);
      expect(cards.single.questionId, '1');
      expect(cards.single.box, 1);
    });

    test(
      'getDueSpacedRepetition returns only due cards, soonest first',
      () async {
        final now = DateTime(2026, 8, 17, 10);
        await db.upsertSpacedRepetition(
          SpacedRepetitionService.review(
            questionId: '1',
            card: null,
            isCorrect: false,
            now: now.subtract(const Duration(days: 2)),
          ),
        );
        await db.upsertSpacedRepetition(
          SpacedRepetitionService.review(
            questionId: '2',
            card: null,
            isCorrect: false,
            now: now.subtract(const Duration(days: 5)),
          ),
        );
        await db.upsertSpacedRepetition(
          SpacedRepetitionService.review(
            questionId: '3',
            card: null,
            isCorrect: false,
            now: now.subtract(const Duration(days: 1)),
          ),
        );

        final due = await db.getDueSpacedRepetition(now);
        expect(due.length, 3);
        expect(due[0].questionId, '2'); // oldest due first
        expect(due[2].questionId, '3');

        final noLongerDue = await db.getDueSpacedRepetition(
          now.subtract(const Duration(days: 6)),
        );
        expect(noLongerDue, isEmpty);
      },
    );

    test('removeSpacedRepetition deletes the card', () async {
      final now = DateTime(2026, 8, 17, 10);
      await db.upsertSpacedRepetition(
        SpacedRepetitionService.review(
          questionId: '1',
          card: null,
          isCorrect: false,
          now: now,
        ),
      );
      await db.removeSpacedRepetition('1');

      expect(await db.getSpacedRepetition('1'), isNull);
      expect(await db.getSpacedRepetitionCards(), isEmpty);
    });

    test('clearAllProgress also clears spaced-repetition cards', () async {
      final now = DateTime(2026, 8, 17, 10);
      await db.upsertSpacedRepetition(
        SpacedRepetitionService.review(
          questionId: '1',
          card: null,
          isCorrect: false,
          now: now,
        ),
      );
      await db.clearAllProgress();

      expect(await db.getSpacedRepetitionCards(), isEmpty);
    });
  });
}
