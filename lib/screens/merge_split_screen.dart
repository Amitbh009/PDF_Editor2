import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import '../services/pdf_service.dart';
import '../services/pdf_state.dart';

enum MergeMode { merge, split }

class MergeSplitScreen extends StatefulWidget {
  final MergeMode mode;

  const MergeSplitScreen({super.key, required this.mode});

  @override
  State<MergeSplitScreen> createState() => _MergeSplitScreenState();
}

class _MergeSplitScreenState extends State<MergeSplitScreen> {
  List<String> _selectedFiles = [];
  Uint8List? _loadedBytes;
  int _totalPages = 0;
  String? _loadedFileName;
  bool _isProcessing = false;
  Set<int> _selectedPages = {};
  bool _selectAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          widget.mode == MergeMode.merge ? 'Merge PDFs' : 'Split PDF',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: widget.mode == MergeMode.merge
          ? _buildMergeUI()
          : _buildSplitUI(),
    );
  }

  // ─────────────────── MERGE ───────────────────

  Widget _buildMergeUI() {
    return Column(
      children: [
        Expanded(
          child: _selectedFiles.isEmpty
              ? _buildEmptyState(
                  icon: Icons.merge_type_rounded,
                  title: 'No files selected',
                  subtitle: 'Add at least 2 PDFs to merge',
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _selectedFiles.length,
                  onReorder: (oldIdx, newIdx) {
                    setState(() {
                      if (newIdx > oldIdx) newIdx--;
                      final item = _selectedFiles.removeAt(oldIdx);
                      _selectedFiles.insert(newIdx, item);
                    });
                  },
                  itemBuilder: (_, i) {
                    final path = _selectedFiles[i];
                    return _FileListItem(
                      key: ValueKey(path),
                      path: path,
                      index: i,
                      onRemove: () =>
                          setState(() => _selectedFiles.removeAt(i)),
                    );
                  },
                ),
        ),
        _buildMergeActions(),
      ],
    );
  }

  Widget _buildMergeActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: Text('Add PDFs',
                      style: GoogleFonts.inter(fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4FC3F7),
                    side: const BorderSide(color: Color(0xFF4FC3F7)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _addFiles,
                ),
              ),
            ],
          ),
          const Gap(12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.merge_type_rounded),
              label: Text(
                  _isProcessing ? 'Merging...' : 'Merge & Save',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (_selectedFiles.length >= 2 && !_isProcessing)
                  ? _merge
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── SPLIT ───────────────────

  Widget _buildSplitUI() {
    return Column(
      children: [
        if (_loadedBytes == null)
          Expanded(
            child: Center(
              child: _buildEmptyState(
                icon: Icons.call_split_rounded,
                title: 'No PDF loaded',
                subtitle: 'Open a PDF to split its pages',
                action: TextButton.icon(
                  icon: const Icon(Icons.folder_open_rounded),
                  label: Text('Open PDF',
                      style: GoogleFonts.inter(fontSize: 14)),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4FC3F7)),
                  onPressed: _loadPdfForSplit,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _loadedFileName ?? 'PDF',
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectAll = !_selectAll),
                        child: Text(
                          _selectAll ? 'Deselect All' : 'Select All',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF4FC3F7),
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _totalPages,
                    itemBuilder: (_, i) {
                      final selected = _selectAll || _selectedPages.contains(i);
                      return GestureDetector(
                        onTap: () {
                          if (_selectAll) {
                            setState(() {
                              _selectAll = false;
                              _selectedPages =
                                  Set.from(List.generate(_totalPages, (j) => j))
                                    ..remove(i);
                            });
                          } else {
                            setState(() {
                              if (_selectedPages.contains(i)) {
                                _selectedPages.remove(i);
                              } else {
                                _selectedPages.add(i);
                              }
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF4FC3F7).withOpacity(0.15)
                                : const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF4FC3F7)
                                  : Colors.white12,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_rounded,
                                color: selected
                                    ? const Color(0xFF4FC3F7)
                                    : Colors.white24,
                                size: 28,
                              ),
                              const Gap(6),
                              Text(
                                'Page ${i + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: selected
                                      ? const Color(0xFF4FC3F7)
                                      : Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        if (_loadedBytes != null) _buildSplitActions(),
      ],
    );
  }

  Widget _buildSplitActions() {
    final count = _selectAll
        ? _totalPages
        : _selectedPages.length;
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1A1A2E),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: _isProcessing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
              : const Icon(Icons.call_split_rounded),
          label: Text(
            _isProcessing
                ? 'Splitting...'
                : 'Extract $count page${count != 1 ? 's' : ''}',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB74D),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: (count > 0 && !_isProcessing) ? _split : null,
        ),
      ),
    );
  }

  // ─────────────────── ACTIONS ───────────────────

  Future<void> _addFiles() async {
    final paths = await PdfService.pickMultiplePdfs();
    if (paths.isEmpty) return;
    setState(() => _selectedFiles.addAll(paths));
  }

  Future<void> _merge() async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await PdfService.mergePdfs(_selectedFiles);
      if (bytes == null) return;
      final dir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();
      if (Platform.isAndroid && !await dir.exists()) {
        await dir.create(recursive: true);
      }
      final path =
          '${dir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await File(path).writeAsBytes(bytes);
      Fluttertoast.showToast(msg: 'Merged! Saved to $path');
      await OpenFile.open(path);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _loadPdfForSplit() async {
    final result = await PdfService.pickAndLoadPdf();
    if (result == null) return;
    setState(() {
      _loadedBytes = result['bytes'];
      _loadedFileName = result['name'];
      _totalPages = result['pages'];
      _selectedPages.clear();
    });
  }

  Future<void> _split() async {
    if (_loadedBytes == null) return;
    setState(() => _isProcessing = true);
    try {
      final pages = _selectAll
          ? List.generate(_totalPages, (i) => i)
          : _selectedPages.toList()..sort();
      final results = await PdfService.splitPdf(_loadedBytes!, pages);
      if (results == null) return;

      final dir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();
      if (Platform.isAndroid && !await dir.exists()) {
        await dir.create(recursive: true);
      }

      for (int i = 0; i < results.length; i++) {
        final path =
            '${dir.path}/page_${pages[i] + 1}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await File(path).writeAsBytes(results[i]);
      }
      Fluttertoast.showToast(
          msg: '${results.length} files saved to ${dir.path}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.white12),
        const Gap(16),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white38)),
        const Gap(8),
        Text(subtitle,
            style: GoogleFonts.inter(
                fontSize: 13, color: Colors.white24)),
        if (action != null) ...[const Gap(24), action],
      ],
    );
  }
}

class _FileListItem extends StatelessWidget {
  final String path;
  final int index;
  final VoidCallback onRemove;

  const _FileListItem({
    super.key,
    required this.path,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = path.split('/').last.split('\\').last;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('${index + 1}',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4FC3F7))),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.white),
                    overflow: TextOverflow.ellipsis),
                Text(path,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: Colors.white24),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: Colors.white38),
            onPressed: onRemove,
          ),
          const Icon(Icons.drag_handle_rounded,
              color: Colors.white24, size: 20),
        ],
      ),
    );
  }
}
