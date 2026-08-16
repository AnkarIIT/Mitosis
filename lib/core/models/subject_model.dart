class Subject {
  final String id;
  final String name;
  final String icon;
  final String? description;
  final List<Chapter> chapters;

  Subject({
    required this.id,
    required this.name,
    required this.icon,
    this.description,
    required this.chapters,
  });
}

class Chapter {
  final String id;
  final String name;
  final String subjectId;
  final String? description;
  final String? classLevel;
  final int weight;
  final List<Topic> topics;

  Chapter({
    required this.id,
    required this.name,
    required this.subjectId,
    this.description,
    this.classLevel,
    this.weight = 1,
    required this.topics,
  });
}

class Topic {
  final String id;
  final String name;
  final String chapterId;
  final String? description;
  final String? summary; // Detailed NCERT summary
  final List<String>? keyPoints; // Bullet points for quick revision
  final int weight;
  final int questionCount;
  final String difficulty;

  Topic({
    required this.id,
    required this.name,
    required this.chapterId,
    this.description,
    this.summary,
    this.keyPoints,
    this.weight = 1,
    required this.questionCount,
    this.difficulty = "Mixed",
  });
}
