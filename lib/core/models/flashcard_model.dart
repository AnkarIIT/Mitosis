class Flashcard {
  final String id;
  final String front;
  final String back;
  final String subject;
  final String topicId;
  final String? imageUrl;

  const Flashcard({
    required this.id,
    required this.front,
    required this.back,
    required this.subject,
    required this.topicId,
    this.imageUrl,
  });
}
