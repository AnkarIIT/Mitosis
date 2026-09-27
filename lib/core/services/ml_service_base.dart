import 'dart:math';

/// Platform-agnostic base for the ML service.
///
/// Holds the shared scoring logic (keyword + string-overlap fallbacks) and
/// delegates the heavy semantic embedding to a platform implementation via
/// the hooks below. Concrete implementations live in `ml_service_io.dart` and
/// `ml_service_web.dart`; the actual class is chosen by a conditional import
/// in `ml_service.dart`.
abstract class MLService {
  /// Loads any heavy ML artifacts. Implementation-dependent; may be a no-op.
  Future<void> initializeModels() async {}

  /// Returns a 0..1 semantic similarity between two texts.
  Future<double> calculateSemanticSimilarity(String text1, String text2) async {
    // Default: string-overlap fallback when no model is available.
    return fallbackSimilarity(text1, text2);
  }

  Future<double> evaluateShortAnswer(
    String studentAnswer,
    String correctAnswer,
  ) async {
    // 1. Keyword match (40%)
    final kwScore = _calculateKeywordMatch(studentAnswer, correctAnswer);

    // 2. Semantic Similarity (60%)
    final semanticScore = await calculateSemanticSimilarity(
      studentAnswer,
      correctAnswer,
    );

    final finalScore = (kwScore * 0.4) + (semanticScore * 0.6);
    return finalScore;
  }

  double fallbackSimilarity(String s1, String s2) {
    final set1 = s1.toLowerCase().split(' ').toSet();
    final set2 = s2.toLowerCase().split(' ').toSet();
    final intersection = set1.intersection(set2);
    final union = set1.union(set2);
    return intersection.length / union.length;
  }

  double _calculateKeywordMatch(String student, String correct) {
    final studentWords = student.toLowerCase().split(RegExp(r'\s+')).toSet();
    final correctWords = correct.toLowerCase().split(RegExp(r'\s+')).toSet();

    final stopWords = {
      'the',
      'is',
      'at',
      'which',
      'on',
      'and',
      'a',
      'an',
      'to',
      'of',
      'in',
    };
    final importantCorrectWords = correctWords
        .difference(stopWords)
        .where((w) => w.length > 2)
        .toSet();

    if (importantCorrectWords.isEmpty) return 1.0;

    final intersection = studentWords.intersection(importantCorrectWords);
    return (intersection.length / importantCorrectWords.length);
  }

  List<double> tokenize(String text) {
    List<double> tokens = List.filled(512, 0.0);
    for (int i = 0; i < text.length && i < 512; i++) {
      tokens[i] = text.codeUnitAt(i).toDouble();
    }
    return tokens;
  }

  double cosineSimilarity(List<dynamic> v1, List<dynamic> v2) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      normA += pow(v1[i], 2);
      normB += pow(v2[i], 2);
    }
    double result = dotProduct / (sqrt(normA) * sqrt(normB));
    return result.isNaN ? 0.0 : result;
  }
}
