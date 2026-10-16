import '../models/learning_diagnostics.dart';
import '../models/question_model.dart';

class MistakeClassifier {
  const MistakeClassifier();

  MistakeDiagnosis classify({
    required Question question,
    required String? selectedAnswer,
    required double timeSeconds,
  }) {
    if (selectedAnswer == null || selectedAnswer.trim().isEmpty) {
      return const MistakeDiagnosis(
        type: MistakeType.speed,
        explanation: 'The question was left unanswered.',
      );
    }
    final tags = question.tags.map((tag) => tag.toLowerCase()).toList();
    final text = '${question.questionText} ${question.explanation}'
        .toLowerCase();
    if (timeSeconds > 90) {
      return const MistakeDiagnosis(
        type: MistakeType.speed,
        explanation: 'The answer took longer than the practice time target.',
      );
    }
    if (tags.any((tag) => tag.contains('calculation')) ||
        text.contains('calculate') ||
        text.contains('numerical')) {
      return const MistakeDiagnosis(
        type: MistakeType.calculation,
        explanation: 'This question requires a calculation or numerical setup.',
      );
    }
    if (tags.any((tag) => tag.contains('concept')) ||
        tags.any((tag) => tag.contains('ncert'))) {
      return const MistakeDiagnosis(
        type: MistakeType.concept,
        explanation: 'The error is linked to a concept or NCERT fact.',
      );
    }
    if (timeSeconds < 8) {
      return const MistakeDiagnosis(
        type: MistakeType.silly,
        explanation: 'The quick response suggests a reading or marking error.',
      );
    }
    return const MistakeDiagnosis(
      type: MistakeType.unknown,
      explanation: 'More attempts are needed to identify the error pattern.',
    );
  }
}
