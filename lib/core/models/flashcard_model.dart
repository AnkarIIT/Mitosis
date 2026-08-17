class Flashcard {
  final String id;
  final String front;
  final String back;
  final String subject;
  final String topicId;
  final String? imageUrl;

  // NotebookLM-style fields
  final String chapterId;
  final String ncertReference;
  final int sourcePage;
  final String difficulty;
  final bool isGenerated;

  // SM-2 / Leitner scheduling fields
  final int box;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final int lapses;
  final DateTime dueAt;
  final DateTime? lastReviewedAt;

  const Flashcard({
    required this.id,
    required this.front,
    required this.back,
    required this.subject,
    required this.topicId,
    this.imageUrl,
    this.chapterId = '',
    this.ncertReference = '',
    this.sourcePage = 0,
    this.difficulty = 'Medium',
    this.isGenerated = false,
    this.box = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.lapses = 0,
    required this.dueAt,
    this.lastReviewedAt,
  });

  Flashcard copyWith({
    String? id,
    String? front,
    String? back,
    String? subject,
    String? topicId,
    String? imageUrl,
    String? chapterId,
    String? ncertReference,
    int? sourcePage,
    String? difficulty,
    bool? isGenerated,
    int? box,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    int? lapses,
    DateTime? dueAt,
    DateTime? lastReviewedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      subject: subject ?? this.subject,
      topicId: topicId ?? this.topicId,
      imageUrl: imageUrl ?? this.imageUrl,
      chapterId: chapterId ?? this.chapterId,
      ncertReference: ncertReference ?? this.ncertReference,
      sourcePage: sourcePage ?? this.sourcePage,
      difficulty: difficulty ?? this.difficulty,
      isGenerated: isGenerated ?? this.isGenerated,
      box: box ?? this.box,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }
}
