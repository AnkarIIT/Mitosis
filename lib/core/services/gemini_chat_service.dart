import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChatMode { general, conceptExplanation, doubtSolving, quizHint }

class GeminiChatService {
  static const String _apiKeyPrefsKey = 'gemini_api_key';

  String? _apiKey;
  GenerativeModel? _model;
  ChatSession? _chatSession;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyPrefsKey);
    _initializeModel();
  }

  void _initializeModel({ChatMode mode = ChatMode.general}) {
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      final cleanKey = _apiKey!
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();

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
    } else {
      _model = null;
      _chatSession = null;
    }
  }

  bool get isConfigured => _model != null;

  Future<void> saveApiKey(String key) async {
    final cleanKey = key.replaceAll('\n', '').replaceAll('\r', '').trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefsKey, cleanKey);
    _apiKey = cleanKey;
    _initializeModel();
  }

  String? get apiKey => _apiKey;

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPrefsKey);
    _apiKey = null;
    _initializeModel();
  }

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
      return "Error: $e";
    }
  }

  Future<String> sendMultimodalMessage(String text, List<Part> parts) async {
    if (!isConfigured) {
      if (_apiKey != null && !_apiKey!.trim().startsWith('AIzaSy')) {
        return "Error: The API key you entered doesn't look right. It should start with 'AIzaSy...'. Please check your Settings.";
      }
      return "Error: Gemini API Key is not configured. Please add it in Settings.";
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
        systemInstruction: Content.system(
          'You are a helpful NEET tutor. Answer questions using the image context when available.',
        ),
      );
      final response = await model.generateContent([
        Content.multi([TextPart(text), ...parts]),
      ]);
      return response.text ?? "Sorry, I couldn't generate a response.";
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<String> getQuizHint(String questionText, String options) async {
    if (!isConfigured) return "API Key not configured.";

    final prompt =
        'I am stuck on this NEET question. Can you give me a small hint? Question: "$questionText" Options: $options. REMEMBER: Do not give the answer.';

    try {
      // Use a fresh model instance for a one-off hint to avoid polluting main chat session
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
      return "Error generating plan: $e";
    }
  }
}
