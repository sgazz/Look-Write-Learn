import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    super.key,
    required this.strokeColor,
    required this.strokeWidth,
    required this.onClearRequested,
    this.isEraserMode = false,
  });

  final Color strokeColor;
  final double strokeWidth;
  final VoidCallback onClearRequested;
  final bool isEraserMode;

  static final ValueNotifier<bool> clearCanvasNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> undoNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> redoNotifier = ValueNotifier<bool>(false);

  static ValueNotifier<bool> get clearCanvasNotifierRef => clearCanvasNotifier;
  static ValueNotifier<bool> get undoNotifierRef => undoNotifier;
  static ValueNotifier<bool> get redoNotifierRef => redoNotifier;

  static set clearCanvasNotifier(ValueNotifier<bool> v) {
    // noop to preserve API in main.dart usage; the static is final ref
  }
  static set undoNotifier(ValueNotifier<bool> v) {
    // noop to preserve API in main.dart usage; the static is final ref
  }
  static set redoNotifier(ValueNotifier<bool> v) {
    // noop to preserve API in main.dart usage; the static is final ref
  }

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final List<_Stroke> strokes = <_Stroke>[];
  final List<List<_Stroke>> undoStack = <List<_Stroke>>[];
  final List<List<_Stroke>> redoStack = <List<_Stroke>>[];
  _Stroke? currentStroke;

  @override
  void initState() {
    super.initState();
    DrawingCanvas.clearCanvasNotifierRef.addListener(_maybeClear);
    DrawingCanvas.undoNotifierRef.addListener(_maybeUndo);
    DrawingCanvas.redoNotifierRef.addListener(_maybeRedo);
  }

  @override
  void dispose() {
    DrawingCanvas.clearCanvasNotifierRef.removeListener(_maybeClear);
    DrawingCanvas.undoNotifierRef.removeListener(_maybeUndo);
    DrawingCanvas.redoNotifierRef.removeListener(_maybeRedo);
    super.dispose();
  }

  void _maybeClear() {
    if (DrawingCanvas.clearCanvasNotifierRef.value) {
      setState(() => strokes.clear());
      DrawingCanvas.clearCanvasNotifierRef.value = false;
      widget.onClearRequested();
    }
  }

  void _maybeUndo() {
    if (DrawingCanvas.undoNotifierRef.value) {
      undo();
      DrawingCanvas.undoNotifierRef.value = false;
    }
  }

  void _maybeRedo() {
    if (DrawingCanvas.redoNotifierRef.value) {
      redo();
      DrawingCanvas.redoNotifierRef.value = false;
    }
  }

  void _startStroke(Offset p) {
    currentStroke = _Stroke(
      color: widget.isEraserMode ? Colors.transparent : widget.strokeColor,
      width: widget.strokeWidth,
      points: <Offset>[p],
      isEraser: widget.isEraserMode,
    );
  }

  void _extendStroke(Offset p) {
    currentStroke?.points.add(p);
  }

  void _endStroke() {
    if (currentStroke != null) {
      // Save state for undo before adding new stroke
      undoStack.add(List<_Stroke>.from(strokes));
      redoStack.clear(); // Clear redo stack when new action is performed
      
      strokes.add(currentStroke!);
      currentStroke = null;
    }
  }

  void undo() {
    if (undoStack.isNotEmpty) {
      redoStack.add(List<_Stroke>.from(strokes));
      strokes.clear();
      strokes.addAll(undoStack.removeLast());
      setState(() {});
    }
  }

  void redo() {
    if (redoStack.isNotEmpty) {
      undoStack.add(List<_Stroke>.from(strokes));
      strokes.clear();
      strokes.addAll(redoStack.removeLast());
      setState(() {});
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
  _Stroke({required this.color, required this.width, required this.points, this.isEraser = false});
  final Color color;
  final double width;
  final List<Offset> points;
  final bool isEraser;
}

class _CanvasPainter extends CustomPainter {
  _CanvasPainter({required this.strokes, required this.inProgress});

  final List<_Stroke> strokes;
  final _Stroke? inProgress;

  @override
  void paint(Canvas canvas, Size size) {
    // No background - transparent canvas
    void drawStroke(_Stroke s) {
      if (s.isEraser) {
        // For eraser, use blend mode to erase
        final Paint paint = Paint()
          ..color = Colors.white // Use white for erasing
          ..strokeWidth = s.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..blendMode = BlendMode.clear; // This will erase pixels

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
      } else {
        // Normal drawing
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


