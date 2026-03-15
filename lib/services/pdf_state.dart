import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

enum EditorTool {
  none,
  text,
  highlight,
  underline,
  strikethrough,
  draw,
  signature,
  image,
  form,
}

class TextAnnotation {
  final String id;
  String content;
  Offset position;
  double fontSize;
  Color color;
  String fontFamily;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  TextAlign alignment;
  int pageIndex;

  TextAnnotation({
    required this.id,
    required this.content,
    required this.position,
    this.fontSize = 14,
    this.color = Colors.black,
    this.fontFamily = 'Helvetica',
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.alignment = TextAlign.left,
    required this.pageIndex,
  });
}

class DrawAnnotation {
  final String id;
  List<Offset?> points;
  Color color;
  double strokeWidth;
  int pageIndex;

  DrawAnnotation({
    required this.id,
    required this.points,
    this.color = Colors.red,
    this.strokeWidth = 2.0,
    required this.pageIndex,
  });
}

class ImageAnnotation {
  final String id;
  String imagePath;
  Offset position;
  double width;
  double height;
  int pageIndex;

  ImageAnnotation({
    required this.id,
    required this.imagePath,
    required this.position,
    this.width = 150,
    this.height = 150,
    required this.pageIndex,
  });
}

class PdfState extends ChangeNotifier {
  String? currentFilePath;
  String? currentFileName;
  Uint8List? pdfBytes;
  bool isLoading = false;
  bool isModified = false;
  int currentPage = 0;
  int totalPages = 0;

  EditorTool activeTool = EditorTool.none;
  Color activeColor = Colors.red;
  double activeFontSize = 14;
  double activeStrokeWidth = 2.0;
  String activeFontFamily = 'Helvetica';
  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;
  TextAlign activeAlignment = TextAlign.left;

  List<TextAnnotation> textAnnotations = [];
  List<DrawAnnotation> drawAnnotations = [];
  List<ImageAnnotation> imageAnnotations = [];

  // Undo/redo stacks
  final List<Map<String, dynamic>> _undoStack = [];
  final List<Map<String, dynamic>> _redoStack = [];

  void setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  void loadPdf(String path, String name, Uint8List bytes, int pages) {
    currentFilePath = path;
    currentFileName = name;
    pdfBytes = bytes;
    totalPages = pages;
    currentPage = 0;
    isModified = false;
    textAnnotations.clear();
    drawAnnotations.clear();
    imageAnnotations.clear();
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  void setTool(EditorTool tool) {
    activeTool = (activeTool == tool) ? EditorTool.none : tool;
    notifyListeners();
  }

  void setColor(Color color) {
    activeColor = color;
    notifyListeners();
  }

  void setFontSize(double size) {
    activeFontSize = size;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    activeStrokeWidth = width;
    notifyListeners();
  }

  void setFontFamily(String family) {
    activeFontFamily = family;
    notifyListeners();
  }

  void setBold(bool val) {
    isBold = val;
    notifyListeners();
  }

  void setItalic(bool val) {
    isItalic = val;
    notifyListeners();
  }

  void setUnderline(bool val) {
    isUnderline = val;
    notifyListeners();
  }

  void setAlignment(TextAlign align) {
    activeAlignment = align;
    notifyListeners();
  }

  void setPage(int page) {
    currentPage = page;
    notifyListeners();
  }

  void addTextAnnotation(TextAnnotation ann) {
    _saveUndo();
    textAnnotations.add(ann);
    isModified = true;
    notifyListeners();
  }

  void updateTextAnnotation(String id, String content) {
    final idx = textAnnotations.indexWhere((a) => a.id == id);
    if (idx != -1) {
      textAnnotations[idx].content = content;
      isModified = true;
      notifyListeners();
    }
  }

  void moveTextAnnotation(String id, Offset newPos) {
    final idx = textAnnotations.indexWhere((a) => a.id == id);
    if (idx != -1) {
      textAnnotations[idx].position = newPos;
      isModified = true;
      notifyListeners();
    }
  }

  void removeTextAnnotation(String id) {
    _saveUndo();
    textAnnotations.removeWhere((a) => a.id == id);
    isModified = true;
    notifyListeners();
  }

  void addDrawAnnotation(DrawAnnotation ann) {
    _saveUndo();
    drawAnnotations.add(ann);
    isModified = true;
    notifyListeners();
  }

  void addImageAnnotation(ImageAnnotation ann) {
    _saveUndo();
    imageAnnotations.add(ann);
    isModified = true;
    notifyListeners();
  }

  void removeImageAnnotation(String id) {
    _saveUndo();
    imageAnnotations.removeWhere((a) => a.id == id);
    isModified = true;
    notifyListeners();
  }

  void resizeImageAnnotation(String id, double w, double h) {
    final idx = imageAnnotations.indexWhere((a) => a.id == id);
    if (idx != -1) {
      imageAnnotations[idx].width = w;
      imageAnnotations[idx].height = h;
      isModified = true;
      notifyListeners();
    }
  }

  void _saveUndo() {
    _undoStack.add({
      'text': List.from(textAnnotations),
      'draw': List.from(drawAnnotations),
      'image': List.from(imageAnnotations),
    });
    _redoStack.clear();
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add({
      'text': List.from(textAnnotations),
      'draw': List.from(drawAnnotations),
      'image': List.from(imageAnnotations),
    });
    final state = _undoStack.removeLast();
    textAnnotations = List.from(state['text']);
    drawAnnotations = List.from(state['draw']);
    imageAnnotations = List.from(state['image']);
    isModified = true;
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add({
      'text': List.from(textAnnotations),
      'draw': List.from(drawAnnotations),
      'image': List.from(imageAnnotations),
    });
    final state = _redoStack.removeLast();
    textAnnotations = List.from(state['text']);
    drawAnnotations = List.from(state['draw']);
    imageAnnotations = List.from(state['image']);
    notifyListeners();
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void setPdfBytes(Uint8List bytes) {
    pdfBytes = bytes;
    isModified = false;
    notifyListeners();
  }
}
