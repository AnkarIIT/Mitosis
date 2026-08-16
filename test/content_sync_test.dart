import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
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

  group('Content Sync Schema (v17)', () {
    test('sync watermark round-trips and upserts on same key', () async {
      final first = DateTime.now().subtract(const Duration(hours: 1));
      final second = DateTime.now();

      await db.setSyncTimestamp('questions', first);
      await db.setSyncTimestamp('questions', second);

      final watermark = await db.getLastSyncTimestamp('questions');
      expect(watermark, isNotNull);
      expect(watermark!.difference(second).inSeconds.abs(), lessThan(5));
    });

    test('inactive remote questions are hidden from the repository', () async {
      await db.into(db.questions).insert(QuestionsCompanion(
            id: const Value<String>('90001'),
            subject: const Value<String>('Physics'),
            chapter: const Value<String>('Kinematics'),
            topic: const Value<String>('Motion'),
            topicId: const Value<String>('remote_ch'),
            questionText: const Value<String>('Remote text'),
            options: const Value<String>('A|||B|||C|||D'),
            correctAnswer: const Value<String>('A'),
            difficulty: const Value<String>('Medium'),
            tags: const Value<String>(''),
            type: const Value<String>('mcq'),
            remoteId: const Value<String>('uuid-remote-1'),
            updatedAt: Value(DateTime.now()),
            isActive: const Value(false),
          ));

      final active = await repository.getAllQuestionsFromDb();
      expect(active.where((q) => q.id == 90001), isEmpty);
    });

    test('remote questions are mapped to stable local Question models', () async {
      await db.into(db.questions).insert(QuestionsCompanion(
            id: const Value<String>('4242'),
            subject: const Value<String>('Botany'),
            chapter: const Value<String>('Cell Biology'),
            topic: const Value<String>('Cell'),
            topicId: const Value<String>('bot_ch2'),
            questionText: const Value<String>('Cell theory states?'),
            options: const Value<String>('A|||B|||C|||D'),
            correctAnswer: const Value<String>('B'),
            difficulty: const Value<String>('Easy'),
            tags: const Value<String>(''),
            type: const Value<String>('mcq'),
            remoteId: const Value<String>('uuid-remote-2'),
            updatedAt: Value(DateTime.now()),
          ));

      final all = await repository.getAllQuestionsFromDb();
      final remote = all.firstWhere((q) => q.id == 4242);
      expect(remote.subject, 'Botany');
      expect(remote.options, ['A', 'B', 'C', 'D']);
      expect(remote.correctAnswer, 'B');
    });
  });

  group('QuestionRepository Tests', () {
    test('insertSampleQuestions should insert questions when database is empty',
        () async {
      await repository.insertSampleQuestions();

      final questions = await repository.getAllQuestionsFromDb();
      expect(questions.length, greaterThan(0));
    });

    test('getQuestionsBySubject should return only questions for that subject',
        () async {
      final q1 = model.Question(
        id: 1,
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
        id: 2,
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

      await db.into(db.questions).insert(QuestionsCompanion(
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
          ));
      await db.into(db.questions).insert(QuestionsCompanion(
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
          ));

      final bioQuestions = await repository.getQuestionsBySubject('Biology');
      expect(bioQuestions.length, 1);
      expect(bioQuestions.first.subject, 'Biology');
    });

    test('getQuestionsByTopicId should filter correctly', () async {
      final q1 = model.Question(
        id: 1,
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

      await db.into(db.questions).insert(QuestionsCompanion(
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
          ));

      final topicQuestions =
          await repository.getQuestionsByTopicId('bio_topic_1');
      expect(topicQuestions.length, 1);
      expect(topicQuestions.first.topicId, 'bio_topic_1');
    });
  });
}