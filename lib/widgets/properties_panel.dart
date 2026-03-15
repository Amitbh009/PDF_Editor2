import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../services/pdf_state.dart';

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
              _PropBtn(
                label: 'B',
                active: state.isBold,
                onTap: () => state.setBold(!state.isBold),
                bold: true,
              ),
              const Gap(8),
              _PropBtn(
                label: 'I',
                active: state.isItalic,
                onTap: () => state.setItalic(!state.isItalic),
                italic: true,
              ),
              const Gap(8),
              _PropBtn(
                label: 'U',
                active: state.isUnderline,
                onTap: () => state.setUnderline(!state.isUnderline),
                underline: true,
              ),
              const Gap(12),
              // Alignment buttons
              _AlignBtn(
                icon: Icons.format_align_left_rounded,
                active: state.activeAlignment == TextAlign.left,
                onTap: () => state.setAlignment(TextAlign.left),
                tooltip: 'Align Left',
              ),
              const Gap(4),
              _AlignBtn(
                icon: Icons.format_align_center_rounded,
                active: state.activeAlignment == TextAlign.center,
                onTap: () => state.setAlignment(TextAlign.center),
                tooltip: 'Center',
              ),
              const Gap(4),
              _AlignBtn(
                icon: Icons.format_align_right_rounded,
                active: state.activeAlignment == TextAlign.right,
                onTap: () => state.setAlignment(TextAlign.right),
                tooltip: 'Align Right',
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
  final bool underline;

  const _PropBtn({
    required this.label,
    required this.active,
    required this.onTap,
    this.bold = false,
    this.italic = false,
    this.underline = false,
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
              decoration: underline ? TextDecoration.underline : null,
              decorationColor:
                  active ? const Color(0xFF4FC3F7) : Colors.white54,
              fontSize: 14,
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
  final String tooltip;

  const _AlignBtn({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
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
          child: Icon(
            icon,
            size: 16,
            color: active ? const Color(0xFF4FC3F7) : Colors.white54,
          ),
        ),
      ),
    );
  }
}
