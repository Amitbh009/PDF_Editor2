import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import '../services/pdf_state.dart';
import 'color_picker_panel.dart';

class EditorToolbar extends StatelessWidget {
  final Function(EditorTool) onToolTap;

  const EditorToolbar({super.key, required this.onToolTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfState>(
      builder: (context, state, _) {
        return Container(
          color: const Color(0xFF1A1A2E),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1, color: Colors.white10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    _ToolGroup(
                      label: 'Insert',
                      children: [
                        _ToolBtn(
                          icon: Icons.text_fields_rounded,
                          label: 'Text',
                          tool: EditorTool.text,
                          onTap: onToolTap,
                        ),
                        _ToolBtn(
                          icon: Icons.image_rounded,
                          label: 'Image',
                          tool: EditorTool.image,
                          onTap: onToolTap,
                        ),
                        _ToolBtn(
                          icon: Icons.draw_rounded,
                          label: 'Signature',
                          tool: EditorTool.signature,
                          onTap: onToolTap,
                        ),
                      ],
                    ),
                    _Divider(),
                    _ToolGroup(
                      label: 'Annotate',
                      children: [
                        _ToolBtn(
                          icon: Icons.brush_rounded,
                          label: 'Draw',
                          tool: EditorTool.draw,
                          onTap: onToolTap,
                        ),
                        _ToolBtn(
                          icon: Icons.highlight_rounded,
                          label: 'Highlight',
                          tool: EditorTool.highlight,
                          onTap: onToolTap,
                        ),
                        _ToolBtn(
                          icon: Icons.format_underline_rounded,
                          label: 'Underline',
                          tool: EditorTool.underline,
                          onTap: onToolTap,
                        ),
                        _ToolBtn(
                          icon: Icons.strikethrough_s_rounded,
                          label: 'Strike',
                          tool: EditorTool.strikethrough,
                          onTap: onToolTap,
                        ),
                      ],
                    ),
                    _Divider(),
                    _ToolGroup(
                      label: 'Forms',
                      children: [
                        _ToolBtn(
                          icon: Icons.list_alt_rounded,
                          label: 'Form',
                          tool: EditorTool.form,
                          onTap: onToolTap,
                        ),
                      ],
                    ),
                    _Divider(),
                    // Color picker
                    _ColorBtn(
                      color: state.activeColor,
                      onTap: () => _showColorPicker(context, state),
                    ),
                    const Gap(8),
                    // Stroke width
                    _StrokeSelector(
                      value: state.activeStrokeWidth,
                      onChange: state.setStrokeWidth,
                    ),
                    const Gap(8),
                    // Font size
                    _FontSizeSelector(
                      value: state.activeFontSize,
                      onChange: state.setFontSize,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
            ],
          ),
        );
      },
    );
  }

  void _showColorPicker(BuildContext context, PdfState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ColorPickerPanel(
        selectedColor: state.activeColor,
        onColorSelected: (c) {
          state.setColor(c);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ToolGroup extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _ToolGroup({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              color: Colors.white24,
              letterSpacing: 1,
            ),
          ),
        ),
        Row(children: children),
      ],
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final EditorTool tool;
  final Function(EditorTool) onTap;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.tool,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfState>(
      builder: (context, state, _) {
        final isActive = state.activeTool == tool;
        return GestureDetector(
          onTap: () => onTap(tool),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF4FC3F7).withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF4FC3F7)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isActive ? const Color(0xFF4FC3F7) : Colors.white60,
                  size: 20,
                ),
                const Gap(2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isActive ? const Color(0xFF4FC3F7) : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white10,
    );
  }
}

class _ColorBtn extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ColorBtn({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('COLOR',
              style: GoogleFonts.inter(
                  fontSize: 9, color: Colors.white24, letterSpacing: 1)),
          const Gap(4),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrokeSelector extends StatelessWidget {
  final double value;
  final Function(double) onChange;

  const _StrokeSelector({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('STROKE',
            style: GoogleFonts.inter(
                fontSize: 9, color: Colors.white24, letterSpacing: 1)),
        const Gap(4),
        DropdownButton<double>(
          value: value,
          dropdownColor: const Color(0xFF1A1A2E),
          underline: const SizedBox(),
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
          items: [1, 2, 3, 5, 8, 12]
              .map((v) => DropdownMenuItem(
                    value: v.toDouble(),
                    child: Text('${v}px'),
                  ))
              .toList(),
          onChanged: (v) => v != null ? onChange(v) : null,
        ),
      ],
    );
  }
}

class _FontSizeSelector extends StatelessWidget {
  final double value;
  final Function(double) onChange;

  const _FontSizeSelector({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('SIZE',
            style: GoogleFonts.inter(
                fontSize: 9, color: Colors.white24, letterSpacing: 1)),
        const Gap(4),
        DropdownButton<double>(
          value: value,
          dropdownColor: const Color(0xFF1A1A2E),
          underline: const SizedBox(),
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
          items: [8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 64]
              .map((v) => DropdownMenuItem(
                    value: v.toDouble(),
                    child: Text('${v}pt'),
                  ))
              .toList(),
          onChanged: (v) => v != null ? onChange(v) : null,
        ),
      ],
    );
  }
}
