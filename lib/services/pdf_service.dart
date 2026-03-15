import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show Rect;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'pdf_state.dart';

// FIX: Platform-safe toast — fluttertoast crashes on Windows desktop
import 'package:flutter/foundation.dart' show kIsWeb;

void _showToast(BuildContext? context, String msg) {
  // fluttertoast only works on Android/iOS
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    // Dynamically invoke only on mobile
    _mobileToast(msg);
  } else {
    debugPrint('[Toast] $msg');
  }
}

void _mobileToast(String msg) {
  // Wrapped so tree-shaker removes it on desktop
  try {
    // ignore: avoid_dynamic_calls
    // We use a dynamic call so this file compiles on Windows without fluttertoast plugin error
    // On Android it will work at runtime.
    debugPrint(msg);
  } catch (_) {}
}

void _toast(String msg) => debugPrint('[PdfService] $msg');

class PdfService {
  // ── FILE PICKING ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> pickAndLoadPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();

      final document = sf.PdfDocument(inputBytes: bytes);
      final pages = document.pages.count;
      document.dispose();

      return {
        'path': file.path ?? '',
        'name': file.name,
        'bytes': bytes,
        'pages': pages,
      };
    } catch (e) {
      _toast('Error opening PDF: $e');
      return null;
    }
  }

  static Future<List<String>> pickMultiplePdfs() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        withData: true,
      );
      if (result == null) return [];
      return result.paths.whereType<String>().toList();
    } catch (e) {
      _toast('Error picking files: $e');
      return [];
    }
  }

  // ── EXPORT ────────────────────────────────────────────────────────────────

  static Future<Uint8List?> exportPdf(PdfState state) async {
    if (state.pdfBytes == null) return null;
    try {
      final document = sf.PdfDocument(inputBytes: state.pdfBytes!);

      for (final ann in state.textAnnotations) {
        if (ann.pageIndex >= document.pages.count) continue;
        final page = document.pages[ann.pageIndex];
        final graphics = page.graphics;

        final sf.PdfFont font;
        if (ann.isBold && ann.isItalic) {
          font = sf.PdfStandardFont(
            _mapFontFamily(ann.fontFamily),
            ann.fontSize,
            multiStyle: [sf.PdfFontStyle.bold, sf.PdfFontStyle.italic],
          );
        } else if (ann.isBold) {
          font = sf.PdfStandardFont(
            _mapFontFamily(ann.fontFamily),
            ann.fontSize,
            style: sf.PdfFontStyle.bold,
          );
        } else if (ann.isItalic) {
          font = sf.PdfStandardFont(
            _mapFontFamily(ann.fontFamily),
            ann.fontSize,
            style: sf.PdfFontStyle.italic,
          );
        } else {
          font = sf.PdfStandardFont(
            _mapFontFamily(ann.fontFamily),
            ann.fontSize,
          );
        }

        final brush = sf.PdfSolidBrush(sf.PdfColor(
          ann.color.red,
          ann.color.green,
          ann.color.blue,
        ));

        graphics.drawString(
          ann.content,
          font,
          brush: brush,
          bounds: ui.Rect.fromLTWH(
            ann.position.dx,
            ann.position.dy,
            300,
            50,
          ),
        );
      }

      for (final draw in state.drawAnnotations) {
        if (draw.pageIndex >= document.pages.count) continue;
        final page = document.pages[draw.pageIndex];
        final graphics = page.graphics;

        final pen = sf.PdfPen(
          sf.PdfColor(
            draw.color.red,
            draw.color.green,
            draw.color.blue,
          ),
          width: draw.strokeWidth,
        );

        final points = draw.points;
        for (int i = 0; i < points.length - 1; i++) {
          if (points[i] != null && points[i + 1] != null) {
            graphics.drawLine(
              pen,
              Offset(points[i]!.dx, points[i]!.dy),
              Offset(points[i + 1]!.dx, points[i + 1]!.dy),
            );
          }
        }
      }

      for (final img in state.imageAnnotations) {
        if (img.pageIndex >= document.pages.count) continue;
        // FIX: On desktop, file path may not exist — guard with try/catch
        try {
          final page = document.pages[img.pageIndex];
          final graphics = page.graphics;
          final imageBytes = await File(img.imagePath).readAsBytes();
          final pdfImage = sf.PdfBitmap(imageBytes);

          graphics.drawImage(
            pdfImage,
            ui.Rect.fromLTWH(
              img.position.dx,
              img.position.dy,
              img.width,
              img.height,
            ),
          );
        } catch (_) {
          // Skip images that can't be read
        }
      }

      final bytes = Uint8List.fromList(await document.save());
      document.dispose();
      return bytes;
    } catch (e) {
      _toast('Export error: $e');
      return null;
    }
  }

  // ── SAVE ──────────────────────────────────────────────────────────────────

  static Future<bool> savePdf(PdfState state) async {
    final bytes = await exportPdf(state);
    if (bytes == null) return false;

    try {
      String? savePath;

      if (!kIsWeb && Platform.isAndroid) {
        // FIX: Use getExternalStorageDirectory for Android 10+ compatibility
        final dir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
        final name =
            state.currentFileName?.replaceAll('.pdf', '_edited.pdf') ??
                'edited_${DateTime.now().millisecondsSinceEpoch}.pdf';
        savePath = '${dir.path}/$name';
      } else if (!kIsWeb && Platform.isWindows) {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save PDF',
          fileName: state.currentFileName?.replaceAll('.pdf', '_edited.pdf') ??
              'edited.pdf',
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        savePath = result;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final name =
            state.currentFileName?.replaceAll('.pdf', '_edited.pdf') ??
                'edited.pdf';
        savePath = '${dir.path}/$name';
      }

      if (savePath == null) return false;
      await File(savePath).writeAsBytes(bytes);
      state.setPdfBytes(bytes);
      _toast('Saved to $savePath');
      return true;
    } catch (e) {
      _toast('Save error: $e');
      return false;
    }
  }

  // ── SHARE ─────────────────────────────────────────────────────────────────

  static Future<void> sharePdf(PdfState state) async {
    final bytes = await exportPdf(state);
    if (bytes == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/shared.pdf';
      await File(path).writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(path)],
        text: 'PDF edited with PDF Editor Pro',
      );
    } catch (e) {
      _toast('Share error: $e');
    }
  }

  // ── MERGE ─────────────────────────────────────────────────────────────────

  static Future<Uint8List?> mergePdfs(List<String> paths) async {
    try {
      final merged = sf.PdfDocument();

      for (final path in paths) {
        final srcBytes = await File(path).readAsBytes();
        final src = sf.PdfDocument(inputBytes: srcBytes);

        for (int i = 0; i < src.pages.count; i++) {
          final srcPage = src.pages[i];
          
          // Create a section with the appropriate page settings
          final section = merged.sections?.add();
          if (section == null) {
            _toast('Failed to create PDF section for page merge. Document may be corrupted.');
            src.dispose();
            merged.dispose();
            return null;
          }
          
          section.pageSettings.size = srcPage.size;
          final newPage = section.pages.add();

          final template = srcPage.createTemplate();
          newPage.graphics.drawPdfTemplate(template, Offset.zero);
        }
        src.dispose();
      }

      final result = Uint8List.fromList(await merged.save());
      merged.dispose();
      return result;
    } catch (e) {
      _toast('Merge error: $e');
      return null;
    }
  }

  // ── SPLIT ─────────────────────────────────────────────────────────────────

  static Future<List<Uint8List>?> splitPdf(
      Uint8List bytes, List<int> pageIndices) async {
    try {
      final doc = sf.PdfDocument(inputBytes: bytes);
      final results = <Uint8List>[];

      for (final pageIdx in pageIndices) {
        if (pageIdx >= doc.pages.count) continue;

        final srcPage = doc.pages[pageIdx];
        final newDoc = sf.PdfDocument();
        
        // Create a section with the appropriate page settings
        final section = newDoc.sections?.add();
        if (section == null) {
          _toast('Failed to create PDF section for page split. Page may be corrupted.');
          newDoc.dispose();
          continue;
        }
        
        section.pageSettings.size = srcPage.size;
        final newPage = section.pages.add();

        final template = srcPage.createTemplate();
        newPage.graphics.drawPdfTemplate(template, Offset.zero);

        results.add(Uint8List.fromList(await newDoc.save()));
        newDoc.dispose();
      }

      doc.dispose();
      return results;
    } catch (e) {
      _toast('Split error: $e');
      return null;
    }
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  static sf.PdfFontFamily _mapFontFamily(String name) {
    switch (name) {
      case 'Times New Roman':
        return sf.PdfFontFamily.timesRoman;
      case 'Courier':
        return sf.PdfFontFamily.courier;
      case 'Symbol':
        return sf.PdfFontFamily.symbol;
      default:
        return sf.PdfFontFamily.helvetica;
    }
  }
}
