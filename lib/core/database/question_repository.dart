import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question_model.dart' as model;
import '../constants/neet_sample_data.dart' as sample;
import '../constants/neet_sample_data_phase2.dart' as sample2;
import '../services/question_importer.dart';
import 'drift_database.dart';
import '../providers/providers.dart';

class QuestionRepository {
  final AppDatabase db;

  QuestionRepository(this.db);

  /// Seeds all bundled sample questions. Idempotent: it inserts any seed
  /// question whose id is not already present, so fresh installs get the full
  /// bank and existing installs automatically receive newly added seed sets.
  Future<void> insertSampleQuestions() async {
    final existing = await db.select(db.questions).get();
    final existingIds = existing.map((q) => q.id).toSet();

    final allQuestions = [
      ...sample.getAllQuestions(),
      ...sample2.biologyQuestionsPhase2,
      ...sample2.biologyQuestionsPhase2Class12,
      ...sample2.chemistryQuestionsPhase2,
      ...sample2.physicsQuestionsPhase2,
    ];

    final toInsert = allQuestions
        .where((q) => !existingIds.contains(q.id))
        .toList();

    if (toInsert.isEmpty) return;

    await db.batch((batch) {
      for (var q in toInsert) {
        batch.insert(
          db.questions,
          QuestionsCompanion(
            id: Value<String>(q.id),
            subject: Value<String>(q.subject),
            chapter: Value<String>(q.chapter),
            topic: Value<String>(q.topic),
            topicId: Value<String>(q.topicId),
            questionText: Value<String>(q.questionText),
            options: Value<String>(q.options.join('|||')),
            correctAnswer: Value<String>(q.correctAnswer),
            explanation: Value<String?>(q.explanation),
            ncertReference: Value<String?>(q.ncertReference),
            year: Value<int?>(q.year),
            difficulty: Value<String>(q.difficulty),
            tags: Value<String>(q.tags.join('|||')),
            imageUrl: Value<String?>(q.imageUrl),
            type: Value<String>(q.type),
          ),
        );
      }
    });
    debugPrint('✅ Inserted ${toInsert.length} sample questions');
  }

  /// Imports questions from a bundled Flutter asset (e.g. "assets/questions/neet_sample_10.json").
  /// Deduplicates against existing question texts in the database.
  /// Returns the number of newly imported questions.
  Future<int> importBundledQuestions(String assetPath) async {
    final existing = await db.select(db.questions).get();
    final existingTexts = existing
        .map((q) => QuestionImporter.normalizeText(q.questionText))
        .toSet();

    final json = await rootBundle.loadString(assetPath);
    final importer = QuestionImporter();
    final rows = importer.parseJson(json);

    final (built, result) = QuestionImporter(
      existingTexts: existingTexts,
    ).buildQuestions(rows);

    if (built.isEmpty) return 0;

    await db.batch((batch) {
      for (final q in built) {
        batch.insert(
          db.questions,
          QuestionsCompanion(
            id: Value<String>(q.id),
            subject: Value<String>(q.subject),
            chapter: Value<String>(q.chapter),
            topic: Value<String>(q.topic),
            topicId: Value<String>(q.topicId),
            questionText: Value<String>(q.questionText),
            options: Value<String>(q.options.join('|||')),
            correctAnswer: Value<String>(q.correctAnswer),
            explanation: Value<String?>(q.explanation),
            ncertReference: Value<String?>(q.ncertReference),
            year: Value<int?>(q.year),
            difficulty: Value<String>(q.difficulty),
            tags: Value<String>(q.tags.join('|||')),
            imageUrl: Value<String?>(q.imageUrl),
            type: Value<String>(q.type),
          ),
        );
      }
    });

    debugPrint('✅ Imported ${built.length} questions from $assetPath');
    return built.length;
  }

