import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/test_assignment.dart';

class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const SectionHeaderWidget({super.key, required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        if (onViewAll != null)
          TextButton(onPressed: onViewAll, child: const Text('View All')),
      ],
    );
  }
}

class PremiumTestCard extends StatelessWidget {
  final TestAssignment assignment;
  final VoidCallback onStart;
  final bool isRecruiter;

  const PremiumTestCard({
    super.key,
    required this.assignment,
    required this.onStart,
    this.isRecruiter = false,
  });

  @override
  Widget build(BuildContext context) {
    // Recruiter tests get a dark/Gold theme, College gets White/Blue theme
    final bgColor = isRecruiter ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isRecruiter ? Colors.white : AppTheme.textColor;
    final accentColor = isRecruiter
        ? const Color(0xFFFFD700)
        : AppTheme.primaryColor;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16), // Reduced padding
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          if (isRecruiter)
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 0),
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  isRecruiter ? 'Hiring Challenge' : 'Assessment',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
              if (assignment.isMandatory)
                Icon(
                  Icons.priority_high_rounded,
                  color: isRecruiter ? Colors.orangeAccent : Colors.orange,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 12), // Reduced spacing
          Text(
            assignment.testTitle ?? 'Untitled Assessment',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            assignment.assignedByRole.toUpperCase().replaceAll('_', ' '),
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.6),
              letterSpacing: 1,
            ),
          ),
          const Spacer(),

          Row(
            children: [
              _buildPropBadge(
                Icons.timer_outlined,
                '${assignment.durationMinutes ?? 30}m',
                textColor,
                bgColor,
              ),
              const SizedBox(width: 12),
              _buildPropBadge(
                Icons.quiz_outlined,
                '${assignment.totalQuestions ?? 20} Qs',
                textColor,
                bgColor,
              ),
            ],
          ),

          const SizedBox(height: 12), // Reduced spacing

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: assignment.isAttempted ? null : onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: assignment.isAttempted
                    ? Colors.grey.withValues(alpha: 0.3)
                    : accentColor,
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
                foregroundColor: isRecruiter ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                assignment.isAttempted
                    ? (assignment.myScore != null
                          ? 'Completed (${assignment.myScore!.toInt()}%)'
                          : 'Completed')
                    : 'Start Now',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: assignment.isAttempted ? Colors.grey : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropBadge(IconData icon, String text, Color color, Color bg) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
