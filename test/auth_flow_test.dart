import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_helpers.dart';

import 'package:neet_mitos/features/auth/auth_screen.dart';

void main() {
  group('AuthNotifier Tests', () {
    test('continueAsGuest sets user as guest and authenticated', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createTestContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      // The notifier constructor kicks off checkAuth();
      // let it settle so it can't overwrite the guest state below.
      await Future<void>.delayed(Duration.zero);
      await notifier.continueAsGuest();

      final state = container.read(authProvider);
      expect(state.isGuest, isTrue);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, isNull);
    });

    test('toggle2FA is a no-op after local auth migration', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createTestContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      await notifier.checkAuth();
      final enabled = await notifier.toggle2FA(true);

      expect(enabled, isFalse);
    });
  });

  group('AuthScreen Widget Tests', () {
    testWidgets('renders welcome text and sign-in controls', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = createTestContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AuthScreen()),
        ),
      );
      // The sign-in hero intentionally has a looping canvas animation.
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
    });

    testWidgets('switches fields when changing auth mode tabs', (tester) async {
      SharedPreferences.setMockInitialValues({});
      // The form scrolls on small default surfaces — use a phone-sized
      // surface so the mode-switch button is hittable.
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = createTestContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AuthScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Initially in Login mode: Full Name field should NOT be present
      expect(find.text('Full Name'), findsNothing);

      // Tap Sign Up tab - use the TextButton directly
      final signUpButton = find.widgetWithText(
        TextButton,
        "Don't have an account? Sign up",
      );
      await tester.ensureVisible(signUpButton);
      await tester.tap(signUpButton);
      await tester.pump(const Duration(milliseconds: 500));

      // Sign Up mode: Full Name field should now be present
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
    });
  });
}
