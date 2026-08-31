import 'dart:convert';

class Evaluation {
  final String questionId;
  final String studentAnswer;
  final double score;
  final double semanticSimilarity;
  final double keywordMatch;
  final bool isCorrect;
  final String feedback;
  final List<String> missingKeywords;
  final DateTime evaluatedAt;

  Evaluation({
    required this.questionId,
    required this.studentAnswer,
    required this.score,
    required this.semanticSimilarity,
    required this.keywordMatch,
    required this.isCorrect,
    required this.feedback,
    required this.missingKeywords,
    required this.evaluatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'question_id': questionId,
      'student_answer': studentAnswer,
      'score': score,
      'semantic_similarity': semanticSimilarity,
      'keyword_match': keywordMatch,
      'is_correct': isCorrect ? 1 : 0,
      'feedback': feedback,
      'missing_keywords': jsonEncode(missingKeywords),
      'evaluated_at': evaluatedAt.toIso8601String(),
    };
  }

  factory Evaluation.fromMap(Map<String, dynamic> map) {
    return Evaluation(
      questionId: map['question_id'] ?? '',
      studentAnswer: map['student_answer'] ?? '',
      score: (map['score'] as num).toDouble(),
      semanticSimilarity: (map['semantic_similarity'] as num).toDouble(),
      keywordMatch: (map['keyword_match'] as num).toDouble(),
      isCorrect: map['is_correct'] == 1,
      feedback: map['feedback'] ?? '',
      missingKeywords: List<String>.from(
        jsonDecode(map['missing_keywords'] ?? '[]'),
      ),
      evaluatedAt: DateTime.parse(
        map['evaluated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
