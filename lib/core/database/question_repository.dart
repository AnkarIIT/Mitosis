import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/question_model.dart' as model; 
import '../constants/neet_sample_data.dart' as sample;
import '../constants/neet_sample_data_phase2.dart' as sample2;
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
        .where((q) => !existingIds.contains(q.id.toString()))
        .toList();

    if (toInsert.isEmpty) return;

    await db.batch((batch) {
      for (var q in toInsert) {
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

  Future<List<model.Question>> getAllQuestionsFromDb() async {
    final data = await (db.select(
      db.questions,
    )
      ..where((tbl) => tbl.isActive.equals(true))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)])).get();

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
