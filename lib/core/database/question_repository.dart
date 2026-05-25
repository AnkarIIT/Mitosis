import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/question_model.dart'
    as model; // ← Use alias to avoid conflict
import 'drift_database.dart';
import '../constants/neet_sample_data.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

class QuestionRepository {
  final AppDatabase db;

  QuestionRepository(this.db);

  Future<void> insertSampleQuestions() async {
    final count = await db
        .select(db.questions)
        .get()
        .then((value) => value.length);

    if (count == 0) {
      final allQuestions = getAllQuestions();
      for (var q in allQuestions) {
        await db
            .into(db.questions)
            .insert(
              QuestionsCompanion.insert(
                subject: q.subject,
                chapter: q.chapter,
                topic: q.topic,
                topicId: Value(q.topicId),
                questionText: q.questionText,
                options: q.options.join('|||'),
                correctAnswer: q.correctAnswer,
                explanation: Value(q.explanation),
                ncertReference: Value(q.ncertReference),
                year: Value(q.year),
                difficulty: Value(q.difficulty),
                tags: Value(q.tags.join('|||')),
                imageUrl: Value(q.imageUrl),
              ),
            );
      }
      debugPrint("✅ Sample questions inserted successfully!");
    }
  }

  Future<List<model.Question>> getQuestionsBySubject(String subject) async {
    final data = await (db.select(
      db.questions,
    )..where((tbl) => tbl.subject.equals(subject))).get();

    return data
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
            'tags': row.tags,
            'imageUrl': row.imageUrl,
          }),
        )
        .toList();
  }
}

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return QuestionRepository(db);
});
