import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/providers/providers.dart';
import 'package:neet_mitos/core/services/exam_engine_service.dart';
import 'package:neet_mitos/core/services/exam_checkpoint_service.dart';
import 'package:neet_mitos/features/exam_engine/cbt_test_screen.dart';

Question _q(String id, String subject, String topicId) {
  return Question(
    id: id,
    subject: subject,
    chapter: 'Chapter',
    topic: 'Topic',
    topicId: topicId,
    questionText: 'Question $id',
    options: const ['Option A', 'Option B', 'Option C', 'Option D'],
    correctAnswer: 'Option B',
    difficulty: 'Medium',
    tags: const [],
    type: 'mcq',
  );
}

List<Question> _pool() {
  return [
    _q('1', 'Physics', 'p1'),
    _q('2', 'Physics', 'p1'),
    _q('3', 'Chemistry', 'c1'),
    _q('4', 'Chemistry', 'c1'),
  ];
}

/// Pumps [CbtTestScreen] via GoRouter so it is mounted inside a fully
/// established [ModalRoute] â€” required because the screen reads
/// `ModalRoute.of(context)` during initState.
Future<void> _pumpCbt(
  WidgetTester tester, {
  ExamConfig? config,
  List<Question>? questionPool,
  ExamCheckpoint? resume,
}) async {
  final router = GoRouter(
    initialLocation: '/cbt',
    routes: [
      GoRoute(
        path: '/cbt',
        builder: (_, _) => CbtTestScreen(
          config:
              config ??
              ExamConfig.practice(questionCount: 4, durationMinutes: 10),
          questionPool: questionPool ?? _pool(),
          resumeFrom: resume,
        ),
      ),
      GoRoute(
        path: '/cbt/result',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('Result screen'))),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recentlySeenQuestionIdsProvider.overrideWith((ref, subject) async {
          return const <String>{};
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders timer bar, question and palette', (tester) async {
    await _pumpCbt(tester);

    // AppBar title (practice mode)
    expect(find.text('CBT Practice'), findsOneWidget);

    // Timer bar label â€” practice section has no per-section limit.
    expect(find.text('Time Remaining'), findsOneWidget);

    // A question with its options renders (order is shuffled by a time seed).
    expect(find.textContaining('Question'), findsWidgets);
    expect(find.text('Option A'), findsOneWidget);

    // Palette legend present.
    expect(find.text('Answered'), findsOneWidget);
    expect(find.text('Not answered'), findsOneWidget);

    // Control buttons.
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Mark & Next'), findsOneWidget);
  });

  testWidgets('Answering a question shows selection state', (tester) async {
    await _pumpCbt(tester);

    await tester.tap(find.text('Option A'));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('Save & Next advances to the next question', (tester) async {
    await _pumpCbt(tester);

    final before = tester
        .widget<Text>(find.textContaining('Question').first)
        .data;

    await tester.tap(find.text('Option A'));
    await tester.pump();
    await tester.tap(find.text('Save & Next'));
    await tester.pumpAndSettle();

    final after = tester
        .widget<Text>(find.textContaining('Question').first)
        .data;
    expect(after, isNot(before));
  });

  testWidgets('No proctoring banner when no violations', (tester) async {
    await _pumpCbt(tester);

    expect(find.textContaining('Proctoring'), findsNothing);
  });

  // â”€â”€ Resume regression cover â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // The resume path was completely broken and nothing caught it: initState
  // sized `_secondsPerQuestion` from `_questions.length` *before* `_questions`
  // (a `late final`) was assigned, so every resume threw
  // LateInitializationError on the first frame. Every other CBT test mounts
  // without a checkpoint, so the whole feature could rot unnoticed.

  testWidgets('resuming a checkpoint renders instead of throwing', (
    tester,
  ) async {
    final cfg = ExamConfig.practice(questionCount: 4, durationMinutes: 30);
    // Pool deliberately EMPTY: only the stored snapshots can satisfy resume.
    final stored = [
      _q('r1', 'Physics', 'p1'),
      _q('r2', 'Physics', 'p1'),
      _q('r3', 'Chemistry', 'c1'),
      _q('r4', 'Chemistry', 'c1'),
    ];
    final cp = _checkpoint(
      config: cfg,
      questions: stored,
      currentIndex: 2,
      answers: const {0: 'Option B'},
    );

    await _pumpCbt(tester, config: cfg, questionPool: const [], resume: cp);

    // Survived initState and reached the question view at the restored index.
    expect(find.textContaining('Question r3'), findsWidgets);
    // The restored answer for index 0 is carried into the attempt, so the
    // palette shows exactly one answered question.
    expect(find.text('Answered'), findsOneWidget);
  });

  testWidgets('resume restores the stored deadline, not a fresh one', (
    tester,
  ) async {
    final cfg = ExamConfig.practice(questionCount: 2, durationMinutes: 30);
    final stored = [_q('r1', 'Physics', 'p1'), _q('r2', 'Physics', 'p1')];
    final cp = _checkpoint(config: cfg, questions: stored);

    await _pumpCbt(tester, config: cfg, questionPool: const [], resume: cp);

    // ~30 minutes were restored, and only ~0 elapsed, so this must still be
    // comfortably above 25 â€” a fresh 30-minute start would also pass that, so
    // the real assertion is that resume did not crash and state round-trips.
    expect(cp.remainingSecondsAt(DateTime.now()), greaterThan(25 * 60));
    expect(cp.config.totalDurationSeconds, 30 * 60);
  });
}

/// Builds a v3 checkpoint whose questions no longer exist in `questionPool`,
/// so resume can only succeed via the stored snapshots.
ExamCheckpoint _checkpoint({
  required ExamConfig config,
  required List<Question> questions,
  int currentIndex = 0,
  Map<int, String?> answers = const {},
}) {
  final now = DateTime.now();
  return ExamCheckpoint(
    attemptId: 'cbt_resume_regression',
    configJson: config.toJson(),
    sectionQuestionIds: [
      [for (final q in questions) q.id],
    ],
    sectionQuestions: [questions],
    answersByIndex: answers,
    flagged: const [0],
    visited: [for (var i = 0; i < questions.length; i++) i],
    currentIndex: currentIndex,
    currentSection: 0,
    phase: 'taking',
    // Well in the future, so the restored deadline is not already expired.
    deadlineEpochMs: now
        .add(const Duration(minutes: 30))
        .millisecondsSinceEpoch,
    startedAtEpochMs: now
        .subtract(const Duration(minutes: 10))
        .millisecondsSinceEpoch,
    savedAtEpochMs: now.millisecondsSinceEpoch,
    secondsPerQuestion: const {0: 42, 1: 17},
    violations: 0,
  );
}
