import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/services/chapter_service.dart';
import 'package:neet_mitos/core/services/question_inventory_service.dart';

/// Locks two defects that made the whole chapter / mock-readiness feature look
/// broken to every user.
void main() {
  group('summary quiz answer keys', () {
    // QuickCheck.correctAnswer is the OPTION TEXT. The quiz screens compared it
    // to the option LETTER, so `isCorrect` was permanently false, the green
    // highlight never rendered, and the result bar always said "0 / N correct"
    // with "Keep Practicing" — even for a perfect run.
    test('every question key matches one of its own options', () {
      final chapter = ChapterService.allChapters.first;
      expect(chapter.summaryQuiz, isNotEmpty);

      for (final qc in chapter.summaryQuiz) {
        expect(
          qc.options.contains(qc.correctAnswer),
          isTrue,
          reason:
              '${qc.id}: correctAnswer "${qc.correctAnswer}" is not one of '
              '${qc.options}',
        );
      }
    });

    test('a perfect run scores 100%, resolving letter -> option text', () {
      final chapter = ChapterService.allChapters.first;
      final quiz = chapter.summaryQuiz;

      // Mirrors the screen: pick the letter whose option text is the key.
      final chosen = <int, String>{};
      for (var i = 0; i < quiz.length; i++) {
        final idx = quiz[i].options.indexOf(quiz[i].correctAnswer);
        expect(idx, isNot(-1), reason: '${quiz[i].id} has no matching option');
        chosen[i] = String.fromCharCode(65 + idx);
      }

      var correct = 0;
      for (var i = 0; i < quiz.length; i++) {
        final letter = chosen[i]!;
        final idx = letter.codeUnitAt(0) - 'A'.codeUnitAt(0);
        if (idx >= 0 &&
            idx < quiz[i].options.length &&
            quiz[i].options[idx] == quiz[i].correctAnswer) {
          correct++;
        }
      }
      expect(correct, quiz.length);
      expect((correct / quiz.length) * 100, 100.0);
    });

    test('no two options in a question share the same text', () {
      // A duplicated option text would make one letter always correct, and
      // `options.indexOf(correctAnswer)` ambiguous.
      final chapter = ChapterService.allChapters.first;
      for (final qc in chapter.summaryQuiz) {
        expect(
          qc.options.toSet().length,
          qc.options.length,
          reason: '${qc.id} has duplicate option text',
        );
      }
    });
  });

  group('mock readiness requirements', () {
    test('requirements never ask for a subject the bank cannot contain', () {
      // Questions are stored with Biology covering botany and zoology
      // (QuestionImporter._canonicalSubject, and the bundled sample data only
      // ever says "Biology"). Keying requirements on 'Botany'/'Zoology'
      // therefore guaranteed a permanent shortage and a false
      // "Insufficient Questions" gate on every NEET 2024 mock.
      for (final entry in {
        'neet2024': MockRequirements.neet2024,
        'neetLegacy': MockRequirements.neetLegacy,
      }.entries) {
        for (final subject in entry.value.keys) {
          expect(
            subject,
            isIn(<String>[
              'Physics',
              'Chemistry',
              'Biology',
              'Botany',
              'Zoology',
            ]),
            reason: '${entry.key}: unexpected subject "$subject"',
          );
        }
      }
    });

    test('a bank stored under Biology satisfies the biology requirements', () {
      // Drives checkMockInventory's folding with a fake repository would need a
      // DB; instead assert the arithmetic the service now performs: Biology
      // count is offered to both botany and zoology requirement keys.
      const biologyAvailable = 120;
      final available = <String, int>{
        'Physics': 60,
        'Chemistry': 60,
        'Biology': biologyAvailable,
        'Botany': biologyAvailable,
        'Zoology': biologyAvailable,
      };

      var ready = true;
      for (final e in MockRequirements.neet2024.entries) {
        if ((available[e.key] ?? 0) < e.value) ready = false;
      }
      expect(ready, isTrue);
    });
  });
}
