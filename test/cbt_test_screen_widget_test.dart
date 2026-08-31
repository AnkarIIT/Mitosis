import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/providers/providers.dart';
import 'package:neet_mitos/core/services/exam_engine_service.dart';
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
/// established [ModalRoute] — required because the screen reads
/// `ModalRoute.of(context)` during initState.
Future<void> _pumpCbt(
  WidgetTester tester, {
  ExamConfig? config,
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
          questionPool: _pool(),
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

    // Timer bar label — practice section has no per-section limit.
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

    final before =
        tester.widget<Text>(find.textContaining('Question').first).data;

    await tester.tap(find.text('Option A'));
    await tester.pump();
    await tester.tap(find.text('Save & Next'));
    await tester.pumpAndSettle();

    final after =
        tester.widget<Text>(find.textContaining('Question').first).data;
    expect(after, isNot(before));
  });

  testWidgets('No proctoring banner when no violations', (tester) async {
    await _pumpCbt(tester);

    expect(find.textContaining('Proctoring'), findsNothing);
  });
}
