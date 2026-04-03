import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Full-screen widget that lets the user drag 4 corner handles to define
/// a quadrilateral crop region. On confirm, applies a perspective rectification
/// using [img.copyRectify] and saves the result as a JPEG.
///
/// Returns the path to the cropped image, or null if the user tapped Back.
class ManualCropScreen extends StatefulWidget {
  final String imagePath;

  const ManualCropScreen({super.key, required this.imagePath});

  @override
  State<ManualCropScreen> createState() => _ManualCropScreenState();
}

class _ManualCropScreenState extends State<ManualCropScreen> {
  // Decoded image dimensions (null until loaded)
  int? _imgWidth;
  int? _imgHeight;

  // Corner positions in image-pixel coordinates.
  // Initialised to the full image corners once dimensions are known.
  late Offset _topLeft;
  late Offset _topRight;
  late Offset _bottomLeft;
  late Offset _bottomRight;

  bool _loading = true;
  bool _processing = false;
  String? _error;

  // The RenderBox of the image widget — used to map touch → image coords.
  final GlobalKey _imageKey = GlobalKey();

  // Actual rendered size of the image on screen (letterboxed inside the widget).
  Size? _renderedImageSize;
  Offset? _renderedImageOffset; // top-left of the image inside the widget

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Could not decode image');

      final w = decoded.width.toDouble();
      final h = decoded.height.toDouble();

