import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/providers/providers.dart';

import 'package:neet_mitos/features/auth/auth_screen.dart';

void main() {
  group('AuthNotifier Tests', () {
    test('continueAsGuest sets user as guest and authenticated', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      await notifier.checkAuth();
      await notifier.continueAsGuest();

      final state = container.read(authProvider);
      expect(state.isGuest, isTrue);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, isNull);
    });

    test('signInWithMicrosoft handles unconfigured cloud auth gracefully', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      await notifier.checkAuth();
      final success = await notifier.signInWithMicrosoft();

      expect(success, isFalse);
      final state = container.read(authProvider);
      expect(state.error, contains('configured'));
      expect(state.status, AuthStatus.unauthenticated);
    });
  });

  group('AuthScreen Widget Tests', () {
    testWidgets('renders NEET Mitos title and tab controls', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );

      expect(find.text('NEET Mitos'), findsOneWidget);
      expect(find.text('Your AI-Powered NEET Partner'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('OTP'), findsOneWidget);
      expect(find.text('SKIP FOR NOW'), findsOneWidget);
    });

    testWidgets('switches fields when changing auth mode tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );

      // Initially in Log In mode: Full Name field should NOT be present
      expect(find.text('Full Name'), findsNothing);

      // Tap Sign Up tab
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Sign Up mode: Full Name field should now be present
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Username (Optional)'), findsOneWidget);

      // Tap OTP tab
      await tester.tap(find.text('OTP'));
      await tester.pumpAndSettle();

      // OTP mode: Password field should NOT be present
      expect(find.text('Password'), findsNothing);
      expect(find.text('SEND VERIFICATION OTP'), findsOneWidget);
    });
  });
}
