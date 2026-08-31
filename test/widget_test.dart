import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/models/question_model.dart' as model;
import 'package:neet_mitos/core/models/subject_model.dart';
import 'package:neet_mitos/core/providers/providers.dart';
import 'package:neet_mitos/core/services/connectivity_service.dart';
import 'package:neet_mitos/features/settings/settings_screen.dart';
import 'package:neet_mitos/features/profile/profile_screen.dart';
import 'package:neet_mitos/features/study_plan/study_plan_screen.dart';
import 'package:neet_mitos/features/topic_browser/topic_detail_screen.dart';
import 'package:neet_mitos/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

GoRouter _testRouter({required Widget child}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => child),
      GoRoute(
        path: '/topic/:topicId',
        builder: (_, state) {
          final topicId = state.pathParameters['topicId']!;
          final subjectName = state.uri.queryParameters['subjectName'] ?? '';
          final chapterName = state.uri.queryParameters['chapterName'] ?? '';
          return TopicDetailScreen(
            topicId: topicId,
            subjectName: subjectName,
            chapterName: chapterName,
          );
        },
      ),
      GoRoute(
        path: '/chat',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('AI Doubt Solver'))),
      ),
      GoRoute(
        path: '/test-series',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('Test Series'))),
      ),
      GoRoute(
        path: '/quiz',
        builder: (_, _) => const Scaffold(body: Center(child: Text('Quiz'))),
      ),
      GoRoute(
        path: '/progress',
        builder: (_, _) => const Scaffold(
          body: Center(child: Text('Subject-wise Performance')),
        ),
      ),
    ],
  );
}

void main() {
  ConnectivityService.instance.setSkipNetworkCheck(true);

  test('AppDatabase returns a single shared instance', () {
    final first = AppDatabase();
    final second = AppDatabase();

    expect(identical(first, second), isTrue);
  });

  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    await tester.binding.setSurfaceSize(const Size(420, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          onboardingCompleteProvider.overrideWith((ref) => true),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Featured Subjects'), findsOneWidget);
    expect(find.text('Ongoing Progress'), findsWidgets);
  });

  testWidgets('Settings screen removes external website CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Get your FREE API Key here'), findsNothing);
  });

  testWidgets('Home screen shows ongoing progress section', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    await tester.binding.setSurfaceSize(const Size(420, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          onboardingCompleteProvider.overrideWith((ref) => true),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ongoing Progress'), findsOneWidget);
  });

  testWidgets('Weak Topics quick action opens the progress dashboard', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    await tester.binding.setSurfaceSize(const Size(420, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          onboardingCompleteProvider.overrideWith((ref) => true),
          weakTopicsProvider.overrideWith(
            (ref) => [
              Topic(
                id: 'weak_topic_1',
                name: 'Rotation',
                chapterId: 'physics_ch4',
                difficulty: 'Hard',
                summary: 'Weak topic for testing',
                keyPoints: ['Torque', 'Angular Momentum'],
                questionCount: 3,
              ),
            ],
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The home tab should show the Weak Topics banner when weak topics exist
    expect(find.text('Weak Topics'), findsOneWidget);
    expect(find.text('Rotation'), findsOneWidget);
  });

  testWidgets('Topic detail routes Ask AI Tutor to chatbot screen', (
    WidgetTester tester,
  ) async {
    final topic = Topic(
      id: 'bio_ch1_t1',
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
        child: MaterialApp.router(
          routerConfig: _testRouter(
            child: TopicDetailScreen(
              topicId: topic.id,
              subjectName: 'Biology',
              chapterName: 'Cell Biology',
            ),
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

    expect(find.text('AI Doubt Solver'), findsOneWidget);
  });

  testWidgets(
    'Topic detail shows a test series fallback when no questions exist',
    (WidgetTester tester) async {
      final topic = Topic(
        id: 'bio_ch1_t1',
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
          child: MaterialApp.router(
            routerConfig: _testRouter(
              child: TopicDetailScreen(
                topicId: topic.id,
                subjectName: 'Biology',
                chapterName: 'Cell Biology',
              ),
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

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier() : super(AuthState(status: AuthStatus.authenticated));

  @override
  Future<void> checkAuth() async {}

  @override
  Future<void> continueAsGuest() async {}

  @override
  Future<bool> toggle2FA(bool enabled) async => false;

  @override
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async => false;

  @override
  Future<bool> login({required String email, required String password}) async =>
      false;

  @override
  Future<bool> signInWithGoogle() async => false;

  @override
  Future<bool> resetPassword(String email) async => false;

  @override
  Future<bool> verifyResetCode({
    required String email,
    required String code,
    required String newPassword,
  }) async => true;

  @override
  Future<void> logout() async {}

  @override
  Future<({bool success, String message})> deleteAccount() async {
    return (success: true, message: 'deleted');
  }
}
