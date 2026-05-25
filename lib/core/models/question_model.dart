class Question {
  final int id;
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
    this.difficulty = "Medium",
    this.tags = const [],
    this.imageUrl,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int,
      subject: map['subject'] as String,
      chapter: map['chapter'] as String,
      topic: map['topic'] as String,
      topicId: map['topicId'] as String? ?? '',
      questionText: map['questionText'] as String,
      options: (map['options'] as String).split('|||'),
      correctAnswer: map['correctAnswer'] as String,
      explanation: map['explanation'] as String?,
      ncertReference: map['ncertReference'] as String?,
      year: map['year'] as int?,
      difficulty: map['difficulty'] as String,
      tags: (map['tags'] as String?)?.split('|||') ?? [],
      imageUrl: map['imageUrl'] as String?,
    );
  }
}
