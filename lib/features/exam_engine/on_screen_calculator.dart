import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A compact scientific-style on-screen calculator for use inside the CBT
/// exam. Floating-point safe enough for NEET arithmetic (+, −, ×, ÷, %).
class OnScreenCalculator extends StatefulWidget {
  const OnScreenCalculator({super.key});

  @override
  State<OnScreenCalculator> createState() => _OnScreenCalculatorState();
}

class _OnScreenCalculatorState extends State<OnScreenCalculator> {
  String _display = '0';
  double? _acc;
  String? _op;
  bool _fresh = true; // true → next digit starts a new number

  void _digit(String d) {
    setState(() {
      if (_fresh) {
        _display = d;
        _fresh = false;
        return;
      }
      if (_display == '0') {
        _display = d == '.' ? '0.' : d;
        return;
      }
      _display += d;
    });
  }

  void _setOp(String op) {
    setState(() {
      if (_op != null && !_fresh) {
        _equals(quiet: true);
      }
      _op = op;
      _acc = _current;
      _fresh = true;
    });
  }

  double get _current => double.tryParse(_display) ?? 0;

  void _equals({bool quiet = false}) {
    setState(() {
      final a = _acc;
      final b = _current;
      final op = _op;
      _op = null;
      _acc = null;
      _fresh = true;
      if (a == null || op == null) return;
      double r;
      switch (op) {
        case '+':
          r = a + b;
        case '-':
          r = a - b;
        case '×':
          r = a * b;
        case '÷':
          r = b == 0 ? double.nan : a / b;
        default:
          return;
      }
      _formatResult(r);
      if (!quiet) {
        _acc = _current;
        _fresh = true;
      }
    });
  }

  void _formatResult(double r) {
    if (r.isNaN || r.isInfinite) {
      _display = 'Error';
      return;
    }
    final abs = r.abs();
    // Trim floating point noise for values that are clean.
    final rounded = abs < 1e12
        ? double.parse(abs.toStringAsPrecision(12))
        : abs;
    var text = rounded.toStringAsFixed(10);
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
    if (text.isEmpty || text == '-0') text = '0';
    _display = text;
  }

  void _clearAll() {
    setState(() {
      _display = '0';
      _acc = null;
      _op = null;
      _fresh = true;
    });
  }

  void _toggleSign() {
    setState(() {
      if (_display == '0') return;
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    });
  }

  void _toPercent() {
    setState(() {
      final v = _current / 100;
      _formatResult(v);
      _fresh = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = AdaptiveColors.primary(context);
    final surface = AdaptiveColors.surface(context);
    final textPrimary = AdaptiveColors.textPrimary(context);
    final textSecondary = AdaptiveColors.textSecondary(context);
    final bg = AdaptiveColors.background(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdaptiveColors.divider(context)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  _display,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildKeypad(accent, surface, textPrimary, textSecondary, bg),
        ],
      ),
    );
  }

  Widget _buildKeypad(
    Color accent,
    Color surface,
    Color textPrimary,
    Color textSecondary,
    Color bg,
  ) {
    Widget key(String label,
        {VoidCallback? onTap, Color? bgColor, Color? fg, double fontSize = 18}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Material(
            color: bgColor ?? surface,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap ?? () => _digit(label),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: fg ?? textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            key('AC',
                onTap: _clearAll,
                bgColor: bg,
                fg: textSecondary,
                fontSize: 15),
            key('±', onTap: _toggleSign, bgColor: bg, fg: textSecondary),
            key('%', onTap: _toPercent, bgColor: bg, fg: textSecondary),
            key('÷',
                onTap: () => _setOp('÷'), bgColor: accent, fg: Colors.white),
          ],
        ),
        Row(
          children: [
            key('7'),
            key('8'),
            key('9'),
            key('×', onTap: () => _setOp('×'), bgColor: accent, fg: Colors.white),
          ],
        ),
        Row(
          children: [
            key('4'),
            key('5'),
            key('6'),
            key('-', onTap: () => _setOp('-'), bgColor: accent, fg: Colors.white),
          ],
        ),
        Row(
          children: [
            key('1'),
            key('2'),
            key('3'),
            key('+', onTap: () => _setOp('+'), bgColor: accent, fg: Colors.white),
          ],
        ),
        Row(
          children: [
            key('0'),
            key('.'),
            key('=', onTap: () => _equals(), bgColor: accent, fg: Colors.white),
          ],
        ),
      ],
    );
  }
}

/// Helper to present the calculator sheet from the exam screen.
Future<void> showOnScreenCalculator(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AdaptiveColors.background(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const SafeArea(child: OnScreenCalculator()),
  );
}
