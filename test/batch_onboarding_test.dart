import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/providers/providers.dart';
import 'package:neet_mitos/features/onboarding/batch_onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpBatchPage(
  WidgetTester tester, {
  required VoidCallback onDone,
}) async {
  SharedPreferences.setMockInitialValues({});
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: Scaffold(body: BatchOnboardingPage(onDone: onDone)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('batch onboarding saves persona, year and commitment', (
    WidgetTester tester,
  ) async {
    var doneCalled = false;
    await _pumpBatchPage(tester, onDone: () => doneCalled = true);

    expect(find.text('Which batch are you in?'), findsOneWidget);

    await tester.ensureVisible(find.text('Class 12'));
    await tester.tap(find.text('Class 12'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();

    expect(find.text('What year are you targeting?'), findsOneWidget);
    await tester.tap(find.text('2028'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();

    expect(
      find.text('How much time can you commit daily?'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.textContaining('1 hour'));
    await tester.tap(find.textContaining('1 hour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(doneCalled, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('neet_batch'), 'Class 12');
    expect(prefs.getInt('neet_target_year'), 2028);
    expect(prefs.getInt('neet_daily_commitment_minutes'), 60);
    expect(prefs.getBool('batch_onboarding_complete'), isTrue);
  });

  testWidgets('batch onboarding can be skipped without saving', (
    WidgetTester tester,
  ) async {
    var doneCalled = false;
    await _pumpBatchPage(tester, onDone: () => doneCalled = true);

    await tester.tap(find.text('SKIP'));
    await tester.pumpAndSettle();

    expect(doneCalled, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('neet_batch'), isNull);
    expect(prefs.getBool('batch_onboarding_complete'), isNull);
  });

  testWidgets('next is disabled until a persona is selected', (
    WidgetTester tester,
  ) async {
    await _pumpBatchPage(tester, onDone: () {});

    final nextButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('NEXT'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(nextButton.onPressed, isNull);

    await tester.ensureVisible(find.text('Dropper'));
    await tester.tap(find.text('Dropper'));
    await tester.pumpAndSettle();

    final enabledNext = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('NEXT'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(enabledNext.onPressed, isNotNull);
  });
}
