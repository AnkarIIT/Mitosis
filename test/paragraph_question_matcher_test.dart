import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/services/paragraph_question_matcher.dart';

Question _q(
  String id,
  String topic,
  String questionText, {
  String subject = 'Biology',
  String chapter = 'The Living World',
}) {
  return Question(
    id: id,
    subject: subject,
    chapter: chapter,
    topic: topic,
    topicId: 't_$id',
    questionText: questionText,
    options: const ['A', 'B', 'C', 'D'],
    correctAnswer: 'B',
    difficulty: 'Medium',
    tags: const [],
    type: 'mcq',
  );
}

void main() {
  group('ParagraphQuestionMatcher.tokens', () {
    test('filters stopwords, short tokens and numbers', () {
      final tokens = ParagraphQuestionMatcher.tokens(
        'The plant kingdom includes algae bryophytes pteridophytes 123 with their structure',
      );
      expect(tokens, contains('plant'));
      expect(tokens, contains('kingdom'));
      expect(tokens, contains('bryophytes'));
      expect(tokens, isNot(contains('the')));
      expect(tokens, isNot(contains('with')));
      expect(tokens, isNot(contains('123')));
    });
  });

  group('ParagraphQuestionMatcher.score', () {
    test('counts shared significant tokens', () {
      final q = _q(
        '1',
        'Algae',
        'Which pigment is found in red algae?',
      );
      final score = ParagraphQuestionMatcher.score(
        'Algae are the simplest chlorophyll bearing autotrophic plants found '
        'in aquatic habitats',
        q,
      );
      expect(score, greaterThanOrEqualTo(1));
    });

    test('returns zero for unrelated text', () {
      final q = _q('1', 'Newton Laws', 'F equals mass times acceleration');
      final score = ParagraphQuestionMatcher.score(
        'The human heart pumps blood through arteries and veins',
        q,
      );
      expect(score, 0);
    });
  });

  group('ParagraphQuestionMatcher.matchingQuestions', () {
    test('returns matches ranked by score', () {
      final questions = [
        _q('1', 'Algae', 'Which pigment is found in red algae species?'),
        _q('2', 'Algae', 'Algae reproduce by fragmentation methods in water'),
        _q('3', 'Metabolism', 'Enzymes catalyse metabolic reactions'),
      ];
      const paragraph =
          'Algae are chlorophyll bearing plants that reproduce by '
          'fragmentation; the pigment in red algae species gives '
          'them their colour';
      final matched = ParagraphQuestionMatcher.matchingQuestions(
        paragraph,
        questions,
      );
      expect(matched, containsAll(questions.take(2)));
      expect(matched, isNot(contains(questions[2])));
    });

    test('returns empty when no question meets the threshold', () {
      final questions = [
        _q('1', 'Vectors', 'Angle between two perpendicular vectors'),
      ];
      final matched = ParagraphQuestionMatcher.matchingQuestions(
        'Cell cycle consists of interphase and mitosis division stages',
        questions,
      );
      expect(matched, isEmpty);
    });
  });
}
