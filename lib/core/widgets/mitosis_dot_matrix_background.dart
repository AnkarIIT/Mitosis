import 'dart:math' as math;

import 'package:flutter/material.dart';

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
            colors: [Color(0xFF061619), Color(0xFF0B282B), Color(0xFF0A2023)],
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

  static const _mint = Color(0xFF69E2C5);
  static const _gold = Color(0xFFFFD78A);
  static const _mark = <Offset>[
    Offset(0.34, 0.70),
    Offset(0.43, 0.38),
    Offset(0.50, 0.66),
    Offset(0.58, 0.34),
    Offset(0.68, 0.70),
  ];
  static const _sparkPoints = <Offset>[
    Offset(0.18, 0.31),
    Offset(0.79, 0.61),
    Offset(0.82, 0.27),
  ];

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

        var markStrength = 0.0;
        for (var index = 0; index < _mark.length - 1; index++) {
          final distance = _distanceToSegment(
            normalized,
            _mark[index],
            _mark[index + 1],
          );
          markStrength = math
              .max(markStrength, 1 - distance / 0.028)
              .toDouble();
        }
        markStrength = markStrength.clamp(0.0, 1.0).toDouble();

        var sparkleStrength = 0.0;
        for (final spark in _sparkPoints) {
          final distance = (normalized - spark).distance;
          sparkleStrength = math
              .max(sparkleStrength, 1 - distance / 0.023)
              .toDouble();
        }
        sparkleStrength = sparkleStrength.clamp(0.0, 1.0).toDouble();

        final alpha = (baseAlpha + markStrength * (0.48 + wave * 0.28))
            .clamp(0.035, 0.95)
            .toDouble();
        final radius = step * (0.075 + wave * 0.025 + markStrength * 0.07);
        if (markStrength > 0.58) {
          canvas.drawCircle(
            point,
            radius * 2.7,
            Paint()
              ..color = _mint.withValues(alpha: markStrength * 0.18)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
        }
        canvas.drawCircle(
          point,
          radius,
          Paint()..color = _mint.withValues(alpha: alpha),
        );
        if (sparkleStrength > 0.58) {
          canvas.drawCircle(
            point,
            step * 0.42,
            Paint()
              ..color = _gold.withValues(alpha: sparkleStrength * 0.22)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
          canvas.drawCircle(
            point,
            step * (0.09 + sparkleStrength * 0.055),
            Paint()..color = _gold.withValues(alpha: sparkleStrength),
          );
        }
      }
    }
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    final relative = point - start;
    final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
    final projection =
        ((relative.dx * segment.dx + relative.dy * segment.dy) / lengthSquared)
            .clamp(0.0, 1.0)
            .toDouble();
    return (point - (start + segment * projection)).distance;
  }

  @override
  bool shouldRepaint(covariant _DotMatrixPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
