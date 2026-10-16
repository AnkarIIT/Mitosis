import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/question_model.dart';
import 'package:neet_mitos/core/models/flashcard_model.dart';
import 'package:neet_mitos/core/providers/providers.dart';
import 'package:neet_mitos/core/services/question_inventory_service.dart';
import 'package:neet_mitos/core/services/exam_engine_service.dart';
import 'package:neet_mitos/core/theme/app_theme.dart';
import 'package:neet_mitos/features/chatbot/chatbot_screen.dart';
import 'package:neet_mitos/features/dpp/dpp_neet_screen.dart';
import 'package:neet_mitos/features/error_book/error_book_screen.dart';
import 'package:neet_mitos/features/exam_engine/cbt_instructions_screen.dart';
import 'package:neet_mitos/features/flashcards/flashcard_study_screen.dart';
import 'package:neet_mitos/features/home/home_content/home_tab.dart';
import 'package:neet_mitos/features/home/home_content/learn_hub_screen.dart';
import 'package:neet_mitos/features/home/home_content/practice_hub_screen.dart';
import 'package:neet_mitos/features/profile/profile_screen.dart';
import 'package:neet_mitos/features/progress/progress_dashboard.dart';
import 'package:neet_mitos/features/review/spaced_review_screen.dart';
import 'package:neet_mitos/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small-screen + large-text device matrix.
///
/// A RenderFlex overflow fails the test, so pumping the core loop screens at
/// 360px width with 1.3x text proves the release gate: no clipped content on
/// small Android phones with accessibility text sizes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSmall(
    WidgetTester tester,
    Widget screen, {
    List<Override> overrides = const [],
    bool dark = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() => tester.binding.platformDispatcher.clearAllTestValues());
    SharedPreferences.setMockInitialValues({'onboarding_complete_guest': true});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          onboardingCompleteProvider.overrideWith((ref) => true),
          // The home screen shows an indeterminate spinner while this provider
          // is pending, and it queries the real database — which never resolves
          // under `flutter test`, so pumpAndSettle could never settle.
          neet2024ReadinessProvider.overrideWith(
            (ref) async => const MockInventoryResult(
              mockName: 'NEET 2024 Mock',
              requirements: {'Physics': 180},
              available: {'Physics': 180},
              shortages: {},
              isReady: true,
            ),
          ),
          ...overrides,
        ],
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Small screen (360px) + large text (1.3x)', () {
    testWidgets('Today tab renders without overflow', (tester) async {
      await pumpSmall(tester, const HomeTab());
      expect(find.text('Featured Subjects'), findsOneWidget);
      expect(find.text("Start today's plan"), findsOneWidget);
    });

    testWidgets('Today tab renders without overflow in dark mode', (
      tester,
    ) async {
      await pumpSmall(tester, const HomeTab(), dark: true);
      expect(find.text('Featured Subjects'), findsOneWidget);
    });

    testWidgets('Learn and Practice hubs render', (tester) async {
      await pumpSmall(tester, const LearnHubScreen());
      expect(find.text('Subjects & Chapters'), findsOneWidget);
    });

    testWidgets('Practice hub renders', (tester) async {
      await pumpSmall(tester, const PracticeHubScreen());
      expect(find.text('Daily Practice Paper'), findsOneWidget);
    });

    testWidgets('DPP setup renders with summary and start CTA', (tester) async {
      await pumpSmall(tester, const DppNeetScreen());
      expect(find.text('Scope'), findsOneWidget);
      expect(find.textContaining('Start DPP'), findsOneWidget);
    });

    testWidgets('DPP setup renders in dark mode', (tester) async {
      await pumpSmall(tester, const DppNeetScreen(), dark: true);
      expect(find.text('Scope'), findsOneWidget);
    });

    testWidgets('CBT instructions render with sticky start', (tester) async {
      await pumpSmall(
        tester,
        CbtInstructionsScreen(
          config: ExamConfig.neet(),
          questionPool: const [],
        ),
      );
      expect(find.text('Start Test'), findsOneWidget);
      expect(find.text('Before you start'), findsOneWidget);
    });

    testWidgets('Review empty state renders', (tester) async {
      await pumpSmall(
        tester,
        const SpacedReviewScreen(),
        overrides: [
          dueCardsProvider.overrideWith((ref) async => const <Question>[]),
        ],
      );
      expect(find.text('All caught up!'), findsOneWidget);
    });

    testWidgets('Error Book empty state offers a next step', (tester) async {
      await pumpSmall(
        tester,
        const ErrorBookScreen(),
        overrides: [
          errorBookProvider.overrideWith((ref) async => const <Question>[]),
        ],
      );
      expect(find.text('Start practicing'), findsOneWidget);
    });

    testWidgets('Flashcard empty state renders', (tester) async {
      await pumpSmall(
        tester,
        const FlashcardStudyScreen(),
        overrides: [
          dueFlashcardsProvider.overrideWith(
            (ref) async => const <Flashcard>[],
          ),
        ],
      );
      expect(find.text('All caught up!'), findsOneWidget);
    });

    testWidgets('Profile renders with marks-based goal card', (tester) async {
      await pumpSmall(tester, const ProfileScreen());
      expect(find.text('NEET Target Score'), findsOneWidget);
      expect(find.textContaining('Best mock'), findsOneWidget);
    });

    testWidgets('Progress dashboard renders', (tester) async {
      await pumpSmall(tester, const ProgressDashboard());
      expect(find.text('NEET Rank Predictor'), findsOneWidget);
    });

    testWidgets('Progress dashboard renders in dark mode', (tester) async {
      await pumpSmall(tester, const ProgressDashboard(), dark: true);
      expect(find.text('NEET Rank Predictor'), findsOneWidget);
    });

    testWidgets('Settings sections render', (tester) async {
      await pumpSmall(tester, const SettingsScreen());
      expect(find.text('ACCOUNT'), findsOneWidget);
      // Lower sections build lazily — scroll before asserting.
      await tester.scrollUntilVisible(find.text('AI TUTOR CONFIGURATION'), 300);
      expect(find.text('AI TUTOR CONFIGURATION'), findsOneWidget);
    });

    testWidgets('AI Tutor renders setup guidance when unconfigured', (
      tester,
    ) async {
      await pumpSmall(tester, const ChatbotScreen());
      expect(find.text('AI Doubt Solver'), findsOneWidget);
      // Fresh test env has no API key: the persistent setup banner must
      // show instead of leaving the user to discover dialogs per tap.
      expect(
        find.text('AI Tutor needs a free Gemini API key to answer.'),
        findsOneWidget,
      );
    });
  });
}

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier()
    : super(AuthState(status: AuthStatus.authenticated, isGuest: true));

  @override
  Future<void> checkAuth() async {}

  @override
  Future<void> continueAsGuest() async {}

  @override
  Future<bool> toggle2FA(bool enabled) async => false;

  @override
  Future<bool> enable2FA(String email) async => false;

  @override
  Future<bool> confirmEnable2FA(String email, String code) async => false;

  @override
  Future<bool> disable2FA() async => false;

  @override
  Future<bool> verifyLogin2FA(String code) async => false;

  @override
  Future<bool> resendLogin2FA() async => false;

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
