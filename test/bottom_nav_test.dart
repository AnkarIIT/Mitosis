import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/providers/providers.dart';
import 'package:neet_mitos/core/services/question_inventory_service.dart';
import 'package:neet_mitos/features/home/home_content/home_tab.dart';
import 'package:neet_mitos/features/home/home_content/learn_hub_screen.dart';
import 'package:neet_mitos/features/home/home_content/practice_hub_screen.dart';
import 'package:neet_mitos/features/flashcards/flashcard_dashboard_screen.dart';
import 'package:neet_mitos/features/review/spaced_review_screen.dart';
import 'package:neet_mitos/features/progress/progress_dashboard.dart';
import 'package:neet_mitos/features/profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bottom navigation mapping', () {
    testWidgets('Today tab shows home content', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      await tester.binding.setSurfaceSize(const Size(420, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier()),
            onboardingCompleteProvider.overrideWith((ref) => true),
            // HomeTab renders an indeterminate spinner while this pending
            // provider queries the real database; under `flutter test` that
            // never resolves, so pumpAndSettle could never settle.
            neet2024ReadinessProvider.overrideWith(
              (ref) async => const MockInventoryResult(
                mockName: 'NEET 2024 Mock',
                requirements: {'Physics': 180},
                available: {'Physics': 180},
                shortages: {},
                isReady: true,
              ),
            ),
          ],
          child: const MaterialApp(home: HomeTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Featured Subjects'), findsOneWidget);
    });

    testWidgets('Learn tab shows learn hub', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LearnHubScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Subjects & Chapters'), findsOneWidget);
    });

    testWidgets('Practice tab shows practice hub', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: PracticeHubScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Daily Practice Paper'), findsOneWidget);
    });

    testWidgets('Flashcards tab shows flashcard dashboard', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dueFlashcardsProvider.overrideWith((ref) async => const []),
            flashcardsProvider.overrideWith((ref) => const []),
          ],
          child: const MaterialApp(home: FlashcardDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flashcards'), findsOneWidget);
    });

    testWidgets('Review tab shows review session', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SpacedReviewScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review Session'), findsOneWidget);
    });

    testWidgets('Progress tab shows progress dashboard', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ProgressDashboard())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Progress'), findsOneWidget);
    });

    testWidgets('Profile screen shows target score card', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ProfileScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('NEET Target Score'), findsOneWidget);
    });
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
