import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/pdf_service.dart';
import '../services/pdf_state.dart';
import 'editor_screen.dart';
import 'merge_split_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D1A), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC3F7).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4FC3F7).withOpacity(0.4),
                  ),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: Color(0xFF4FC3F7), size: 24),
              ),
              const Gap(12),
              Text(
                'PDF Editor Pro',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
          const Gap(8),
          Text(
            'Edit, annotate, merge & sign PDFs',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white38,
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(32),
          _buildOpenButton(context),
          const Gap(24),
          Text(
            'Tools',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white38,
              letterSpacing: 1.2,
            ),
          ).animate().fadeIn(delay: 400.ms),
          const Gap(16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _ToolCard(
                  icon: Icons.edit_document,
                  title: 'Edit PDF',
                  subtitle: 'Text, images, draw',
                  color: const Color(0xFF4FC3F7),
                  delay: 500,
                  onTap: () => _openEditor(context),
                ),
                _ToolCard(
                  icon: Icons.merge_type_rounded,
                  title: 'Merge PDFs',
                  subtitle: 'Combine multiple files',
                  color: const Color(0xFF81C784),
                  delay: 600,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MergeSplitScreen(mode: MergeMode.merge),
                    ),
                  ),
                ),
                _ToolCard(
                  icon: Icons.call_split_rounded,
                  title: 'Split PDF',
                  subtitle: 'Extract pages',
                  color: const Color(0xFFFFB74D),
                  delay: 700,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MergeSplitScreen(mode: MergeMode.split),
                    ),
                  ),
                ),
                _ToolCard(
                  icon: Icons.draw_rounded,
                  title: 'Annotate',
                  subtitle: 'Highlight & comment',
                  color: const Color(0xFFE94560),
                  delay: 800,
                  onTap: () => _openEditor(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _openEditor(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4FC3F7).withOpacity(0.2),
              const Color(0xFF1565C0).withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4FC3F7).withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4FC3F7).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.folder_open_rounded,
                  color: Color(0xFF4FC3F7), size: 32),
            ),
            const Gap(20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Open PDF',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Tap to browse and open a PDF file',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF4FC3F7), size: 18),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final state = Provider.of<PdfState>(context, listen: false);
    state.setLoading(true);
    final result = await PdfService.pickAndLoadPdf();
    state.setLoading(false);

    if (result == null) return;

    state.loadPdf(
      result['path'],
      result['name'],
      result['bytes'],
      result['pages'],
    );

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Gap(4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: delay)).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