  Future<List<model.Question>> getAllQuestionsFromDb() async {
    final data = await (db.select(
      db.questions,
    )
      ..where((tbl) => tbl.isActive.equals(true))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)])).get();

    return _mapQuestions(data);
  }

  /// Paginated fetch to prevent UI memory spikes when loading massive question sets.
  Future<List<model.Question>> getQuestionsPaginated({
    required int limit,
    required int offset,
    String? subject,
    String? topicId,
  }) async {
    final query = db.select(db.questions)
      ..where((tbl) {
        Expression<bool> predicate = tbl.isActive.equals(true);
        if (subject != null) {
          predicate = predicate & tbl.subject.equals(subject);
        }
        if (topicId != null) {
          predicate = predicate & tbl.topicId.equals(topicId);
        }
        return predicate;
      })
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)])
      ..limit(limit, offset: offset);

    final data = await query.get();
    return _mapQuestions(data);
  }

  Future<List<model.Question>> getQuestionsBySubject(String subject) async {
    final data =
        await (db.select(db.questions)
              ..where(
                (tbl) =>
                    tbl.isActive.equals(true) & tbl.subject.equals(subject),
              )
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
            .get();

    return _mapQuestions(data);
  }

  Future<List<model.Question>> getQuestionsByTopicId(String topicId) async {
    final data =
        await (db.select(db.questions)
              ..where(
                (tbl) =>
                    tbl.isActive.equals(true) & tbl.topicId.equals(topicId),
              )
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
            .get();

    return _mapQuestions(data);
  }

  Future<model.Question?> getQuestionById(String id) async {
    final row = await (db.select(db.questions)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return model.Question.fromMap({
      'id': row.id,
      'subject': row.subject,
      'chapter': row.chapter,
      'topic': row.topic,
      'topicId': row.topicId,
      'questionText': row.questionText,
      'options': row.options,
      'correctAnswer': row.correctAnswer,
      'explanation': row.explanation,
      'ncertReference': row.ncertReference,
      'year': row.year,
      'difficulty': row.difficulty,
      'tags': row.tags ?? '',
      'imageUrl': row.imageUrl,
      'type': row.type,
    });
  }

  Future<void> updateQuestionExplanation(String questionId, String explanation) async {
    await (db.update(db.questions)..where((tbl) => tbl.id.equals(questionId)))
        .write(QuestionsCompanion(explanation: Value<String>(explanation)));
  }

  /// Returns the canonicalized text of every question already stored, so
  /// imports can skip exact duplicates.
  Future<Set<String>> getExistingQuestionTexts() async {
    final results = await db.select(db.questions).get();
    return results
        .map((r) => QuestionImporter.normalizeText(r.questionText))
        .toSet();
  }

  /// Inserts many questions in a single transaction and returns how many were
  /// written. Duplicate ids are overwritten (insertOrReplace).
  Future<int> bulkInsertQuestions(List<model.Question> questions) async {
    if (questions.isEmpty) return 0;
    await db.batch((batch) {
      for (var q in questions) {
        batch.insert(
          db.questions,
          QuestionsCompanion(
            id: Value<String>(q.id),
            subject: Value<String>(q.subject),
            chapter: Value<String>(q.chapter),
            topic: Value<String>(q.topic),
            topicId: Value<String>(q.topicId),
            questionText: Value<String>(q.questionText),
            options: Value<String>(q.options.join('|||')),
            correctAnswer: Value<String>(q.correctAnswer),
            explanation: Value<String?>(q.explanation),
            ncertReference: Value<String?>(q.ncertReference),
            year: Value<int?>(q.year),
            difficulty: Value<String>(q.difficulty),
            tags: Value<String>(q.tags.join('|||')),
            imageUrl: Value<String?>(q.imageUrl),
            type: Value<String>(q.type),
          ),
        );
      }
    });
    return questions.length;
  }

  /// Inserts a single question. Duplicate ids are overwritten.
  Future<void> insertQuestion(model.Question question) async {
    await db.into(db.questions).insert(
      QuestionsCompanion(
        id: Value<String>(question.id),
        subject: Value<String>(question.subject),
        chapter: Value<String>(question.chapter),
        topic: Value<String>(question.topic),
        topicId: Value<String>(question.topicId),
        questionText: Value<String>(question.questionText),
        options: Value<String>(question.options.join('|||')),
        correctAnswer: Value<String>(question.correctAnswer),
        explanation: Value<String?>(question.explanation),
        ncertReference: Value<String?>(question.ncertReference),
        year: Value<int?>(question.year),
        difficulty: Value<String>(question.difficulty),
        tags: Value<String>(question.tags.join('|||')),
        imageUrl: Value<String?>(question.imageUrl),
        type: Value<String>(question.type),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  List<model.Question> _mapQuestions(List<dynamic> rows) {
    return rows
        .map(
          (row) => model.Question.fromMap({
            'id': row.id,
            'subject': row.subject,
            'chapter': row.chapter,
            'topic': row.topic,
            'topicId': row.topicId,
            'questionText': row.questionText,
            'options': row.options,
            'correctAnswer': row.correctAnswer,
            'explanation': row.explanation,
            'ncertReference': row.ncertReference,
            'year': row.year,
            'difficulty': row.difficulty,
            'tags': row.tags ?? '',
            'imageUrl': row.imageUrl,
            'type': row.type,
          }),
        )
        .toList();
  }
}

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return QuestionRepository(db);
});
