import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
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

    expect(find.text('Get your FREE API Key here'), findsNothing);
    expect(find.text('Gemini API Key'), findsOneWidget);
  });
}
