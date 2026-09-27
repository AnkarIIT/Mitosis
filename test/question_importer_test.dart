import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/services/question_importer.dart';

void main() {
  group('QuestionImporter.parseJson', () {
    test('parses a top-level array', () {
      const raw = '''
        [
          {"questionText": "Q1?", "options": ["A", "B", "C", "D"], "correctAnswer": "A"},
          {"questionText": "Q2?", "options": ["A", "B"], "correctAnswer": "B"}
        ]
      ''';
      final rows = QuestionImporter().parseJson(raw);
      expect(rows, hasLength(2));
      expect(rows.first['questionText'], 'Q1?');
    });

    test('parses an object wrapping a questions array', () {
      const raw = '''
        {"questions": [
          {"questionText": "Q?", "options": ["A", "B"], "correctAnswer": "A"}
        ]}
      ''';
      final rows = QuestionImporter().parseJson(raw);
      expect(rows, hasLength(1));
    });

    test('throws FormatException for invalid JSON', () {
      expect(
        () => QuestionImporter().parseJson('not json'),
        throwsFormatException,
      );
    });

    test('throws FormatException when the array contains non-objects', () {
      expect(
        () => QuestionImporter().parseJson('[1, 2, 3]'),
        throwsFormatException,
      );
    });
  });

  group('QuestionImporter.parseCsv', () {
    test('parses a header row and maps canonical names', () {
      const csv = '''
        questionText,correctAnswer,options,subject
        "What is 2+2?","4","1|||2|||3|||4",Biology
        "What is H2O?","Water","Ice|||Water|||Steam",Chemistry
      ''';
      final rows = QuestionImporter().parseCsv(csv);
      expect(rows, hasLength(2));
      expect(rows.first['questionText'], 'What is 2+2?');
      expect(rows.first['correctAnswer'], '4');
      expect(rows.first['options'], '1|||2|||3|||4');
    });

    test('handles quoted fields with embedded commas and newlines', () {
      const csv = '''
        questionText,options,correctAnswer
        "A, B and C","X","X"
        "Line1\nLine2","Y","Y"
      ''';
      final rows = QuestionImporter().parseCsv(csv);
      expect(rows, hasLength(2));
      expect(rows.first['questionText'], 'A, B and C');
      expect(rows[1]['questionText'], 'Line1\nLine2');
    });

    test('supports multi-column options (option1..optionN)', () {
      const csv = '''
        questionText,option1,option2,option3,option4,correctAnswer
        Pick one,W,X,Y,Z,W
      ''';
      final importer = QuestionImporter();
      final rows = importer.parseCsv(csv);
      final (questions, result) = importer.buildQuestions(rows);
      expect(questions, hasLength(1));
      expect(questions.first.options, ['W', 'X', 'Y', 'Z']);
      expect(result.errors, isEmpty);
    });
  });

  group('QuestionImporter.buildQuestions', () {
    test('normalizes subjects, difficulty, year and type', () {
      final rows = [
        {
          'questionText': 'Which planet is closest to the Sun?',
          'options': ['Mercury', 'Venus', 'Earth', 'Mars'],
          'correctAnswer': 'Mercury',
          'subject': 'bio',
          'difficulty': 'hard',
          'year': '2024 (PYQ)',
          'type': 'integer',
        },
      ];
      final (questions, result) = QuestionImporter().buildQuestions(rows);
      final q = questions.single;
      expect(q.subject, 'Biology');
      expect(q.difficulty, 'Hard');
      expect(q.year, 2024);
      expect(q.type, 'integer');
      expect(result.imported, 1);
    });

    test('skips rows missing required fields and reports errors', () {
      final rows = [
        {
          'questionText': '',
          'options': ['A', 'B'],
          'correctAnswer': 'A',
        },
        {
          'questionText': 'No answer',
          'options': ['A', 'B'],
        },
        {
          'questionText': 'Only one option',
          'options': ['A'],
          'correctAnswer': 'A',
        },
        {
          'questionText': 'Valid one',
          'options': ['A', 'B'],
          'correctAnswer': 'B',
        },
      ];
      final (questions, result) = QuestionImporter().buildQuestions(rows);
      expect(questions, hasLength(1));
      expect(result.imported, 1);
      expect(result.rejected, 3);
      expect(result.errors, hasLength(3));
      expect(
        result.errors.any((e) => e.contains('missing questionText')),
        isTrue,
      );
      expect(
        result.errors.any((e) => e.contains('missing correctAnswer')),
        isTrue,
      );
      expect(
        result.errors.any((e) => e.contains('at least 2 options')),
        isTrue,
      );
    });

    test('dedupes within a batch using normalized text', () {
      final rows = [
        {
          'questionText': '  Which   planet is closest? ',
          'options': ['Mercury', 'Venus'],
          'correctAnswer': 'Mercury',
        },
        {
          'questionText': 'Which planet is closest?',
          'options': ['Mercury', 'Venus'],
          'correctAnswer': 'Mercury',
        },
      ];
      final (questions, result) = QuestionImporter().buildQuestions(rows);
      expect(questions, hasLength(1));
      expect(result.skippedDuplicates, 1);
    });

    test('dedupes against already existing question texts', () {
      final rows = [
        {
          'questionText': 'Existing question',
          'options': ['A', 'B'],
          'correctAnswer': 'A',
        },
      ];
      final importer = QuestionImporter(
        existingTexts: {'existing question'},
        baseId: '5000000',
      );
      final (questions, result) = importer.buildQuestions(rows);
      expect(questions, isEmpty);
      expect(result.skippedDuplicates, 1);
    });

    test('assigns unique sequential ids from the base', () {
      final rows = [
        {
          'questionText': 'Q1',
          'options': ['A', 'B'],
          'correctAnswer': 'A',
        },
        {
          'questionText': 'Q2',
          'options': ['A', 'B'],
          'correctAnswer': 'B',
        },
        {
          'questionText': 'Q3',
          'options': ['A', 'B'],
          'correctAnswer': 'A',
        },
      ];
      final (questions, _) = QuestionImporter(
        baseId: 'q_9',
      ).buildQuestions(rows);
      expect(questions.map((q) => q.id).toList(), ['q_90', 'q_91', 'q_92']);
    });

    test('parses options stored as ||| separated string', () {
      final rows = [
        {'questionText': 'Q?', 'options': 'A|||B|||C', 'correctAnswer': 'A'},
      ];
      final (questions, _) = QuestionImporter().buildQuestions(rows);
      expect(questions.single.options, ['A', 'B', 'C']);
    });

    test('generates a topicId when none is provided', () {
      final rows = [
        {
          'questionText': 'Q?',
          'options': ['A', 'B'],
          'correctAnswer': 'A',
          'chapter': 'Some Chapter',
          'topic': 'A Topic',
        },
      ];
      final (questions, _) = QuestionImporter().buildQuestions(rows);
      expect(questions.single.topicId, 'some_chapter_a_topic');
    });
  });
}
