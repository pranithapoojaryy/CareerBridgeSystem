import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

class BulkActionsPanel extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onSendMessage;
  final VoidCallback onExportSelected;
  final VoidCallback onAssignTest;
  final VoidCallback onClearSelection;

  const BulkActionsPanel({
    super.key,
    required this.selectedCount,
    required this.onSendMessage,
    required this.onExportSelected,
    required this.onAssignTest,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$selectedCount selected',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onSendMessage,
                  icon: const Icon(Icons.message_rounded, size: 16),
                  label: const Text('Send Message'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onAssignTest,
                  icon: const Icon(Icons.assignment_rounded, size: 16),
                  label: const Text('Assign Test'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onExportSelected,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClearSelection,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Clear selection',
          ),
        ],
      ),
    );
  }
}