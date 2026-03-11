import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/pdf_state.dart';

class AnnotationLayer extends StatefulWidget {
  final int pageIndex;
  final Function(TapDownDetails) onTapDown;

  const AnnotationLayer({
    super.key,
    required this.pageIndex,
    required this.onTapDown,
  });

  @override
  State<AnnotationLayer> createState() => _AnnotationLayerState();
}

class _AnnotationLayerState extends State<AnnotationLayer> {
  final _uuid = const Uuid();
  DrawAnnotation? _currentDraw;

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfState>(
      builder: (context, state, _) {
        final textAnns = state.textAnnotations
            .where((a) => a.pageIndex == widget.pageIndex)
            .toList();
        final drawAnns = state.drawAnnotations
            .where((a) => a.pageIndex == widget.pageIndex)
            .toList();
        final imageAnns = state.imageAnnotations
            .where((a) => a.pageIndex == widget.pageIndex)
            .toList();

        return GestureDetector(
          onTapDown: (details) {
            if (state.activeTool == EditorTool.text) {
              widget.onTapDown(details);
            }
          },
          onPanStart: (details) {
            if (state.activeTool == EditorTool.draw ||
                state.activeTool == EditorTool.highlight ||
                state.activeTool == EditorTool.underline) {
              setState(() {
                _currentDraw = DrawAnnotation(
                  id: _uuid.v4(),
                  points: [details.localPosition],
                  color: state.activeTool == EditorTool.highlight
                      ? state.activeColor.withOpacity(0.4)
                      : state.activeColor,
                  strokeWidth: state.activeTool == EditorTool.highlight
                      ? state.activeStrokeWidth * 6
                      : state.activeStrokeWidth,
                  pageIndex: widget.pageIndex,
                );
              });
            }
          },
          onPanUpdate: (details) {
            if (_currentDraw != null) {
              setState(() {
                _currentDraw!.points.add(details.localPosition);
              });
            }
          },
          onPanEnd: (_) {
            if (_currentDraw != null) {
              state.addDrawAnnotation(_currentDraw!);
              setState(() => _currentDraw = null);
            }
          },
          child: CustomPaint(
            painter: _AnnotationPainter(
              drawAnnotations: drawAnns,
              currentDraw: _currentDraw,
            ),
            child: Stack(
              children: [
                // Image annotations
                ...imageAnns.map((ann) => _ImageAnnotationWidget(ann: ann)),
                // Text annotations
                ...textAnns.map((ann) => _TextAnnotationWidget(ann: ann)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  final List<DrawAnnotation> drawAnnotations;
  final DrawAnnotation? currentDraw;

  _AnnotationPainter({
    required this.drawAnnotations,
    this.currentDraw,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final all = [...drawAnnotations, if (currentDraw != null) currentDraw!];
    for (final ann in all) {
      final paint = Paint()
        ..color = ann.color
        ..strokeWidth = ann.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final pts = ann.points;
      for (int i = 0; i < pts.length - 1; i++) {
        if (pts[i] != null && pts[i + 1] != null) {
          canvas.drawLine(pts[i]!, pts[i + 1]!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_AnnotationPainter old) => true;
}

class _TextAnnotationWidget extends StatefulWidget {
  final TextAnnotation ann;

  const _TextAnnotationWidget({required this.ann});

  @override
  State<_TextAnnotationWidget> createState() => _TextAnnotationWidgetState();
}

class _TextAnnotationWidgetState extends State<_TextAnnotationWidget> {
  late Offset _position;
  bool _isSelected = false;

  @override
  void initState() {
    super.initState();
    _position = widget.ann.position;
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<PdfState>(context, listen: false);
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: () => setState(() => _isSelected = !_isSelected),
        onPanUpdate: (d) {
          setState(() => _position += d.delta);
          state.moveTextAnnotation(widget.ann.id, _position);
        },
        onDoubleTap: () => _editText(context, state),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: _isSelected
                    ? Border.all(
                        color: const Color(0xFF4FC3F7),
                        width: 1.5,
                      )
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.ann.content,
                style: TextStyle(
                  fontSize: widget.ann.fontSize,
                  color: widget.ann.color,
                  fontWeight: widget.ann.isBold
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontStyle: widget.ann.isItalic
                      ? FontStyle.italic
                      : FontStyle.normal,
                  fontFamily: widget.ann.fontFamily,
                ),
              ),
            ),
            if (_isSelected)
              Positioned(
                top: -10,
                right: -10,
                child: GestureDetector(
                  onTap: () {
                    state.removeTextAnnotation(widget.ann.id);
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE94560),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _editText(BuildContext context, PdfState state) async {
    final ctrl = TextEditingController(text: widget.ann.content);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Edit Text',
            style: GoogleFonts.inter(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.inter(color: Colors.white),
          maxLines: 5,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF16213E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7)),
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: Text('Update',
                style: GoogleFonts.inter(color: Colors.black)),
          ),
        ],
      ),
    );
    if (result != null) {
      state.updateTextAnnotation(widget.ann.id, result);
    }
  }
}

class _ImageAnnotationWidget extends StatefulWidget {
  final ImageAnnotation ann;

  const _ImageAnnotationWidget({required this.ann});

  @override
  State<_ImageAnnotationWidget> createState() => _ImageAnnotationWidgetState();
}

class _ImageAnnotationWidgetState extends State<_ImageAnnotationWidget> {
  late Offset _position;
  late double _width;
  late double _height;
  bool _isSelected = false;

  @override
  void initState() {
    super.initState();
    _position = widget.ann.position;
    _width = widget.ann.width;
    _height = widget.ann.height;
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<PdfState>(context, listen: false);
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: () => setState(() => _isSelected = !_isSelected),
        onPanUpdate: (d) {
          setState(() => _position += d.delta);
          widget.ann.position = _position;
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: _width,
              height: _height,
              decoration: BoxDecoration(
                border: _isSelected
                    ? Border.all(color: const Color(0xFF4FC3F7), width: 2)
                    : null,
              ),
              child: Image.file(
                File(widget.ann.imagePath),
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.broken_image, color: Colors.white),
                ),
              ),
            ),
            if (_isSelected) ...[
              // Delete
              Positioned(
                top: -12,
                right: -12,
                child: GestureDetector(
                  onTap: () => state.removeImageAnnotation(widget.ann.id),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE94560),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
              // Resize handle
              Positioned(
                bottom: -8,
                right: -8,
                child: GestureDetector(
                  onPanUpdate: (d) {
                    setState(() {
                      _width = (_width + d.delta.dx).clamp(50, 800);
                      _height = (_height + d.delta.dy).clamp(30, 800);
                    });
                    state.resizeImageAnnotation(
                        widget.ann.id, _width, _height);
                  },
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FC3F7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.open_in_full_rounded,
                        size: 12, color: Colors.black),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
