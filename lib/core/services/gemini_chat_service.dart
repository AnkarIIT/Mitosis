import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'gemini_proxy_service.dart';

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

  /// Tier-2/3 client: shared cache + rate-limited live Gemini via Supabase.
  /// The local Tier-1 tier (questions.explanation in Drift) is resolved by
  /// callers that own a database handle.
  final GeminiProxyService _proxy;

  GeminiChatService({GeminiProxyService? proxy})
    : _proxy = proxy ?? GeminiProxyService();

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
      return;
    }

    final cleanKey = _apiKey!.replaceAll('\n', '').replaceAll('\r', '').trim();

    if (!cleanKey.startsWith('AIzaSy')) {
      _model = null;
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: cleanKey,
      systemInstruction: Content.system(_systemPromptFor(mode)),
    );
  }

  /// Builds the tutor system prompt for a given [mode]. Shared between the
  /// direct Gemini session and the proxy request so cache keys stay stable.
  String _systemPromptFor(ChatMode mode) {
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

    return systemPrompt;
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
    if (_proxy.isConfigured) {
      final result = await _proxy.generate(
        prompt: text,
        systemPrompt: _systemPromptFor(mode),
      );
      switch (result.source) {
        case GeminiProxySource.cache:
        case GeminiProxySource.live:
          return result.text;
        case GeminiProxySource.rateLimited:
          return "You've reached the AI limit for a while. Please try again later.";
        case GeminiProxySource.error:
          return "Sorry, the AI service hit an error. Please try again.";
        case GeminiProxySource.offline:
          return "You're offline. AI Tutor is unavailable — reconnect and try again.";
      }
    }

    // Fall back to the user's own Gemini key when the shared proxy isn't
    // enabled (or is unreachable), so the AI tutor works with just a key.
    return _sendDirect(text, mode: mode);
  }

  /// Sends [text] directly to Gemini using the locally-stored API key.
  Future<String> _sendDirect(String text, {ChatMode mode = ChatMode.general}) {
    final key = _apiKey?.replaceAll('\n', '').replaceAll('\r', '').trim();
    if (key == null || key.isEmpty || !key.startsWith('AIzaSy')) {
      return Future.value(
        'Error: Gemini API Key is not configured. Please add it in Settings.',
      );
    }
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
        systemInstruction: Content.system(_systemPromptFor(mode)),
      );
      return model
          .generateContent([Content.text(text)])
          .then((response) => response.text ?? 'Error: unable to get a response from the AI tutor.');
    } catch (e) {
      debugPrint('❌ Direct Gemini call failed: $e');
      return Future.value('Error: unable to get a response from the AI tutor.');
    }
  }

  /// Direct-Gemini text generation using the stored key and a custom system
  /// prompt. Used by generation features (e.g. flashcards) that need their own
  /// instruction set and want to fall back to the user's key when the shared
  /// proxy isn't enabled.
  Future<String> generateWithSystemPrompt(String text, String systemPrompt) {
    final key = _apiKey?.replaceAll('\n', '').replaceAll('\r', '').trim();
    if (key == null || key.isEmpty || !key.startsWith('AIzaSy')) {
      return Future.value('Error: Gemini API Key is not configured. Please add it in Settings.');
    }
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
        systemInstruction: Content.system(systemPrompt),
      );
      return model
          .generateContent([Content.text(text)])
          .then((response) => response.text ?? 'Error: unable to generate content.');
    } catch (e) {
      return Future.value('Error: unable to generate content.');
    }
  }


  Future<String> sendMultimodalMessage(String text, List<Part> parts) async {
    if (!isConfigured) {
      return "Error: Gemini API Key is not configured. Please add it in Settings.";
    }

    try {
      final key = _apiKey?.replaceAll('\n', '').replaceAll('\r', '').trim();
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key!,
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
    final prompt =
        'I am stuck on this NEET question. Can you give me a small hint? Question: "$questionText" Options: $options. REMEMBER: Do not give the answer.';

    if (_proxy.isConfigured) {
      final result = await _proxy.generate(
        prompt: prompt,
        systemPrompt: _systemPromptFor(ChatMode.quizHint),
      );
      switch (result.source) {
        case GeminiProxySource.cache:
        case GeminiProxySource.live:
          return result.text;
        case GeminiProxySource.rateLimited:
          return "You've reached the AI limit for a while. Please try again later.";
        case GeminiProxySource.offline:
          return "You're offline. AI Tutor is unavailable.";
        case GeminiProxySource.error:
          return "Sorry, the AI service hit an error. Please try again.";
      }
    }

    // Fall back to the user's own Gemini key when the proxy isn't enabled.
    return _sendDirect(prompt, mode: ChatMode.quizHint);
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
      final key = _apiKey?.replaceAll('\n', '').replaceAll('\r', '').trim();
      final planModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key!,
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

  Future<List<Map<String, dynamic>>> generateQuestionsFromText(
    String textChunk,
    String subject,
  ) async {
    if (!isConfigured) return [];

    final prompt =
        '''
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
      final key = _apiKey?.replaceAll('\n', '').replaceAll('\r', '').trim();
      final genModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key!,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
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
      if (item is! Map) continue;
      
      final questionText = item['questionText'];
      final correctAnswer = item['correctAnswer'];
      if (questionText is! String || questionText.trim().isEmpty) continue;
      if (correctAnswer is! String || correctAnswer.trim().isEmpty) continue;

      final options = item['options'];
      final optionList = options is List
          ? options.whereType<String>().toList()
          : <String>[];
      final type = item['type'] is String
          ? (item['type'] as String).toLowerCase()
          : 'mcq';
      final difficulty = item['difficulty'] is String
          ? (item['difficulty'] as String)
          : 'Medium';

      result.add({
        'questionText': questionText.trim(),
        'correctAnswer': correctAnswer.trim(),
        'options': optionList,
        'type': type,
        'difficulty': difficulty,
        'explanation': item['explanation'] is String ? item['explanation'] : '',
        'ncertReference': item['ncertReference'] is String
            ? item['ncertReference']
            : '',
      });
    }

    return result;
  }
}