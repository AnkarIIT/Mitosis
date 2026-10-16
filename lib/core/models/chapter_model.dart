/// Chapter and lesson data models for structured learning.
///
/// A chapter contains multiple lessons in sequence. Each lesson has
/// original prose, worked examples, misconceptions, and NCERT references.
library chapter_model;

/// A single lesson within a chapter.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.order,
    required this.content, // Original prose (Markdown)
    required this.workedExample,
    required this.misconception,
    required this.ncertSection, // e.g., "Section 2.3"
    required this.ncertPage, // PDF page number
    required this.estimatedMinutes,
    required this.quickChecks, // 1-2 MCQs after lesson
  });

  final String id;
  final String title;
  final int order;
  final String content;
  final String workedExample;
  final String misconception;
  final String ncertSection;
  final int ncertPage;
  final int estimatedMinutes;
  final List<QuickCheck> quickChecks;

  Lesson copyWith({
    String? id,
    String? title,
    int? order,
    String? content,
    String? workedExample,
    String? misconception,
    String? ncertSection,
    int? ncertPage,
    int? estimatedMinutes,
    List<QuickCheck>? quickChecks,
  }) => Lesson(
    id: id ?? this.id,
    title: title ?? this.title,
    order: order ?? this.order,
    content: content ?? this.content,
    workedExample: workedExample ?? this.workedExample,
    misconception: misconception ?? this.misconception,
    ncertSection: ncertSection ?? this.ncertSection,
    ncertPage: ncertPage ?? this.ncertPage,
    estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    quickChecks: quickChecks ?? this.quickChecks,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'order': order,
    'content': content,
    'workedExample': workedExample,
    'misconception': misconception,
    'ncertSection': ncertSection,
    'ncertPage': ncertPage,
    'estimatedMinutes': estimatedMinutes,
    'quickChecks': quickChecks.map((q) => q.toMap()).toList(),
  };

  factory Lesson.fromMap(Map<String, dynamic> map) => Lesson(
    id: map['id']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    order: map['order'] as int? ?? 0,
    content: map['content']?.toString() ?? '',
    workedExample: map['workedExample']?.toString() ?? '',
    misconception: map['misconception']?.toString() ?? '',
    ncertSection: map['ncertSection']?.toString() ?? '',
    ncertPage: map['ncertPage'] as int? ?? 0,
    estimatedMinutes: map['estimatedMinutes'] as int? ?? 0,
    quickChecks:
        (map['quickChecks'] as List?)
            ?.map((e) => QuickCheck.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

/// A single quick check question after a lesson.
class QuickCheck {
  const QuickCheck({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  final String id;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  Map<String, dynamic> toMap() => {
    'id': id,
    'questionText': questionText,
    'options': options,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
  };

  factory QuickCheck.fromMap(Map<String, dynamic> map) => QuickCheck(
    id: map['id']?.toString() ?? '',
    questionText: map['questionText']?.toString() ?? '',
    options: List<String>.from(map['options'] ?? []),
    correctAnswer: map['correctAnswer']?.toString() ?? '',
    explanation: map['explanation']?.toString() ?? '',
  );
}

/// A full chapter containing ordered lessons.
class Chapter {
  const Chapter({
    required this.id,
    required this.subject,
    required this.classLevel,
    required this.chapterNumber,
    required this.title,
    required this.learningOutcomes,
    required this.estimatedMinutes,
    required this.lessons,
    required this.pdfEntryId, // For PDF deep-linking
    required this.summaryQuiz, // End-of-chapter quiz (5-10 MCQs)
  });

  final String id;
  final String subject; // Physics, Chemistry, Botany, Zoology
  final String classLevel; // Class 11, Class 12
  final int chapterNumber;
  final String title;
  final List<String> learningOutcomes;
  final int estimatedMinutes;
  final List<Lesson> lessons;
  final String pdfEntryId; // For PDF deep-linking
  final List<QuickCheck> summaryQuiz; // End-of-chapter quiz

  int get totalEstimatedMinutes =>
      estimatedMinutes + lessons.fold(0, (sum, l) => sum + l.estimatedMinutes);

  /// The lesson a student should start on.
  ///
  /// `firstLesson` used to be a hardcoded `lessons.first` with no callers, so
  /// it ignored any recorded progress and would have re-served lesson 1 to a
  /// student who had already finished it. Progress lives on [ChapterProgress],
  /// not on the chapter, so it is passed in.
  Lesson? firstLessonToResume([ChapterProgress? progress]) {
    if (lessons.isEmpty) return null;
    if (progress != null) {
      final resume = lessons
          .where((l) => l.id == progress.currentLessonId)
          .firstOrNull;
      if (resume != null) return resume;
      final next = lessons
          .where((l) => !progress.completedLessonIds.contains(l.id))
          .firstOrNull;
      if (next != null) return next;
    }
    return lessons.first;
  }

  Lesson? getNextLesson(String lessonId) {
    final idx = lessons.indexWhere((l) => l.id == lessonId);
    if (idx >= 0 && idx < lessons.length - 1) return lessons[idx + 1];
    return null;
  }

  Lesson? getPreviousLesson(String lessonId) {
    final idx = lessons.indexWhere((l) => l.id == lessonId);
    if (idx > 0) return lessons[idx - 1];
    return null;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'subject': subject,
    'classLevel': classLevel,
    'chapterNumber': chapterNumber,
    'title': title,
    'learningOutcomes': learningOutcomes,
    'estimatedMinutes': estimatedMinutes,
    'lessons': lessons.map((l) => l.toMap()).toList(),
    'pdfEntryId': pdfEntryId,
    'summaryQuiz': summaryQuiz.map((q) => q.toMap()).toList(),
  };

  factory Chapter.fromMap(Map<String, dynamic> map) => Chapter(
    id: map['id']?.toString() ?? '',
    subject: map['subject']?.toString() ?? '',
    classLevel: map['classLevel']?.toString() ?? '',
    chapterNumber: map['chapterNumber'] as int? ?? 0,
    title: map['title']?.toString() ?? '',
    learningOutcomes: List<String>.from(map['learningOutcomes'] ?? []),
    estimatedMinutes: map['estimatedMinutes'] as int? ?? 0,
    lessons:
        (map['lessons'] as List?)
            ?.map((e) => Lesson.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    pdfEntryId: map['pdfEntryId']?.toString() ?? '',
    summaryQuiz:
        (map['summaryQuiz'] as List?)
            ?.map((e) => QuickCheck.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

/// User progress through a chapter.
class ChapterProgress {
  const ChapterProgress({
    required this.chapterId,
    required this.userId,
    required this.currentLessonId,
    required this.completedLessonIds,
    required this.quickCheckScores, // lessonId -> score (0-100)
    required this.summaryQuizScore, // 0-100, -1 if not taken
    required this.startedAt,
    required this.lastAccessedAt,
    required this.completedAt,
  });

  final String chapterId;
  final int userId;
  final String currentLessonId;
  final Set<String> completedLessonIds;
  final Map<String, int> quickCheckScores;
  final int summaryQuizScore; // -1 = not taken
  final DateTime startedAt;
  final DateTime lastAccessedAt;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;

  /// Fraction of a chapter completed.
  ///
  /// The total lesson count is not a property of progress — it belongs to the
  /// chapter — so it must be supplied. The previous zero-argument getter
  /// returned a hardcoded 0.0 no matter what had been completed, which is a
  /// lie to any caller that trusted it. It has no callers today; deleting it
  /// was the alternative, but the intent is useful so it is made correct here.
  double progressFraction(int totalLessons) {
    if (totalLessons <= 0) return 0.0;
    return (completedLessonIds.length / totalLessons).clamp(0.0, 1.0);
  }

  ChapterProgress copyWith({
    String? chapterId,
    int? userId,
    String? currentLessonId,
    Set<String>? completedLessonIds,
    Map<String, int>? quickCheckScores,
    int? summaryQuizScore,
    DateTime? startedAt,
    DateTime? lastAccessedAt,
    DateTime? completedAt,

    /// Explicitly sets [completedAt] to null.
    ///
    /// `copyWith(completedAt: null)` cannot express "clear it" because null
    /// means "unchanged", so a chapter could never be un-completed. This flag
    /// disambiguates.
    bool clearCompletedAt = false,
  }) => ChapterProgress(
    chapterId: chapterId ?? this.chapterId,
    userId: userId ?? this.userId,
    currentLessonId: currentLessonId ?? this.currentLessonId,
    completedLessonIds: completedLessonIds ?? this.completedLessonIds,
    quickCheckScores: quickCheckScores ?? this.quickCheckScores,
    summaryQuizScore: summaryQuizScore ?? this.summaryQuizScore,
    startedAt: startedAt ?? this.startedAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
  );

  Map<String, dynamic> toMap() => {
    'chapterId': chapterId,
    'userId': userId,
    'currentLessonId': currentLessonId,
    'completedLessonIds': completedLessonIds.toList(),
    'quickCheckScores': quickCheckScores,
    'summaryQuizScore': summaryQuizScore,
    'startedAt': startedAt.toIso8601String(),
    'lastAccessedAt': lastAccessedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory ChapterProgress.fromMap(Map<String, dynamic> map) => ChapterProgress(
    chapterId: map['chapterId']?.toString() ?? '',
    userId: map['userId'] as int? ?? 0,
    currentLessonId: map['currentLessonId']?.toString() ?? '',
    completedLessonIds: Set<String>.from(map['completedLessonIds'] ?? []),
    quickCheckScores: Map<String, int>.from(map['quickCheckScores'] ?? {}),
    summaryQuizScore: map['summaryQuizScore'] as int? ?? -1,
    startedAt:
        DateTime.tryParse(map['startedAt']?.toString() ?? '') ?? DateTime.now(),
    lastAccessedAt:
        DateTime.tryParse(map['lastAccessedAt']?.toString() ?? '') ??
        DateTime.now(),
    completedAt: map['completedAt'] != null
        ? DateTime.tryParse(map['completedAt']?.toString() ?? '')
        : null,
  );
}
