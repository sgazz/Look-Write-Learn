import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    super.key,
    required this.strokeColor,
    required this.strokeWidth,
    required this.onClearRequested,
  });

  final Color strokeColor;
  final double strokeWidth;
  final VoidCallback onClearRequested;

  static final ValueNotifier<bool> clearCanvasNotifier = ValueNotifier<bool>(false);

  static ValueNotifier<bool> get clearCanvasNotifierRef => clearCanvasNotifier;

  static set clearCanvasNotifier(ValueNotifier<bool> v) {
    // noop to preserve API in main.dart usage; the static is final ref
  }

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final List<_Stroke> strokes = <_Stroke>[];
  _Stroke? currentStroke;

  @override
  void initState() {
    super.initState();
    DrawingCanvas.clearCanvasNotifierRef.addListener(_maybeClear);
  }

  @override
  void dispose() {
    DrawingCanvas.clearCanvasNotifierRef.removeListener(_maybeClear);
    super.dispose();
  }

  void _maybeClear() {
    if (DrawingCanvas.clearCanvasNotifierRef.value) {
      setState(() => strokes.clear());
      DrawingCanvas.clearCanvasNotifierRef.value = false;
      widget.onClearRequested();
    }
  }

  void _startStroke(Offset p) {
    currentStroke = _Stroke(
      color: widget.strokeColor,
      width: widget.strokeWidth,
      points: <Offset>[p],
    );
  }

  void _extendStroke(Offset p) {
    currentStroke?.points.add(p);
  }

  void _endStroke() {
    if (currentStroke != null) {
      strokes.add(currentStroke!);
      currentStroke = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return MouseRegion(
          cursor: SystemMouseCursors.precise,
          child: GestureDetector(
            onPanStart: (DragStartDetails d) => setState(() => _startStroke(d.localPosition)),
            onPanUpdate: (DragUpdateDetails d) => setState(() => _extendStroke(d.localPosition)),
            onPanEnd: (_) => setState(_endStroke),
            onPanCancel: () => setState(_endStroke),
            child: CustomPaint(
              painter: _CanvasPainter(strokes: strokes, inProgress: currentStroke),
              size: Size.infinite,
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Stroke {
  _Stroke({required this.color, required this.width, required this.points});
  final Color color;
  final double width;
  final List<Offset> points;
}

class _CanvasPainter extends CustomPainter {
  _CanvasPainter({required this.strokes, required this.inProgress});

  final List<_Stroke> strokes;
  final _Stroke? inProgress;

  @override
  void paint(Canvas canvas, Size size) {
    // No background - transparent canvas
    void drawStroke(_Stroke s) {
      final Paint paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (s.points.length < 2) {
        if (s.points.isNotEmpty) {
          canvas.drawPoints(ui.PointMode.points, s.points, paint);
        }
        return;
      }

      final Path path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (int i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx, s.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final _Stroke s in strokes) {
      drawStroke(s);
    }
    if (inProgress != null) {
      drawStroke(inProgress!);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) {
    return !listEquals(oldDelegate.strokes, strokes) || oldDelegate.inProgress != inProgress;
  }
}


