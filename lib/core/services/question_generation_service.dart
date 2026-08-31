import 'dart:convert';
import '../models/question_model.dart';
import '../services/gemini_chat_service.dart';

/// Service for generating questions via AI (Gemini) when local pool is insufficient.
/// Integrates with all three engines (Quiz, Exam, DPP).
class QuestionGenerationService {
  final GeminiChatService _gemini;
  final Map<String, List<Question>> _cache = {};

  QuestionGenerationService(this._gemini);

  /// Generates questions for a specific subject/chapter/topic.
  /// Returns a list of Question objects with 'gen_' prefixed IDs.
  Future<List<Question>> generateQuestions({
    required String subject,
    String? chapterId,
    String? topicId,
    required int count,
    Set<String> excludedIds = const {},
  }) async {
    final cacheKey = '$subject:${chapterId ?? ''}:${topicId ?? ''}:$count';
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      final filtered = cached.where((q) => !excludedIds.contains(q.id)).toList();
      if (filtered.length >= count) return filtered.take(count).toList();
    }

    final prompt = _buildPrompt(subject, chapterId, topicId, count);
    final response = await _gemini.sendMessage(prompt);
    final questions = _parseResponse(response, subject, chapterId, topicId, excludedIds);

    // Cache for reuse
    _cache[cacheKey] = questions;
    return questions.take(count).toList();
  }

  String _buildPrompt(String subject, String? chapterId, String? topicId, int count) {
    final buffer = StringBuffer();
    buffer.writeln('You are an expert NEET question setter. Generate $count accurate, NCERT-based MCQ questions.');
    buffer.writeln('Subject: $subject');
    if (chapterId != null) buffer.writeln('Chapter: $chapterId');
    if (topicId != null) buffer.writeln('Topic: $topicId');
    buffer.writeln('');
    buffer.writeln('Requirements:');
    buffer.writeln('- Questions must be NEET-level difficulty and accuracy');
    buffer.writeln('- Based strictly on NCERT curriculum');
    buffer.writeln('- 4 options per question (A, B, C, D)');
    buffer.writeln('- Include detailed explanation referencing NCERT');
    buffer.writeln('- Difficulty distribution: 30% Easy, 50% Medium, 20% Hard');
    buffer.writeln('- Include relevant tags for concept identification');
    buffer.writeln('');
    buffer.writeln('Return ONLY a valid JSON array. No extra text, no markdown.');
    buffer.writeln('Format:');
    buffer.writeln('[');
    buffer.writeln('  {');
    buffer.writeln('    "questionText": "Question text here",');
    buffer.writeln('    "options": ["Option A", "Option B", "Option C", "Option D"],');
    buffer.writeln('    "correctAnswer": "Option A",');
    buffer.writeln('    "explanation": "Detailed explanation referencing NCERT chapter/section",');
    buffer.writeln('    "difficulty": "Easy|Medium|Hard",');
    buffer.writeln('    "tags": ["concept1", "concept2"]');
    buffer.writeln('  }');
    buffer.writeln(']');
    return buffer.toString();
  }

  List<Question> _parseResponse(
    String response,
    String subject,
    String? chapterId,
    String? topicId,
    Set<String> excludedIds,
  ) {
    try {
      // Extract JSON array from response (in case there's extra text)
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']');
      if (jsonStart == -1 || jsonEnd == -1) return [];

      final jsonStr = response.substring(jsonStart, jsonEnd + 1);
      final List<dynamic> data = jsonDecode(jsonStr);

      final questions = <Question>[];
      for (int i = 0; i < data.length; i++) {
        final item = data[i] as Map<String, dynamic>;
        final id = 'gen_${subject.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}_$i';
        
        if (excludedIds.contains(id)) continue;

        final options = (item['options'] as List?)?.cast<String>() ?? [];
        if (options.length != 4) continue;

        final correctAnswer = item['correctAnswer'] as String? ?? '';
        if (!options.contains(correctAnswer)) continue;

        questions.add(Question(
          id: id,
          subject: subject,
          chapter: item['chapter'] as String? ?? chapterId ?? '',
          topic: item['topic'] as String? ?? topicId ?? '',
          topicId: item['topicId'] as String? ?? topicId ?? '',
          questionText: item['questionText'] as String? ?? '',
          options: options,
          correctAnswer: correctAnswer,
          explanation: item['explanation'] as String? ?? '',
          ncertReference: item['ncertReference'] as String?,
          year: DateTime.now().year,
          difficulty: item['difficulty'] as String? ?? 'Medium',
          tags: (item['tags'] as List?)?.cast<String>() ?? [],
          imageUrl: null,
          type: 'MCQ',
        ));
      }
      return questions;
    } catch (e) {
      return [];
    }
  }

  void clearCache() => _cache.clear();
}