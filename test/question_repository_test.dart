import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/database/question_repository.dart';
import 'package:neet_mitos/core/models/question_model.dart' as model;

void main() {
  late AppDatabase db;
  late QuestionRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = QuestionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('QuestionRepository Tests', () {
    test(
      'insertSampleQuestions should insert questions when database is empty',
      () async {
        await repository.insertSampleQuestions();

        final questions = await repository.getAllQuestionsFromDb();
        expect(questions.length, greaterThan(0));
      },
    );

    test(
      'getQuestionsBySubject should return only questions for that subject',
      () async {
        final q1 = model.Question(
          id: '1',
          subject: 'Biology',
          chapter: 'Cell',
          topic: 'Mitochondria',
          topicId: 'bio1',
          questionText: 'Test bio question',
          options: ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          difficulty: 'Easy',
          tags: [],
          type: 'mcq',
          createdAt: DateTime.now(),
        );
        final q2 = model.Question(
          id: '2',
          subject: 'Physics',
          chapter: 'Motion',
          topic: 'Speed',
          topicId: 'phy1',
          questionText: 'Test phy question',
          options: ['A', 'B', 'C', 'D'],
          correctAnswer: 'B',
          difficulty: 'Medium',
          tags: [],
          type: 'mcq',
          createdAt: DateTime.now(),
        );

        await db
            .into(db.questions)
            .insert(
              QuestionsCompanion(
                id: const Value<String>('1'),
                subject: Value<String>(q1.subject),
                chapter: Value<String>(q1.chapter),
                topic: Value<String>(q1.topic),
                topicId: Value<String>(q1.topicId),
                questionText: Value<String>(q1.questionText),
                options: Value<String>(q1.options.join('|||')),
                correctAnswer: Value<String>(q1.correctAnswer),
                difficulty: Value<String>(q1.difficulty),
                tags: Value<String>(q1.tags.join('|||')),
                type: Value<String>(q1.type),
              ),
            );
        await db
            .into(db.questions)
            .insert(
              QuestionsCompanion(
                id: const Value<String>('2'),
                subject: Value<String>(q2.subject),
                chapter: Value<String>(q2.chapter),
                topic: Value<String>(q2.topic),
                topicId: Value<String>(q2.topicId),
                questionText: Value<String>(q2.questionText),
                options: Value<String>(q2.options.join('|||')),
                correctAnswer: Value<String>(q2.correctAnswer),
                difficulty: Value<String>(q2.difficulty),
                tags: Value<String>(q2.tags.join('|||')),
                type: Value<String>(q2.type),
              ),
            );

        final bioQuestions = await repository.getQuestionsBySubject('Biology');
        expect(bioQuestions.length, 1);
        expect(bioQuestions.first.subject, 'Biology');
      },
    );

    test('getQuestionsByTopicId should filter correctly', () async {
      final q1 = model.Question(
        id: '1',
        subject: 'Biology',
        chapter: 'Cell',
        topic: 'Mitochondria',
        topicId: 'bio_topic_1',
        questionText: 'Test mitochondria',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'A',
        difficulty: 'Easy',
        tags: [],
        type: 'mcq',
        createdAt: DateTime.now(),
      );

      await db
          .into(db.questions)
          .insert(
            QuestionsCompanion(
              id: const Value<String>('1'),
              subject: Value<String>(q1.subject),
              chapter: Value<String>(q1.chapter),
              topic: Value<String>(q1.topic),
              topicId: Value<String>(q1.topicId),
              questionText: Value<String>(q1.questionText),
              options: Value<String>(q1.options.join('|||')),
              correctAnswer: Value<String>(q1.correctAnswer),
              difficulty: Value<String>(q1.difficulty),
              tags: Value<String>(q1.tags.join('|||')),
              type: Value<String>(q1.type),
            ),
          );

      final topicQuestions = await repository.getQuestionsByTopicId(
        'bio_topic_1',
      );
      expect(topicQuestions.length, 1);
      expect(topicQuestions.first.topicId, 'bio_topic_1');
    });
  });
}
