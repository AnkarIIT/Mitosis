import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/models/question_model.dart' as model;
import 'package:neet_mitos/core/models/subject_model.dart';
import 'package:neet_mitos/core/providers/providers.dart';
import 'package:neet_mitos/features/profile/profile_screen.dart';
import 'package:neet_mitos/features/study_plan/study_plan_screen.dart';
import 'package:neet_mitos/features/topic_browser/topic_detail_screen.dart';
import 'package:neet_mitos/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('AppDatabase returns a single shared instance', () {
    final first = AppDatabase();
    final second = AppDatabase();

    expect(identical(first, second), isTrue);
  });

  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('NEET Mitos'), findsWidgets);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Practice Tests'), findsOneWidget);
  });

  testWidgets('Settings screen removes external website CTA', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Get your FREE API Key here'), findsNothing);
  });

  testWidgets('Home screen shows today focus and study planner CTA', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Today’s Focus'), findsOneWidget);
    expect(find.text('Open Study Planner'), findsOneWidget);
  });

  testWidgets('Weak Topics quick action opens the progress dashboard', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Weak Topics'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weak Topics'));
    await tester.pumpAndSettle();

    expect(find.text('Subject-wise Performance'), findsOneWidget);
    expect(find.text('Revision Flashcards'), findsNothing);
  });

  testWidgets('Topic detail routes Ask AI Tutor to chatbot screen', (
    WidgetTester tester,
  ) async {
    final topic = Topic(
      id: 'cell_division',
      name: 'Cell Division',
      chapterId: 'chapter_1',
      difficulty: 'Easy',
      summary: 'Cell division is the process by which cells reproduce.',
      keyPoints: ['Mitosis', 'Meiosis'],
      questionCount: 5,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          questionsForTopicProvider.overrideWith(
            (ref, topicId) async => const <model.Question>[],
          ),
        ],
        child: MaterialApp(
          home: TopicDetailScreen(
            topic: topic,
            subjectName: 'Biology',
            chapterName: 'Cell Biology',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.ensureVisible(find.text('ASK AI TUTOR ABOUT THIS'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('ASK AI TUTOR ABOUT THIS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('AI Doubt Solver 🤖'), findsOneWidget);
  });

  testWidgets(
    'Topic detail shows a test series fallback when no questions exist',
    (WidgetTester tester) async {
      final topic = Topic(
        id: 'cell_division',
        name: 'Cell Division',
        chapterId: 'chapter_1',
        difficulty: 'Easy',
        summary: 'Cell division is the process by which cells reproduce.',
        keyPoints: ['Mitosis', 'Meiosis'],
        questionCount: 5,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            questionsForTopicProvider.overrideWith(
              (ref, topicId) async => const <model.Question>[],
            ),
            allQuestionsProvider.overrideWith(
              (ref) async => const <model.Question>[],
            ),
          ],
          child: MaterialApp(
            home: TopicDetailScreen(
              topic: topic,
              subjectName: 'Biology',
              chapterName: 'Cell Biology',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('TRY TEST SERIES INSTEAD'), findsOneWidget);

      await tester.ensureVisible(find.text('TRY TEST SERIES INSTEAD'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('TRY TEST SERIES INSTEAD'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Test Series'), findsOneWidget);
    },
  );

  testWidgets('Profile screen persists updated target score', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfileScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('UPDATE GOAL'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '720');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('neet_target_score'), 720);
    expect(find.text('720'), findsOneWidget);
  });

  testWidgets('Study planner shows live target score milestones', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'neet_target_score': 720});

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: StudyPlanScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Target Score'), findsOneWidget);
    expect(find.textContaining('720'), findsOneWidget);
    expect(find.text('342 Days Remaining'), findsNothing);
  });
}
