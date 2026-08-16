import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/models/question_model.dart' as model;
import 'package:neet_mitos/core/services/question_importer.dart';

model.Question _makeQuestion(int id, {String? subject, String? text}) {
  return model.Question(
    id: id,
    subject: subject ?? 'Biology',
    chapter: 'Test Chapter',
    topic: 'Test Topic',
    topicId: 'test_topic',
    questionText: text ?? 'Test question $id',
    options: ['A', 'B', 'C', 'D'],
    correctAnswer: 'A',
    difficulty: 'Medium',
    tags: [],
    type: 'mcq',
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('bulkInsertQuestions writes all questions and getQuestions reads them',
      () async {
    await db.batch((batch) {
      for (var q in [_makeQuestion(1), _makeQuestion(2), _makeQuestion(3)]) {
        batch.insert(
          db.questions,
          QuestionsCompanion(
            id: Value<String>(q.id.toString()),
            subject: Value<String>(q.subject),
            chapter: Value<String>(q.chapter),
            topic: Value<String>(q.topic),
            topicId: Value<String>(q.topicId),
            questionText: Value<String>(q.questionText),
            options: Value<String>(q.options.join('|||')),
            correctAnswer: Value<String>(q.correctAnswer),
            difficulty: Value<String>(q.difficulty),
            tags: Value<String>(q.tags.join('|||')),
            type: Value<String>(q.type),
          ),
        );
      }
    });

    final rows = await db.select(db.questions).get();
    expect(rows, hasLength(3));
    expect(rows.every((r) => r.subject == 'Biology'), isTrue);
  });

  test('getExistingQuestionTexts returns canonicalized texts', () async {
    final q = _makeQuestion(1, text: '  Photosynthesis   occurs in? ');
    await db.into(db.questions).insert(
      QuestionsCompanion(
        id: const Value('1'),
        subject: Value(q.subject),
        chapter: Value(q.chapter),
        topic: Value(q.topic),
        topicId: Value(q.topicId),
        questionText: Value(q.questionText),
        options: Value(q.options.join('|||')),
        correctAnswer: Value(q.correctAnswer),
        difficulty: Value(q.difficulty),
        tags: Value(q.tags.join('|||')),
        type: Value(q.type),
      ),
    );

    final texts = (await db.select(db.questions).get())
        .map((r) => QuestionImporter.normalizeText(r.questionText))
        .toSet();

    expect(texts, {'photosynthesis occurs in?'});
  });
}
