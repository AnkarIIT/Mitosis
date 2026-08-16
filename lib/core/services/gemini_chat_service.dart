import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

enum ChatMode { general, conceptExplanation, doubtSolving, quizHint }

/// Manages the Gemini AI session and stores the API key in the OS secure
/// keystore (Android Keystore / iOS Keychain) via [FlutterSecureStorage].
class GeminiChatService {
  // Key used inside the secure storage namespace.
  static const String _apiKeyStorageKey = 'gemini_api_key';

  static const _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String? _apiKey;
  GenerativeModel? _model;
  ChatSession? _chatSession;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    _apiKey = await _secureStorage.read(key: _apiKeyStorageKey);
    _initializeModel();
  }

  void _initializeModel({ChatMode mode = ChatMode.general}) {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _model = null;
      _chatSession = null;
      return;
    }

    final cleanKey = _apiKey!.replaceAll('\n', '').replaceAll('\r', '').trim();

    if (!cleanKey.startsWith('AIzaSy')) {
      _model = null;
      _chatSession = null;
      return;
    }

    String systemPrompt =
        'You are an expert NEET (medical entrance exam) tutor. You explain concepts strictly based on the NCERT syllabus. You are patient, concise, and helpful.';

    switch (mode) {
      case ChatMode.conceptExplanation:
        systemPrompt +=
            ' Focus on explaining complex biological, chemical, or physical concepts in simple, step-by-step terms with examples.';
        break;
      case ChatMode.doubtSolving:
        systemPrompt +=
            ' Focus on solving specific student doubts. If they provide a question, walk them through the logic without just giving the answer immediately.';
        break;
      case ChatMode.quizHint:
        systemPrompt +=
            ' Your goal is to provide a subtle hint to help the student solve a quiz question themselves. NEVER give the full answer. Point them to the right concept or formula.';
        break;
      default:
        break;
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: cleanKey,
      systemInstruction: Content.system(systemPrompt),
    );
    _chatSession = _model!.startChat();
  }

  // ---------------------------------------------------------------------------
  // Key management
  // ---------------------------------------------------------------------------

  bool get isConfigured => _model != null;

  String? get apiKey => _apiKey;

  Future<void> saveApiKey(String key) async {
    final cleanKey = key.replaceAll('\n', '').replaceAll('\r', '').trim();
    await _secureStorage.write(key: _apiKeyStorageKey, value: cleanKey);
    _apiKey = cleanKey;
    _initializeModel();
  }

  Future<void> clearApiKey() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
    _apiKey = null;
    _initializeModel();
  }

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  Future<String> sendMessage(
    String text, {
    ChatMode mode = ChatMode.general,
  }) async {
    if (!isConfigured) {
      if (_apiKey != null && !_apiKey!.trim().startsWith('AIzaSy')) {
        return "Error: The API key you entered doesn't look right. It should start with 'AIzaSy...'. Please check your Settings.";
      }
      return "Error: Gemini API Key is not configured. Please add it in Settings.";
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(text));
      return response.text ?? "Sorry, I couldn't generate a response.";
    } catch (e) {
      return "Error: Something went wrong. Please try again.";
    }
  }

  Future<String> sendMultimodalMessage(String text, List<Part> parts) async {
    if (!isConfigured) {
      return "Error: Gemini API Key is not configured. Please add it in Settings.";
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
        systemInstruction: Content.system(
          'You are an expert NEET tutor and OCR specialist. Identify the medical entrance exam (NEET) question from the provided image. '
          'Provide a clear, step-by-step solution. State the final correct answer clearly (e.g., Option B). '
          'Crucially, provide the exact NCERT textbook reference (Class 11/12, Chapter Name, and Page/Topic) where this concept is explained. '
          'If the image is not a question or is too blurry, politely ask for a clearer photo of a single question.',
        ),
      );
      final response = await model.generateContent([
        Content.multi([TextPart(text), ...parts]),
      ]);
      return response.text ?? "Sorry, I couldn't process the image.";
    } catch (e) {
      return "Error: Unable to analyze image. Please try a clearer photo.";
    }
  }

  Future<String> getQuizHint(String questionText, String options) async {
    if (!isConfigured) return "API Key not configured.";

    final prompt =
        'I am stuck on this NEET question. Can you give me a small hint? Question: "$questionText" Options: $options. REMEMBER: Do not give the answer.';

    try {
      final hintModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
        systemInstruction: Content.system(
          'You are a helpful NEET tutor. Provide a very short, helpful hint for the question. NEVER give the answer or the correct option letter.',
        ),
      );
      final response = await hintModel.generateContent([Content.text(prompt)]);
      return response.text ?? "Try thinking about the core concept involved.";
    } catch (e) {
      return "Think about the NCERT definition for this topic.";
    }
  }

  Future<String> generateStudyPlan(
    List<String> weakTopics,
    int daysAvailable,
  ) async {
    if (!isConfigured) return "API Key not configured.";

    final topicsList = weakTopics.join(", ");
    final prompt =
        '''Create a personalized NEET study plan for the next $daysAvailable days.
Focus on these weak topics: $topicsList.

Format the response as a day-by-day breakdown like this:
Day 1: Topic Name - Key Concepts
Day 2: Topic Name - Practice Questions
...

Make it practical and achievable for a NEET student.''';

    try {
      final planModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
        systemInstruction: Content.system(
          'You are a NEET expert study planner. Create practical, achievable study plans.',
        ),
      );
      final response = await planModel.generateContent([Content.text(prompt)]);
      return response.text ?? "Unable to generate plan.";
    } catch (e) {
      return "Error generating plan. Please try again.";
    }
  }

  Future<List<Map<String, dynamic>>> generateQuestionsFromText(String textChunk, String subject) async {
    if (!isConfigured) return [];

    final prompt = '''
    Generate 5 high-yield NEET entrance exam questions based on the following text from an NCERT textbook.
    Text: "$textChunk"
    
    Return the response as a JSON array of objects with this EXACT structure:
    [
      {
        "questionText": "...",
        "correctAnswer": "...",
        "options": ["A", "B", "C", "D"],
        "type": "mcq", // can be "mcq" or "shortAnswer"
        "difficulty": "easy", // easy, medium, or hard
        "explanation": "...",
        "ncertReference": "Class X, Chapter Y, Page Z"
      }
    ]
    ''';

    try {
      final genModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
        systemInstruction: Content.system(
          'You are an expert NEET question setter. Generate accurate, NCERT-based questions. '
          'For mcq, provide 4 distinct options. For shortAnswer, provide a model answer.',
        ),
      );
      
      final response = await genModel.generateContent([Content.text(prompt)]);
      final jsonStr = response.text;
      if (jsonStr == null) return [];

      return _parseGeneratedQuestions(jsonStr);
    } catch (e) {
      debugPrint('❌ Error generating questions: $e');
      return [];
    }
  }

  /// Parses Gemini's response into a validated list of question maps.
  /// Gemini sometimes wraps the JSON in markdown fences or prepends prose, so
  /// we defensively extract the first JSON array and drop malformed entries.
  List<Map<String, dynamic>> _parseGeneratedQuestions(String raw) {
    var text = raw.trim();

    // 1. Strip a ```json ... ``` fence if present.
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final fenceMatch = fence.firstMatch(text);
    if (fenceMatch != null) {
      text = fenceMatch.group(1)!.trim();
    }

    // 2. Extract the first '[' ... ']' block.
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) return [];
    final slice = text.substring(start, end + 1);

    Object? decoded;
    try {
      decoded = jsonDecode(slice);
    } catch (e) {
      debugPrint('❌ Invalid JSON from Gemini: $e');
      return [];
    }

    if (decoded is! List) return [];

    final result = <Map<String, dynamic>>[];
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        final cleaned = _sanitizeGeneratedQuestion(item);
        if (cleaned != null) result.add(cleaned);
      }
    }
    return result;
  }

  /// Validates and normalizes a single generated question, returning null if
  /// it is unusable (missing text or answer).
  Map<String, dynamic>? _sanitizeGeneratedQuestion(Map<String, dynamic> raw) {
    final questionText = raw['questionText'];
    final correctAnswer = raw['correctAnswer'];
    if (questionText is! String || questionText.trim().isEmpty) return null;
    if (correctAnswer is! String || correctAnswer.trim().isEmpty) return null;

    final options = raw['options'];
    final optionList = options is List
        ? options.whereType<String>().toList()
        : <String>[];
    final type = raw['type'] is String ? (raw['type'] as String).toLowerCase() : 'mcq';
    final difficulty = raw['difficulty'] is String
        ? (raw['difficulty'] as String)
        : 'Medium';

    return {
      'questionText': questionText.trim(),
      'correctAnswer': correctAnswer.trim(),
      'options': optionList,
      'type': type,
      'difficulty': difficulty,
      'explanation': raw['explanation'] is String ? raw['explanation'] : '',
      'ncertReference':
          raw['ncertReference'] is String ? raw['ncertReference'] : '',
    };
  }
}
