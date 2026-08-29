import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/question_model.dart';
import '../models/user_progress_model.dart';

class ResultExportService {
  static Future<String?> exportQuizAttemptToCsv(
    QuizAttempt attempt,
    List<Question> questions,
    Map<int, String?> answersByIndex,
  ) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Question,Subject,Chapter,Topic,Difficulty,Your Answer,Correct Answer,Result,Time (s)');

      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final answer = answersByIndex[i];
        final isCorrect = answer == q.correctAnswer;
        final result = isCorrect ? 'Correct' : (answer == null || answer.isEmpty ? 'Skipped' : 'Incorrect');
        buffer.writeln([
          i + 1,
          q.subject,
          '"${q.chapter.replaceAll('"', '""')}"',
          '"${q.topic.replaceAll('"', '""')}"',
          q.difficulty,
          answer ?? 'Skipped',
          q.correctAnswer,
          result,
          'N/A',
        ].join(','));
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileName = '${attempt.testType}_${attempt.subject}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> exportDppResultToCsv(
    List<Question> questions,
    Map<int, String?> answersByIndex,
    String subject,
  ) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Question,Subject,Chapter,Topic,Difficulty,Your Answer,Correct Answer,Result');

      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final answer = answersByIndex[i];
        final isCorrect = answer == q.correctAnswer;
        final result = isCorrect ? 'Correct' : (answer == null || answer.isEmpty ? 'Skipped' : 'Incorrect');
        buffer.writeln([
          i + 1,
          q.subject,
          '"${q.chapter.replaceAll('"', '""')}"',
          '"${q.topic.replaceAll('"', '""')}"',
          q.difficulty,
          answer ?? 'Skipped',
          q.correctAnswer,
          result,
        ].join(','));
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'dpp_${subject}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      return null;
    }
  }
}
