import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../services/pdf_state.dart';

class ColorPickerPanel extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const ColorPickerPanel({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const _presets = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.brown,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Color',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const Gap(16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _presets
                .map((c) => GestureDetector(
                      onTap: () => onColorSelected(c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == c
                                ? const Color(0xFF4FC3F7)
                                : Colors.white12,
                            width: 2.5,
                          ),
                        ),
                        child: selectedColor == c
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    ))
                .toList(),
          ),
          const Gap(16),
          ElevatedButton.icon(
            icon: const Icon(Icons.colorize_rounded, size: 18),
            label: Text('Custom Color',
                style: GoogleFonts.inter(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16213E),
              foregroundColor: Colors.white70,
            ),
            onPressed: () => _showCustomPicker(context),
          ),
        ],
      ),
    );
  }

  void _showCustomPicker(BuildContext context) {
    Color temp = selectedColor;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Custom Color',
            style: GoogleFonts.inter(color: Colors.white)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (c) => temp = c,
            enableAlpha: true,
            labelTypes: const [],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              onColorSelected(temp);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7)),
            child: Text('Select',
                style: GoogleFonts.inter(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class PropertiesPanel extends StatelessWidget {
  final VoidCallback onClose;

  const PropertiesPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfState>(
      builder: (context, state, _) {
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF16213E),
          child: Row(
            children: [
              Text('Properties',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70)),
              const Gap(16),
              // Bold toggle
              _PropBtn(
                label: 'B',
                active: state.isBold,
                onTap: () {
                  state.isBold = !state.isBold;
                  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                  state.notifyListeners();
                },
                bold: true,
              ),
              const Gap(8),
              _PropBtn(
                label: 'I',
                active: state.isItalic,
                onTap: () {
                  state.isItalic = !state.isItalic;
                  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                  state.notifyListeners();
                },
                italic: true,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close,
                    size: 18, color: Colors.white38),
                onPressed: onClose,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PropBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool bold;
  final bool italic;

  const _PropBtn({
    required this.label,
    required this.active,
    required this.onTap,
    this.bold = false,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF4FC3F7).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? const Color(0xFF4FC3F7) : Colors.white12,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF4FC3F7) : Colors.white54,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
