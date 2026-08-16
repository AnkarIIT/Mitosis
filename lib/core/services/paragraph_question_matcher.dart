import '../models/question_model.dart';

/// Phase-1 heuristic matcher that links an NCERT paragraph to the questions
/// derived from it, based on significant token overlap between the paragraph
/// text and a question's topic/chapter/question text.
class ParagraphQuestionMatcher {
  static const Set<String> _stopwords = {
    'that', 'this', 'these', 'those', 'there', 'their', 'which',
    'where', 'while', 'through', 'between', 'within', 'without',
    'because', 'before', 'after', 'about', 'above', 'below', 'under',
    'over', 'again', 'further', 'then', 'once', 'here', 'when',
    'each', 'other', 'more', 'most', 'some', 'such', 'both', 'also',
    'very', 'just', 'only', 'from', 'into', 'with', 'them', 'than',
    'have', 'been', 'being', 'were', 'will', 'would', 'could',
    'should', 'shall', 'does', 'doing', 'made', 'make', 'same',
  };

  /// Splits a text into significant tokens (length >= 4, stopwords removed,
  /// numbers ignored).
  static List<String> tokens(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized
        .split(' ')
        .where((t) =>
            t.length >= 4 &&
            !_stopwords.contains(t) &&
            !RegExp(r'^\d+$').hasMatch(t))
        .toSet()
        .toList();
  }

  /// Counts significant tokens shared between the paragraph and the question
  /// (topic + chapter + question text).
  static int score(String paragraphText, Question question) {
    final paragraphTokens = tokens(paragraphText).toSet();
    final questionTokens = tokens(
      '${question.topic} ${question.chapter} ${question.questionText}',
    ).toSet();
    return paragraphTokens.intersection(questionTokens).length;
  }

  /// Returns chapter questions that match the paragraph, ranked by overlap
  /// score (highest first). Empty when nothing meets the threshold.
  static List<Question> matchingQuestions(
    String paragraphText,
    List<Question> questions, {
    int minScore = 2,
  }) {
    final scored = <(int, Question)>[];
    for (final q in questions) {
      final s = score(paragraphText, q);
      if (s >= minScore) scored.add((s, q));
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return scored.map((e) => e.$2).toList();
  }
}
