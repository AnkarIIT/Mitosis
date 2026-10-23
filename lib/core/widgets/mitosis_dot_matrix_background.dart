import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Lightweight, procedurally painted dot field for the NEET Mitos sign-in hero.
/// The slow shimmer pauses when the device requests reduced motion.
class MitosisDotMatrixBackground extends StatefulWidget {
  const MitosisDotMatrixBackground({super.key, this.height = 360});

  final double height;

  @override
  State<MitosisDotMatrixBackground> createState() =>
      _MitosisDotMatrixBackgroundState();
}

class _MitosisDotMatrixBackgroundState extends State<MitosisDotMatrixBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
      _controller.value = 0.18;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundDark,
              AppColors.brandNavy,
              Color(0xFF071C37),
            ],
          ),
        ),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _DotMatrixPainter(_controller),
            isComplex: true,
            willChange: true,
          ),
        ),
      ),
    );
  }
}

class _DotMatrixPainter extends CustomPainter {
  _DotMatrixPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const _teal = AppColors.brandTeal;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final step = (size.width / 28).clamp(10.0, 17.0).toDouble();
    final phase = animation.value * math.pi * 2;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        final point = Offset(x, y);
        final normalized = Offset(x / size.width, y / size.height);
        final wave =
            0.5 +
            0.5 * math.sin(phase + normalized.dx * 8.2 + normalized.dy * 5.4);
        final horizontalFade = (1 - (normalized.dx - 0.5).abs() * 1.35).clamp(
          0.18,
          1.0,
        );
        final verticalFade = (1 - normalized.dy * 0.46).clamp(0.42, 1.0);
        final baseAlpha = (0.07 + wave * 0.15) * horizontalFade * verticalFade;

        final alpha = baseAlpha.clamp(0.035, 0.24).toDouble();
        final radius = step * (0.075 + wave * 0.025);
        canvas.drawCircle(
          point,
          radius,
          Paint()..color = _teal.withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotMatrixPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
