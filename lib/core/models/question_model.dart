import 'dart:convert';

class Question {
  final String id;
  final String subject;
  final String chapter;
  final String topic;
  final String topicId;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final String? ncertReference;
  final int? year;
  final String difficulty;
  final List<String> tags;
  final String? imageUrl;
  final String type;
  final DateTime createdAt;

  Question({
    required this.id,
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.topicId,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.ncertReference,
    this.year,
    required this.difficulty,
    required this.tags,
    this.imageUrl,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'chapter': chapter,
      'topic': topic,
      'topicId': topicId,
      'questionText': questionText,
      'options': jsonEncode(options),
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'ncertReference': ncertReference,
      'year': year,
      'difficulty': difficulty,
      'tags': jsonEncode(tags),
      'imageUrl': imageUrl,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id']?.toString() ?? '',
      subject: map['subject'] ?? '',
      chapter: map['chapter'] ?? '',
      topic: map['topic'] ?? '',
      topicId: map['topicId'] ?? '',
      questionText: map['questionText'] ?? '',
      options: map['options'] is String
          ? Question._decodeList(map['options'])
          : List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
      explanation: map['explanation'],
      ncertReference: map['ncertReference'],
      year: map['year'],
      difficulty: map['difficulty'] ?? 'Medium',
      tags: map['tags'] is String
          ? Question._decodeList(map['tags'])
          : List<String>.from(map['tags'] ?? []),
      imageUrl: map['imageUrl'],
      type: map['type'] ?? 'mcq',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  static List<String> _decodeList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } on FormatException {
      // Fall through to the deprecated '|||' separator format.
    }
    return raw.split('|||').where((e) => e.isNotEmpty).toList();
  }
}
