import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

/// Manual crop screen for photo doubts: the student photographs a page and
/// selects just the part they're stuck on, so the vision model sees the
/// question instead of a whole page.
///
/// Deliberately dependency-free (no image_cropper plugin / no native crop
/// activity): selection is gesture-drag over the image and the crop itself is
/// pure `dart:ui` — draw the source image with the cropped source-rect into a
/// `PictureRecorder`, then export `toByteData(ImageByteFormat.png)`.
///
/// Returns the cropped file path when the user confirms, and `null` when they
/// cancel (the caller must treat cancel as "abort the question").
class PhotoCropScreen extends StatefulWidget {
  final String imagePath;

  const PhotoCropScreen({super.key, required this.imagePath});

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

enum _DragMode { none, move, topLeft, topRight, bottomLeft, bottomRight }

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  Size? _imageSize;
  Rect _cropRect = Rect.zero;
  Rect _display = Rect.zero;
  bool _initialized = false;
  bool _cropping = false;

  Offset _dragAnchor = Offset.zero;
  _DragMode _mode = _DragMode.none;

  /// Pixel radius around a corner handle that counts as grabbing it.
  static const double _handleRadius = 20;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() => _imageSize = Size(
            frame.image.width.toDouble(),
            frame.image.height.toDouble(),
          ));
    } catch (e) {
      debugPrint('❌ Crop: failed to decode image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't read the photo.")),
      );
      Navigator.of(context).pop(null);
    }
  }

  /// Where the image lands on screen with BoxFit.contain inside [box].
  Rect _displayRect(Size box, Size image) {
    final scale = (box.width / image.width)
        .clamp(0.0, box.height / image.height)
        .toDouble();
    final w = image.width * scale;
    final h = image.height * scale;
    return Offset((box.width - w) / 2, (box.height - h) / 2) & Size(w, h);
  }

  /// Ensures the initial crop box exists once we know the display rect.
  void _ensureInit(Rect display) {
    if (_initialized) return;
    _initialized = true;
    _cropRect = Rect.fromCenter(
      center: display.center,
      width: display.width * 0.8,
      height: display.height * 0.6,
    );
  }

  /// Corner point of the crop rect for the given alignment — the centre of
  /// the corresponding drag handle.
  Offset _handleCenter(Rect r, Alignment a) =>
      a.withinRect(Offset.zero & r.size) + r.topLeft;

  _DragMode _hitTest(Offset point, Rect r) {
    bool near(Alignment a) =>
        (point - _handleCenter(r, a)).distance <= _handleRadius;
    if (near(Alignment.topLeft)) return _DragMode.topLeft;
    if (near(Alignment.topRight)) return _DragMode.topRight;
    if (near(Alignment.bottomLeft)) return _DragMode.bottomLeft;
    if (near(Alignment.bottomRight)) return _DragMode.bottomRight;
    if (r.contains(point)) return _DragMode.move;
    return _DragMode.none;
  }

  void _onPanStart(DragStartDetails details, Rect r) {
    setState(() {
      _mode = _hitTest(details.localPosition, r);
      _dragAnchor = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Rect display) {
    if (_mode == _DragMode.none) return;
    final delta = details.localPosition - _dragAnchor;
    _dragAnchor = details.localPosition;
    setState(() {
      switch (_mode) {
        case _DragMode.move:
          _cropRect = _cropRect.shift(delta).clampWithin(display);
          break;
        case _DragMode.none:
          break;
        default:
          _cropRect = _resize(_cropRect, _mode, delta).clampWithin(display);
      }
    });
  }

  Rect _resize(Rect r, _DragMode mode, Offset delta) {
    switch (mode) {
      case _DragMode.topLeft:
        return Rect.fromLTRB(
          r.left + delta.dx,
          r.top + delta.dy,
          r.right,
          r.bottom,
        );
      case _DragMode.topRight:
        return Rect.fromLTRB(
          r.left,
          r.top + delta.dy,
          r.right + delta.dx,
          r.bottom,
        );
      case _DragMode.bottomLeft:
        return Rect.fromLTRB(
          r.left + delta.dx,
          r.top,
          r.right,
          r.bottom + delta.dy,
        );
      case _DragMode.bottomRight:
        return Rect.fromLTRB(
          r.left,
          r.top,
          r.right + delta.dx,
          r.bottom + delta.dy,
        );
      default:
        return r;
    }
  }

  /// Crops the stored photo through `dart:ui` and saves a PNG in the app's
  /// temporary directory. Returns the new path, or null on failure.
  Future<String?> _cropAndSave(Rect display) async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final sx = image.width / display.width;
      final sy = image.height / display.height;
      final src = Rect.fromLTWH(
        (_cropRect.left - display.left) * sx,
        (_cropRect.top - display.top) * sy,
        _cropRect.width * sx,
        _cropRect.height * sy,
      ).clampWithin(
        Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
      );
      final outWidth = src.width.round().clamp(1, image.width);
      final outHeight = src.height.round().clamp(1, image.height);

      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImageRect(
        image,
        src,
        Rect.fromLTWH(0, 0, outWidth.toDouble(), outHeight.toDouble()),
        Paint(),
      );
      final cropped = await recorder.endRecording().toImage(outWidth, outHeight);
      final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return null;

      final tempDir = await path_provider.getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/doubt_crop_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(data.buffer.asUint8List());
      return file.path;
    } catch (e) {
      debugPrint('❌ Crop failed: $e');
      return null;
    }
  }

  Future<void> _confirm(Rect display) async {
    if (_cropRect.width < 20 || _cropRect.height < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a bigger area first.')),
      );
      return;
    }
    setState(() => _cropping = true);
    final path = await _cropAndSave(display);
    if (!mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crop failed — send the full photo instead.'),
        ),
      );
      Navigator.of(context).pop(null);
      return;
    }
    Navigator.of(context).pop(path);
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = _imageSize;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Crop your doubt'),
        actions: [
          TextButton(
            onPressed: _cropping ? null : () => Navigator.of(context).pop(null),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: imageSize == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final display = _displayRect(constraints.biggest, imageSize);
                _display = display;
                _ensureInit(display);

                return Stack(
                  children: [
                    Positioned.fromRect(
                      rect: display,
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.fill,
                        width: display.width,
                        height: display.height,
                      ),
                    ),
                    Positioned.fromRect(
                      rect: display,
                      child: CustomPaint(
                        size: display.size,
                        painter: _CropOverlayPainter(
                          crop: _cropRect.shift(-display.topLeft),
                        ),
                      ),
                    ),
                    for (final alignment in const [
                      Alignment.topLeft,
                      Alignment.topRight,
                      Alignment.bottomLeft,
                      Alignment.bottomRight,
                    ])
                      Positioned.fromRect(
                        rect: Rect.fromCenter(
                          center: _handleCenter(_cropRect, alignment),
                          width: _handleRadius * 1.4,
                          height: _handleRadius * 1.4,
                        ),
                        child: const _HandleDot(),
                      ),
                    // Gesture layer last, so it wins over the visuals.
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (d) => _onPanStart(d, display),
                        onPanUpdate: (d) => _onPanUpdate(d, display),
                      ),
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: _cropping
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_cropping ? 'Cropping…' : 'Use this crop'),
            onPressed: _cropping || _imageSize == null
                ? null
                : () => _confirm(_display),
          ),
        ),
      ),
    );
  }
}

class _HandleDot extends StatelessWidget {
  const _HandleDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final Rect crop;

  _CropOverlayPainter({required this.crop});

  @override
  void paint(Canvas canvas, Size size) {
    // Dim outside the crop only.
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRect(crop)
        ..fillType = PathFillType.evenOdd,
      dim,
    );
    canvas.drawRect(
      crop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    // Rule-of-thirds guides.
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.35);
    for (final t in const [1 / 3, 2 / 3]) {
      canvas.drawLine(
        Offset(crop.left + crop.width * t, crop.top),
        Offset(crop.left + crop.width * t, crop.bottom),
        guide,
      );
      canvas.drawLine(
        Offset(crop.left, crop.top + crop.height * t),
        Offset(crop.right, crop.top + crop.height * t),
        guide,
      );
    }
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) =>
      oldDelegate.crop != crop;
}

extension _RectClamp on Rect {
  Rect clampWithin(Rect bounds) {
    final w = width.clamp(0.0, bounds.width);
    final h = height.clamp(0.0, bounds.height);
    final x = left.clamp(bounds.left, bounds.right - w);
    final y = top.clamp(bounds.top, bounds.bottom - h);
    return Rect.fromLTWH(x, y, w, h);
  }
}
