import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../database/question_repository.dart';
import '../models/question_model.dart';

/// Service to download NEET Previous Year Questions (PYQ) from public sources.
///
/// Sources:
/// - GitHub raw JSON repos hosting curated NEET PYQ sets
/// - Any configured API endpoint returning Question-shaped JSON
///
/// Each downloaded question is marked with source = 'pyq' and the year
/// field is populated from the source data.
class PyqDownloaderService {
  final QuestionRepository _repository;
  final http.Client _client;

  PyqDownloaderService(this._repository, {http.Client? client}) : _client = client ?? http.Client();

  /// Known public sources for NEET PYQs (JSON arrays of question objects).
  /// Each entry: (url, description).
  static const _defaultSources = <(String, String)>[
    // Placeholder: replace with actual curated NEET PYQ JSON endpoints.
    // Example: ('https://raw.githubusercontent.com/.../neet2023.json', 'NEET 2023'),
  ];

  List<(String, String)> get sources {
    final env = _env('PYQ_SOURCES');
    if (env != null && env.isNotEmpty) {
      try {
        final decoded = jsonDecode(env) as List;
        return decoded.map((e) {
          final m = e as Map<String, dynamic>;
          return (m['url'] as String, m['label'] as String);
        }).toList();
      } on FormatException {
        // fall through to defaults
      }
    }
    return _defaultSources;
  }

  String? _env(String key) {
    try {
      return dotenv.env[key];
    } on Object {
      return null;
    }
  }

  /// Downloads PYQs from all configured sources and inserts them into the DB.
  /// Returns the number of new questions inserted.
  Future<int> downloadAll({bool forceRefresh = false}) async {
    int inserted = 0;
    for (final (url, label) in sources) {
      try {
        inserted += await _downloadSource(url, label, forceRefresh: forceRefresh);
      } catch (e) {
        // log and continue with next source
      }
    }
    return inserted;
  }

  Future<int> _downloadSource(String url, String label, {bool forceRefresh = false}) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to load $label: HTTP ${response.statusCode}');
    }

    final List<dynamic> raw;
    try {
      raw = jsonDecode(response.body) as List<dynamic>;
    } on FormatException {
      throw Exception('Invalid JSON for $label');
    }

    final questions = <Question>[];
    for (final item in raw) {
      final q = _parseQuestion(item as Map<String, dynamic>, label);
      if (q != null) questions.add(q);
    }

    if (questions.isEmpty) return 0;

    // Avoid duplicates: skip if question text already exists.
    final existingTexts = await _repository.getExistingQuestionTexts();
    final toInsert = questions.where((q) => !existingTexts.contains(q.questionText)).toList();

    if (toInsert.isEmpty) return 0;

    await _repository.bulkInsertQuestions(toInsert);
    return toInsert.length;
  }

  Question? _parseQuestion(Map<String, dynamic> json, String sourceLabel) {
    final text = (json['questionText'] ?? json['question'] ?? '').toString().trim();
    if (text.isEmpty) return null;

    final options = _decodeStringList(json['options']);
    final correctAnswer = (json['correctAnswer'] ?? json['answer'] ?? '').toString().trim();
    if (options.length < 2 || correctAnswer.isEmpty) return null;

    final subject = (json['subject'] ?? '').toString().trim();
    final chapter = (json['chapter'] ?? '').toString().trim();
    final topic = (json['topic'] ?? chapter).toString().trim();
    final topicId = (json['topicId'] ?? json['topic_id'] ?? '').toString().trim();
    final year = int.tryParse((json['year'] ?? json['examYear'] ?? '').toString());
    final difficulty = (json['difficulty'] ?? 'Medium').toString().trim();
    final explanation = json['explanation']?.toString().trim();
    final ncertRef = json['ncertReference']?.toString().trim();
    final tags = _decodeStringList(json['tags']);
    final imageUrl = json['imageUrl']?.toString().trim();

    final id = _makeId(json, sourceLabel);

    return Question(
      id: id,
      subject: subject,
      chapter: chapter,
      topic: topic,
      topicId: topicId,
      questionText: text,
      options: options,
      correctAnswer: correctAnswer,
      explanation: explanation,
      ncertReference: ncertRef,
      year: year,
      difficulty: difficulty,
      tags: tags,
      imageUrl: imageUrl,
      type: (json['type'] ?? 'MCQ').toString().trim(),
      createdAt: DateTime.now(),
    );
  }

  String _makeId(Map<String, dynamic> json, String sourceLabel) {
    final rawId = json['id']?.toString().trim() ?? '';
    if (rawId.isNotEmpty) return 'pyq_${sourceLabel}_$rawId';
    final text = (json['questionText'] ?? json['question'] ?? '').toString();
    final hash = text.hashCode;
    return 'pyq_${sourceLabel}_$hash';
  }

  static List<String> _decodeStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return [];
      if (trimmed.startsWith('[')) {
        try {
          final decoded = jsonDecode(trimmed) as List;
          return decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        } on FormatException {
          // fall through
        }
      }
      return trimmed.split('|||').where((e) => e.trim().isNotEmpty).map((e) => e.trim()).toList();
    }
    return [];
  }
}
