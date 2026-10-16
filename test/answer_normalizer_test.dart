import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/utils/answer_normalizer.dart';

void main() {
  final question = Question(
    id: 'q1',
    subject: 'Physics',
    chapter: 'Motion',
    topic: 'Speed',
    topicId: 'speed',
    questionText: 'Which option is correct?',
    options: ['First', 'Second', 'Third', 'Fourth'],
    correctAnswer: 'Second',
    difficulty: 'Easy',
    tags: [],
    type: 'mcq',
  );

  test('resolves option text and letter answers', () {
    expect(AnswerNormalizer.isCorrect('Second', question), isTrue);
    expect(AnswerNormalizer.isCorrect('B', question), isTrue);
    expect(AnswerNormalizer.isCorrect('b', question), isTrue);
  });

  test('resolves zero-based and one-based numeric answers', () {
    expect(AnswerNormalizer.isCorrect('1', question), isTrue);
    expect(AnswerNormalizer.optionIndex('4', question), 3);
  });

  test('rejects empty and invalid answers', () {
    expect(AnswerNormalizer.isCorrect(null, question), isFalse);
    expect(AnswerNormalizer.isCorrect('', question), isFalse);
    expect(AnswerNormalizer.isCorrect('Z', question), isFalse);
  });
}
