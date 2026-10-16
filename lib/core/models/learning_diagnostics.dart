enum MistakeType { concept, calculation, speed, silly, unknown }

class MistakeDiagnosis {
  final MistakeType type;
  final String explanation;

  const MistakeDiagnosis({required this.type, required this.explanation});
}

class RetentionCheck {
  final String topicId;
  final DateTime dueAt;
  final int intervalDays;
  final bool isDue;
  final double? accuracy;

  const RetentionCheck({
    required this.topicId,
    required this.dueAt,
    required this.intervalDays,
    required this.isDue,
    this.accuracy,
  });
}