      setState(() {
        _imgWidth = decoded.width;
        _imgHeight = decoded.height;
        // Default corners: full image
        _topLeft = Offset.zero;
        _topRight = Offset(w, 0);
        _bottomLeft = Offset(0, h);
        _bottomRight = Offset(w, h);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Converts a touch position (relative to the image widget's top-left)
  /// into image pixel coordinates, accounting for letterboxing.
  Offset _touchToImage(Offset touch) {
    final rendered = _renderedImageSize;
    final offset = _renderedImageOffset;
    if (rendered == null || offset == null) return touch;

    final scaleX = _imgWidth! / rendered.width;
    final scaleY = _imgHeight! / rendered.height;

    final dx = (touch.dx - offset.dx).clamp(0.0, rendered.width);
    final dy = (touch.dy - offset.dy).clamp(0.0, rendered.height);

    return Offset(dx * scaleX, dy * scaleY);
  }

  /// Converts an image pixel coordinate to a position within the widget
  /// (accounting for letterboxing).
  Offset _imageToWidget(Offset imageCoord) {
    final rendered = _renderedImageSize;
    final offset = _renderedImageOffset;
    if (rendered == null || offset == null) return imageCoord;

    final scaleX = rendered.width / _imgWidth!;
    final scaleY = rendered.height / _imgHeight!;

    return Offset(
      imageCoord.dx * scaleX + offset.dx,
      imageCoord.dy * scaleY + offset.dy,
    );
  }

  void _updateRenderedImageGeometry() {
    final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || _imgWidth == null || _imgHeight == null) return;

    final widgetSize = box.size;
    final imgAspect = _imgWidth! / _imgHeight!;
    final widgetAspect = widgetSize.width / widgetSize.height;

    Size rendered;
    Offset offset;

    if (imgAspect > widgetAspect) {
      // Letterboxed top/bottom
      final w = widgetSize.width;
      final h = w / imgAspect;
      rendered = Size(w, h);
      offset = Offset(0, (widgetSize.height - h) / 2);
    } else {
      // Letterboxed left/right
      final h = widgetSize.height;
      final w = h * imgAspect;
      rendered = Size(w, h);
      offset = Offset((widgetSize.width - w) / 2, 0);
    }

    _renderedImageSize = rendered;
    _renderedImageOffset = offset;
  }

  Future<void> _confirm() async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) throw Exception('Could not decode image');

      // Clamp all corners to image bounds
      double clampX(double x) => x.clamp(0, src.width - 1).toDouble();
      double clampY(double y) => y.clamp(0, src.height - 1).toDouble();

      final tl = img.Point(clampX(_topLeft.dx), clampY(_topLeft.dy));
      final tr = img.Point(clampX(_topRight.dx), clampY(_topRight.dy));
      final bl = img.Point(clampX(_bottomLeft.dx), clampY(_bottomLeft.dy));
      final br = img.Point(clampX(_bottomRight.dx), clampY(_bottomRight.dy));

      final rectified = img.copyRectify(
        src,
        topLeft: tl,
        topRight: tr,
        bottomLeft: bl,
        bottomRight: br,
        interpolation: img.Interpolation.linear,
      );

      final dir = await getTemporaryDirectory();
      final outPath = p.join(dir.path, '${const Uuid().v4()}_cropped.jpg');
      final encoded = img.encodeJpg(rectified, quality: 92);
      await File(outPath).writeAsBytes(Uint8List.fromList(encoded));

      if (mounted) Navigator.pop(context, outPath);
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Crop error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Adjust Crop'),
        actions: [
          if (!_loading && _error == null && !_processing)
            TextButton(
              onPressed: _confirm,
              child: const Text(
                'Confirm',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          if (_processing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.white)))
              : _CropOverlay(
                  imageKey: _imageKey,
                  imagePath: widget.imagePath,
                  topLeft: _topLeft,
                  topRight: _topRight,
                  bottomLeft: _bottomLeft,
                  bottomRight: _bottomRight,
                  onGeometryReady: _updateRenderedImageGeometry,
                  onCornerDrag: (corner, localPosition) {
                    _updateRenderedImageGeometry();
                    final imgCoord = _touchToImage(localPosition);
                    setState(() {
                      switch (corner) {
                        case _Corner.topLeft:
                          _topLeft = imgCoord;
                        case _Corner.topRight:
                          _topRight = imgCoord;
                        case _Corner.bottomLeft:
                          _bottomLeft = imgCoord;
                        case _Corner.bottomRight:
                          _bottomRight = imgCoord;
                      }
                    });
                  },
                  imageToWidget: _imageToWidget,
                ),
      bottomNavigationBar: _loading || _error != null
          ? null
          : Container(
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: const Text(
                'Drag the corner handles to adjust the crop area.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CropOverlay extends StatefulWidget {
  final GlobalKey imageKey;
  final String imagePath;
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;
  final VoidCallback onGeometryReady;
  final void Function(_Corner corner, Offset localPosition) onCornerDrag;
  final Offset Function(Offset imageCoord) imageToWidget;

  const _CropOverlay({
    required this.imageKey,
    required this.imagePath,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.onGeometryReady,
    required this.onCornerDrag,
    required this.imageToWidget,
  });

  @override
  State<_CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<_CropOverlay> {
  @override
  void initState() {
    super.initState();
    // Notify parent once layout is done so it can compute rendered image size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onGeometryReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Recompute geometry whenever layout changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onGeometryReady();
      });

      final tl = widget.imageToWidget(widget.topLeft);
      final tr = widget.imageToWidget(widget.topRight);
      final bl = widget.imageToWidget(widget.bottomLeft);
      final br = widget.imageToWidget(widget.bottomRight);

      return Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.file(
            key: widget.imageKey,
            File(widget.imagePath),
            fit: BoxFit.contain,
          ),

          // Quad overlay
          CustomPaint(
            painter: _QuadPainter(tl: tl, tr: tr, bl: bl, br: br),
          ),

          // Corner handles
          _CornerHandle(
              position: tl,
              corner: _Corner.topLeft,
              onDrag: widget.onCornerDrag),
          _CornerHandle(
              position: tr,
              corner: _Corner.topRight,
              onDrag: widget.onCornerDrag),
          _CornerHandle(
              position: bl,
              corner: _Corner.bottomLeft,
              onDrag: widget.onCornerDrag),
          _CornerHandle(
              position: br,
              corner: _Corner.bottomRight,
              onDrag: widget.onCornerDrag),
        ],
      );
    });
  }
}

/// Draws the quadrilateral outline with a semi-transparent fill.
class _QuadPainter extends CustomPainter {
  final Offset tl, tr, bl, br;

  const _QuadPainter(
      {required this.tl,
      required this.tr,
      required this.bl,
      required this.br});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue.withAlpha(40)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(_QuadPainter old) =>
      tl != old.tl || tr != old.tr || bl != old.bl || br != old.br;
}

/// A draggable circular handle positioned at [position] (widget coordinates).
class _CornerHandle extends StatelessWidget {
  final Offset position;
  final _Corner corner;
  final void Function(_Corner corner, Offset localPosition) onDrag;

  static const double _radius = 18.0;

  const _CornerHandle({
    required this.position,
    required this.corner,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - _radius,
      top: position.dy - _radius,
      width: _radius * 2,
      height: _radius * 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          // details.localPosition is relative to the handle widget itself.
          // Convert to parent (Stack) coordinates by adding the handle's offset.
          final parentOffset = Offset(
            position.dx - _radius + details.localPosition.dx,
            position.dy - _radius + details.localPosition.dy,
          );
          onDrag(corner, parentOffset);
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 4, spreadRadius: 1),
            ],
          ),
        ),
      ),
    );
  }
}
