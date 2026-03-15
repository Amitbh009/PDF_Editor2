import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TextEditorDialog extends StatefulWidget {
  final String initialText;
  final double initialFontSize;
  final Color initialColor;
  final bool initialBold;
  final bool initialItalic;
  final bool initialUnderline;
  final String initialFont;
  final TextAlign initialAlignment;

  const TextEditorDialog({
    super.key,
    required this.initialText,
    required this.initialFontSize,
    required this.initialColor,
    required this.initialBold,
    required this.initialItalic,
    this.initialUnderline = false,
    required this.initialFont,
    this.initialAlignment = TextAlign.left,
  });

  @override
  State<TextEditorDialog> createState() => _TextEditorDialogState();
}

class _TextEditorDialogState extends State<TextEditorDialog> {
  late TextEditingController _textCtrl;
  late double _fontSize;
  late Color _color;
  late bool _bold;
  late bool _italic;
  late bool _underline;
  late String _font;
  late TextAlign _alignment;

  final _fonts = ['Helvetica', 'Times New Roman', 'Courier'];

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.initialText);
    _fontSize = widget.initialFontSize;
    _color = widget.initialColor;
    _bold = widget.initialBold;
    _italic = widget.initialItalic;
    _underline = widget.initialUnderline;
    _font = widget.initialFont;
    _alignment = widget.initialAlignment;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Text',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const Gap(16),
            TextField(
              controller: _textCtrl,
              style: TextStyle(
                color: Colors.white,
                fontSize: _fontSize,
                fontWeight: _bold ? FontWeight.bold : FontWeight.normal,
                fontStyle: _italic ? FontStyle.italic : FontStyle.normal,
                decoration:
                    _underline ? TextDecoration.underline : TextDecoration.none,
                decorationColor: _color,
              ),
              textAlign: _alignment,
              maxLines: 5,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter text...',
                hintStyle: GoogleFonts.inter(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF16213E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF4FC3F7), width: 1.5),
                ),
              ),
            ),
            const Gap(16),
            // Font family
            Row(
              children: [
                Text('Font:',
                    style:
                        GoogleFonts.inter(fontSize: 13, color: Colors.white60)),
                const Gap(12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _font,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF16213E),
                    underline: const SizedBox(),
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.white),
                    items: _fonts
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f),
                            ))
                        .toList(),
                    onChanged: (v) => v != null
                        ? setState(() => _font = v)
                        : null,
                  ),
                ),
              ],
            ),
            const Gap(8),
            // Font size and style
            Row(
              children: [
                Text('Size:',
                    style:
                        GoogleFonts.inter(fontSize: 13, color: Colors.white60)),
                const Gap(8),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 8,
                    max: 72,
                    divisions: 32,
                    activeColor: const Color(0xFF4FC3F7),
                    label: '${_fontSize.toInt()}pt',
                    onChanged: (v) => setState(() => _fontSize = v),
                  ),
                ),
                Text('${_fontSize.toInt()}pt',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.white38)),
              ],
            ),
            const Gap(8),
            Row(
              children: [
                _StyleBtn(
                  label: 'B',
                  active: _bold,
                  bold: true,
                  onTap: () => setState(() => _bold = !_bold),
                ),
                const Gap(8),
                _StyleBtn(
                  label: 'I',
                  active: _italic,
                  italic: true,
                  onTap: () => setState(() => _italic = !_italic),
                ),
                const Gap(8),
                _StyleBtn(
                  label: 'U',
                  active: _underline,
                  underline: true,
                  onTap: () => setState(() => _underline = !_underline),
                ),
                const Gap(16),
                GestureDetector(
                  onTap: () => _pickColor(context),
                  child: Row(
                    children: [
                      Text('Color: ',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.white60)),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(12),
            // Alignment buttons
            Row(
              children: [
                Text('Align:',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.white60)),
                const Gap(12),
                _AlignBtn(
                  icon: Icons.format_align_left_rounded,
                  active: _alignment == TextAlign.left,
                  onTap: () => setState(() => _alignment = TextAlign.left),
                ),
                const Gap(6),
                _AlignBtn(
                  icon: Icons.format_align_center_rounded,
                  active: _alignment == TextAlign.center,
                  onTap: () => setState(() => _alignment = TextAlign.center),
                ),
                const Gap(6),
                _AlignBtn(
                  icon: Icons.format_align_right_rounded,
                  active: _alignment == TextAlign.right,
                  onTap: () => setState(() => _alignment = TextAlign.right),
                ),
              ],
            ),
            const Gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: GoogleFonts.inter(color: Colors.white38)),
                ),
                const Gap(8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FC3F7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: _textCtrl.text.isNotEmpty
                      ? () => Navigator.pop(context, {
                            'text': _textCtrl.text,
                            'fontSize': _fontSize,
                            'color': _color,
                            'bold': _bold,
                            'italic': _italic,
                            'underline': _underline,
                            'font': _font,
                            'alignment': _alignment,
                          })
                      : null,
                  child: Text('Add',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, color: Colors.black)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _pickColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Pick Color',
            style: GoogleFonts.inter(color: Colors.white)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _color,
            onColorChanged: (c) => setState(() => _color = c),
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7)),
            child: Text('Done',
                style: GoogleFonts.inter(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class _StyleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final bool bold;
  final bool italic;
  final bool underline;
  final VoidCallback onTap;

  const _StyleBtn({
    required this.label,
    required this.active,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF4FC3F7).withOpacity(0.2)
              : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? const Color(0xFF4FC3F7)
                : Colors.white12,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF4FC3F7) : Colors.white54,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              decoration: underline ? TextDecoration.underline : null,
              decorationColor:
                  active ? const Color(0xFF4FC3F7) : Colors.white54,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _AlignBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _AlignBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF4FC3F7).withOpacity(0.2)
              : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? const Color(0xFF4FC3F7) : Colors.white12,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? const Color(0xFF4FC3F7) : Colors.white54,
        ),
      ),
    );
  }
}
