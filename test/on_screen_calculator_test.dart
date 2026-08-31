import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/features/exam_engine/on_screen_calculator.dart';

Widget _host() {
  return const MaterialApp(
    home: Scaffold(body: OnScreenCalculator()),
  );
}

String _currentDisplay(WidgetTester tester) {
  final text = tester.widget<Text>(find.byKey(const Key('calc-current')));
  return text.data ?? '';
}

Future<void> _tapKeys(WidgetTester tester, List<String> keys) async {
  for (final key in keys) {
    await tester.tap(find.byKey(Key('calc-key-$key')));
    await tester.pump();
  }
}

void main() {
  testWidgets('renders digit, operator and control keys', (tester) async {
    await tester.pumpWidget(_host());

    expect(find.byKey(const Key('calc-key-AC')), findsOneWidget);
    expect(find.byKey(const Key('calc-key-±')), findsOneWidget);
    expect(find.byKey(const Key('calc-key-%')), findsOneWidget);
    for (final digit in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) {
      expect(find.byKey(Key('calc-key-$digit')), findsOneWidget);
    }
    for (final op in ['+', '-', '×', '÷', '=']) {
      expect(find.byKey(Key('calc-key-$op')), findsOneWidget);
    }
  });

  testWidgets('adds numbers', (tester) async {
    await tester.pumpWidget(_host());
    await _tapKeys(tester, ['1', '2', '+', '3', '4', '=']);

    expect(_currentDisplay(tester), '46');
  });

  testWidgets('subtracts numbers', (tester) async {
    await tester.pumpWidget(_host());
    await _tapKeys(tester, ['9', '-', '4', '=']);

    expect(_currentDisplay(tester), '5');
  });

  testWidgets('multiplies numbers', (tester) async {
    await tester.pumpWidget(_host());
    await _tapKeys(tester, ['7', '×', '8', '=']);

    expect(_currentDisplay(tester), '56');
  });

  testWidgets('divides numbers with decimal result', (tester) async {
    await tester.pumpWidget(_host());
    await _tapKeys(tester, ['1', '0', '÷', '4', '=']);

    expect(_currentDisplay(tester), '2.5');
  });

  testWidgets('division by zero shows Error', (tester) async {
    await tester.pumpWidget(_host());
    await _tapKeys(tester, ['5', '÷', '0', '=']);

    expect(_currentDisplay(tester), 'Error');
  });

  testWidgets('percent converts to hundredths', (tester) async {
    await tester.pumpWidget(_host());
    await _tapKeys(tester, ['2', '5', '%']);

    expect(_currentDisplay(tester), '0.25');
  });

  testWidgets('toggle sign negates the display', (tester) async {
    await tester.pumpWidget(_host());
    await _tapKeys(tester, ['8', '±']);

    expect(_currentDisplay(tester), '-8');

    await _tapKeys(tester, ['±']);
    expect(_currentDisplay(tester), '8');
  });

  testWidgets('AC clears the display', (tester) async {
    await tester.pumpWidget(_host());
    await _tapKeys(tester, ['9', '9', 'AC']);

    expect(_currentDisplay(tester), '0');
  });

  testWidgets('chained operations evaluate left to right', (tester) async {
    await tester.pumpWidget(_host());
    await _tapKeys(tester, ['2', '+', '3', '×', '4', '=']);

    // 2 + 3 = 5, then 5 × 4 = 20
    expect(_currentDisplay(tester), '20');
  });
}
