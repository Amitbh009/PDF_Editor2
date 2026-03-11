import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:path_provider/path_provider.dart';

class SignaturePad extends StatefulWidget {
  final Function(String imagePath) onSigned;

  const SignaturePad({super.key, required this.onSigned});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<List<Offset?>> _strokes = [];
  List<Offset?> _currentStroke = [];
  Color _inkColor = Colors.black;
  double _strokeWidth = 2.0;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Signature',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Gap(16),
          // Canvas
          RepaintBoundary(
            key: _repaintKey,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: GestureDetector(
                onPanStart: (d) {
                  setState(() {
                    _currentStroke = [d.localPosition];
                  });
                },
                onPanUpdate: (d) {
                  setState(() {
                    _currentStroke.add(d.localPosition);
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    _strokes.add(List.from(_currentStroke));
                    _currentStroke = [];
                  });
                },
                child: CustomPaint(
                  painter: _SignaturePainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    color: _inkColor,
                    strokeWidth: _strokeWidth,
                  ),
                ),
              ),
            ),
          ),
          const Gap(16),
          // Controls
          Row(
            children: [
              // Colors
              ...[
                Colors.black,
                Colors.blue,
                const Color(0xFF1B5E20),
                Colors.red
              ].map((c) => GestureDetector(
                    onTap: () => setState(() => _inkColor = c),
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _inkColor == c
                              ? const Color(0xFF4FC3F7)
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  )),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: Text('Clear',
                    style: GoogleFonts.inter(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: Colors.white54),
                onPressed: () => setState(() {
                  _strokes.clear();
                  _currentStroke.clear();
                }),
              ),
            ],
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _strokes.isEmpty ? null : _save,
              child: Text(
                'Use Signature',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context);
        widget.onSigned(path);
      }
    } catch (e) {
      debugPrint('Signature save error: $e');
    }
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset?>> strokes;
  final List<Offset?> currentStroke;
  final Color color;
  final double strokeWidth;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset?> pts) {
      for (int i = 0; i < pts.length - 1; i++) {
        if (pts[i] != null && pts[i + 1] != null) {
          canvas.drawLine(pts[i]!, pts[i + 1]!, paint);
        }
      }
    }

    for (final stroke in strokes) drawStroke(stroke);
    drawStroke(currentStroke);
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
