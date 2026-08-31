import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// NTA-style on-screen calculator for the CBT exam screen.
///
/// Designed to feel closer to exam-tool UIs:
/// - Two-line display: expression history + current value
/// - Clear operator keys and accent-colored action buttons
/// - Theme-aware via [AdaptiveColors]
/// - No extra dependencies beyond Flutter core
class OnScreenCalculator extends StatefulWidget {
  const OnScreenCalculator({super.key});

  @override
  State<OnScreenCalculator> createState() => _OnScreenCalculatorState();
}

class _OnScreenCalculatorState extends State<OnScreenCalculator> {
  /// Current editable value shown in the main display.
  String _current = '0';

  /// Previous operand for pending operation.
  double? _previous;

  /// Pending operation symbol.
  String? _operator;

  /// Whether the next digit input should start a fresh number.
  bool _fresh = true;

  /// Last completed expression shown in the top display.
  String _expression = '';

  @override
  Widget build(BuildContext context) {
    final accent = AdaptiveColors.primary(context);
    final surface = AdaptiveColors.surface(context);
    final textPrimary = AdaptiveColors.textPrimary(context);
    final textSecondary = AdaptiveColors.textSecondary(context);
    final bg = AdaptiveColors.background(context);
    final divider = AdaptiveColors.divider(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expression / history line
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: divider),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                _expression,
                key: const Key('calc-expression'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Main display
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: divider),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  _current,
                  key: const Key('calc-current'),
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
          _buildKeypad(
            accent: accent,
            surface: surface,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            bg: bg,
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad({
    required Color accent,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color bg,
  }) {
    Widget key(
      String label, {
      VoidCallback? onTap,
      Color? bgColor,
      Color? fg,
      double fontSize = 18,
      bool bold = false,
    }) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Material(
            color: bgColor ?? surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              key: Key('calc-key-$label'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 54,
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
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
            key('AC', onTap: _clearAll, bgColor: bg, fg: textSecondary, fontSize: 15),
            key('±', onTap: _toggleSign, bgColor: bg, fg: textSecondary, fontSize: 15),
            key('%', onTap: _toPercent, bgColor: bg, fg: textSecondary, fontSize: 15),
            key('÷', onTap: () => _setOp('÷'), bgColor: accent, fg: Colors.white, bold: true),
          ],
        ),
        Row(
          children: [
            key('7', onTap: () => _digit('7')),
            key('8', onTap: () => _digit('8')),
            key('9', onTap: () => _digit('9')),
            key('×', onTap: () => _setOp('×'), bgColor: accent, fg: Colors.white, bold: true),
          ],
        ),
        Row(
          children: [
            key('4', onTap: () => _digit('4')),
            key('5', onTap: () => _digit('5')),
            key('6', onTap: () => _digit('6')),
            key('-', onTap: () => _setOp('-'), bgColor: accent, fg: Colors.white, bold: true),
          ],
        ),
        Row(
          children: [
            key('1', onTap: () => _digit('1')),
            key('2', onTap: () => _digit('2')),
            key('3', onTap: () => _digit('3')),
            key('+', onTap: () => _setOp('+'), bgColor: accent, fg: Colors.white, bold: true),
          ],
        ),
        Row(
          children: [
            key('0', onTap: () => _digit('0')),
            key('.', onTap: () => _digit('.')),
            key('=', onTap: _equals, bgColor: accent, fg: Colors.white, bold: true),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Calculator logic
  // ─────────────────────────────────────────────────────────────

  void _digit(String d) {
    setState(() {
      if (_fresh) {
        _current = d == '.' ? '0.' : d;
        _fresh = false;
        return;
      }
      if (d == '.' && _current.contains('.')) return;
      if (_current == '0' && d != '.') {
        _current = d;
        return;
      }
      _current += d;
    });
  }

  void _setOp(String op) {
    setState(() {
      final currentValue = double.tryParse(_current) ?? 0;

      if (_operator != null && !_fresh) {
        final result = _calculate(_previous!, currentValue, _operator!);
        _current = _formatResult(result);
        _expression = '${_formatOperand(_previous!)} $_operator ${_formatOperand(currentValue)} =';
        _previous = result;
      } else {
        _previous = currentValue;
      }

      _operator = op;
      _fresh = true;
    });
  }

  void _equals() {
    setState(() {
      if (_operator == null || _previous == null) return;

      final currentValue = double.tryParse(_current) ?? 0;
      final result = _calculate(_previous!, currentValue, _operator!);
      _expression = '${_formatOperand(_previous!)} $_operator ${_formatOperand(currentValue)} =';
      _current = _formatResult(result);
      _previous = null;
      _operator = null;
      _fresh = true;
    });
  }

  void _clearAll() {
    setState(() {
      _current = '0';
      _previous = null;
      _operator = null;
      _fresh = true;
      _expression = '';
    });
  }

  void _toggleSign() {
    setState(() {
      if (_current == '0') return;
      if (_current.startsWith('-')) {
        _current = _current.substring(1);
      } else {
        _current = '-$_current';
      }
    });
  }

  void _toPercent() {
    setState(() {
      final value = double.tryParse(_current) ?? 0;
      _current = _formatResult(value / 100);
      _fresh = true;
    });
  }

  double _calculate(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b == 0 ? double.nan : a / b;
      default:
        return b;
    }
  }

  String _formatOperand(double value) {
    if (value.isNaN || value.isInfinite) return 'Error';
    final text = value.toStringAsFixed(10);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String _formatResult(double r) {
    if (r.isNaN || r.isInfinite) return 'Error';
    final abs = r.abs();
    final rounded = abs < 1e12
        ? double.parse(abs.toStringAsPrecision(12))
        : abs;
    var text = rounded.toStringAsFixed(10);
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
    if (text.isEmpty || text == '-0') text = '0';
    return text;
  }
}

/// Helper to present the calculator bottom sheet from the exam screen.
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
