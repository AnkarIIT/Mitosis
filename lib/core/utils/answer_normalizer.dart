import '../models/question_model.dart';

/// Resolves imported answers into the option index used by all engines.
///
/// Accepted inputs are option text, A/B/C/D-style labels, and numeric indexes.
/// Numeric values are treated as zero-based when they fit the option range;
/// one-based values are accepted when they otherwise identify an option.
class AnswerNormalizer {
  const AnswerNormalizer._();

  static int? optionIndex(String? answer, Question question) {
    if (answer == null) return null;
    final value = answer.trim();
    if (value.isEmpty) return null;

    final textIndex = question.options.indexWhere(
      (option) => option.trim().toLowerCase() == value.toLowerCase(),
    );
    if (textIndex >= 0) return textIndex;

    final upper = value.toUpperCase();
    if (upper.length == 1) {
      final code = upper.codeUnitAt(0) - 'A'.codeUnitAt(0);
      if (code >= 0 && code < question.options.length) return code;
    }

    final numeric = int.tryParse(value);
    if (numeric == null) return null;
    if (numeric >= 0 && numeric < question.options.length) return numeric;
    if (numeric > 0 && numeric <= question.options.length) {
      return numeric - 1;
    }
    return null;
  }

  static bool isCorrect(String? answer, Question question) {
    final selected = optionIndex(answer, question);
    final correct = optionIndex(question.correctAnswer, question);
    return selected != null && correct != null && selected == correct;
  }
}
