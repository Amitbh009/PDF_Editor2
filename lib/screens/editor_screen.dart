import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../services/pdf_state.dart';
import '../services/pdf_service.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/annotation_layer.dart';
import '../widgets/text_editor_dialog.dart';
import '../widgets/signature_pad.dart';
import '../widgets/color_picker_panel.dart';
import '../widgets/properties_panel.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final _uuid = const Uuid();
  bool _isSaving = false;
  bool _showProperties = false;

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D0D1A),
          appBar: _buildAppBar(context, state),
          body: Column(
            children: [
              EditorToolbar(
                onToolTap: (tool) => _handleToolTap(context, state, tool),
              ),
              if (_showProperties)
                PropertiesPanel(
                  onClose: () => setState(() => _showProperties = false),
                ),
              Expanded(
                child: Stack(
                  children: [
                    _buildPdfViewer(state),
                    if (state.pdfBytes != null)
                      AnnotationLayer(
                        pageIndex: state.currentPage,
                        onTapDown: (details) =>
                            _handleCanvasTap(context, state, details),
                      ),
                    if (state.isLoading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
              _buildBottomBar(state),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, PdfState state) {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => _confirmBack(context, state),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.currentFileName ?? 'PDF Editor',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          if (state.isModified)
            Text(
              'Unsaved changes',
              style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFFFFB74D)),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.undo_rounded,
              color: state.canUndo ? Colors.white : Colors.white24),
          onPressed: state.canUndo ? state.undo : null,
          tooltip: 'Undo',
        ),
        IconButton(
          icon: Icon(Icons.redo_rounded,
              color: state.canRedo ? Colors.white : Colors.white24),
          onPressed: state.canRedo ? state.redo : null,
          tooltip: 'Redo',
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          onPressed: () => setState(() => _showProperties = !_showProperties),
          tooltip: 'Properties',
        ),
        _isSaving
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                color: const Color(0xFF1A1A2E),
                onSelected: (val) => _handleMenu(context, state, val),
                itemBuilder: (_) => [
                  _menuItem('save', Icons.save_rounded, 'Save'),
                  _menuItem('save_as', Icons.save_as_rounded, 'Save As'),
                  _menuItem('share', Icons.share_rounded, 'Share'),
                  const PopupMenuDivider(),
                  _menuItem('merge', Icons.merge_type_rounded, 'Merge PDFs'),
                ],
              ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF4FC3F7)),
          const Gap(12),
          Text(label,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPdfViewer(PdfState state) {
    if (state.pdfBytes == null) {
      return const Center(
        child: Text('No PDF loaded', style: TextStyle(color: Colors.white38)),
      );
    }
    return SfPdfViewer.memory(
      state.pdfBytes!,
      key: _pdfViewerKey,
      controller: _pdfController,
      pageLayoutMode: PdfPageLayoutMode.single,
      scrollDirection: PdfScrollDirection.horizontal,
      canShowScrollHead: false,
      canShowScrollStatus: false,
      onPageChanged: (details) {
        state.setPage(details.newPageNumber - 1);
      },
    );
  }

  Widget _buildBottomBar(PdfState state) {
    if (state.pdfBytes == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1A1A2E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: state.currentPage > 0
                ? () => _pdfController.previousPage()
                : null,
            color: Colors.white,
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page ${state.currentPage + 1} of ${state.totalPages}',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
            ),
          ),
          const Gap(8),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: state.currentPage < state.totalPages - 1
                ? () => _pdfController.nextPage()
                : null,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  void _handleToolTap(
      BuildContext context, PdfState state, EditorTool tool) async {
    if (tool == EditorTool.image) {
      await _pickAndAddImage(context, state);
      return;
    }
    if (tool == EditorTool.signature) {
      _showSignaturePad(context, state);
      return;
    }
    state.setTool(tool);
  }

  void _handleCanvasTap(BuildContext context, PdfState state,
      TapDownDetails details) async {
    final pos = details.localPosition;
    switch (state.activeTool) {
      case EditorTool.text:
        _showTextDialog(context, state, pos);
        break;
      default:
        break;
    }
  }

  void _showTextDialog(
      BuildContext context, PdfState state, Offset position) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => TextEditorDialog(
        initialText: '',
        initialFontSize: state.activeFontSize,
        initialColor: state.activeColor,
        initialBold: state.isBold,
        initialItalic: state.isItalic,
        initialFont: state.activeFontFamily,
      ),
    );
    if (result == null) return;

    state.addTextAnnotation(TextAnnotation(
      id: _uuid.v4(),
      content: result['text'],
      position: position,
      fontSize: result['fontSize'],
      color: result['color'],
      isBold: result['bold'],
      isItalic: result['italic'],
      fontFamily: result['font'],
      pageIndex: state.currentPage,
    ));
  }

  Future<void> _pickAndAddImage(BuildContext context, PdfState state) async {
    String? imagePath;

    // FIX: Use file_picker on desktop (Windows), image_picker on mobile
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      imagePath = picked?.path;
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: false,
      );
      imagePath = result?.files.first.path;
    }

    if (imagePath == null) return;

    state.addImageAnnotation(ImageAnnotation(
      id: _uuid.v4(),
      imagePath: imagePath,
      position: const Offset(50, 50),
      pageIndex: state.currentPage,
    ));
  }

  void _showSignaturePad(BuildContext context, PdfState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SignaturePad(
        onSigned: (imagePath) {
          state.addImageAnnotation(ImageAnnotation(
            id: _uuid.v4(),
            imagePath: imagePath,
            position: const Offset(50, 50),
            width: 200,
            height: 80,
            pageIndex: state.currentPage,
          ));
        },
      ),
    );
  }

  Future<void> _handleMenu(
      BuildContext context, PdfState state, String action) async {
    switch (action) {
      case 'save':
      case 'save_as':
        setState(() => _isSaving = true);
        await PdfService.savePdf(state);
        setState(() => _isSaving = false);
        break;
      case 'share':
        await PdfService.sharePdf(state);
        break;
      case 'merge':
        // FIX: use named route registered in main.dart
        if (context.mounted) {
          Navigator.pushNamed(context, '/merge');
        }
        break;
    }
  }

  Future<void> _confirmBack(BuildContext context, PdfState state) async {
    if (!state.isModified) {
      Navigator.pop(context);
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Unsaved Changes',
            style: GoogleFonts.inter(color: Colors.white)),
        content: Text(
          'You have unsaved changes. Save before leaving?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Discard',
                style: GoogleFonts.inter(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              await PdfService.savePdf(state);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: Text('Save',
                style: GoogleFonts.inter(color: const Color(0xFF4FC3F7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7)),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Leave',
                style: GoogleFonts.inter(color: Colors.black)),
          ),
        ],
      ),
    );
    if ((result ?? false) && context.mounted) {
      Navigator.pop(context);
    }
  }
}
