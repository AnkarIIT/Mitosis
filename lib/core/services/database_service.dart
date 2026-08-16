import '../models/question_model.dart' as model;
import '../models/evaluation_model.dart' as eval_model;
import '../database/drift_database.dart';
import 'question_importer.dart';
import 'package:drift/drift.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  late final AppDatabase _db;

  DatabaseService._init() {
    _db = AppDatabase();
  }

  Future<void> initialize() async {
    // Initialization handled by AppDatabase singleton or lazy loading
  }

  Future<void> insertQuestion(model.Question question) async {
    await _db.into(_db.questions).insert(
      QuestionsCompanion(
        id: Value<String>(question.id.toString()),
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

  /// Returns the canonicalized text of every question already stored, so
  /// imports can skip exact duplicates.
  Future<Set<String>> getExistingQuestionTexts() async {
    final results = await _db.select(_db.questions).get();
    return results
        .map((r) => QuestionImporter.normalizeText(r.questionText))
        .toSet();
  }

  /// Inserts many questions in a single transaction and returns how many were
  /// written. Duplicate ids are overwritten (insertOrReplace).
  Future<int> bulkInsertQuestions(List<model.Question> questions) async {
    if (questions.isEmpty) return 0;
    await _db.transaction(() async {
      for (var q in questions) {
        await _db.into(_db.questions).insert(
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
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    return questions.length;
  }

  Future<List<model.Question>> getQuestions(String subject) async {
    final results = await (_db.select(_db.questions)..where((t) => t.subject.equals(subject))).get();
    return results.map((row) => model.Question.fromMap({
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
      'createdAt': DateTime.now().toIso8601String(), // Fallback
    })).toList();
  }

  Future<void> insertEvaluation(eval_model.Evaluation eval) async {
    await _db.into(_db.evaluations).insert(
      EvaluationsCompanion.insert(
        questionId: eval.questionId,
        studentAnswer: eval.studentAnswer,
        score: eval.score,
        semanticSimilarity: eval.semanticSimilarity,
        keywordMatch: eval.keywordMatch,
        isCorrect: eval.isCorrect,
        feedback: Value(eval.feedback),
        missingKeywords: Value(eval.missingKeywords.join(',')),
        evaluatedAt: eval.evaluatedAt,
      ),
    );
  }

  Future<Map<String, dynamic>> getOverallStats() async {
    final evals = await _db.select(_db.evaluations).get();
    if (evals.isEmpty) return {'total': 0, 'correct': 0, 'avg_score': 0.0};
    
    int correct = evals.where((e) => e.isCorrect).length;
    double avgScore = evals.fold(0.0, (sum, e) => sum + e.score) / evals.length;
    
    return {
      'total': evals.length,
      'correct': correct,
      'avg_score': avgScore,
    };
  }
}
