import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

class StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(bool) onSelect;
  final VoidCallback onMessage;
  final VoidCallback? onVerify;
  final VoidCallback? onDelete;

  const StudentCard({
    super.key,
    required this.student,
    required this.isSelected,
    required this.onTap,
    required this.onSelect,
    required this.onMessage,
    this.onVerify,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Extract data from the new structure - handle null student_profiles
    final studentProfile = student['student_profiles'] is List
        ? (student['student_profiles'] as List).isNotEmpty
              ? (student['student_profiles'] as List)[0]
              : null
        : student['student_profiles'];

    final usn = studentProfile?['usn'] ?? 'N/A';
    final isVerified = student['is_verified'] ?? false;

    final fullName = student['full_name'] ?? 'Unknown';
    final email = student['email'] ?? '';
    final phone = student['phone'] ?? studentProfile?['phone'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // More rounded for modern look
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16), // Reduced from 24
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (isVerified ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isVerified ? 'VERIFIED' : 'PENDING',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isVerified ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.9,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (value) => onSelect(value ?? false),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Student Avatar and Name
                Row(
                  children: [
                    Container(
                      width: 48, // Reduced from 56
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                            AppTheme.primaryColor.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                          style: GoogleFonts.outfit(
                            fontSize: 20, // Reduced from 24
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: GoogleFonts.outfit(
                              fontSize: 16, // Reduced from 18
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'USN: $usn',
                            style: GoogleFonts.outfit(
                              fontSize: 12, // Reduced from 13
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16), // Reduced from 20
                // Department and Batch
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _buildCourseInfo(),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Email & Phone
                _buildInfoTag(
                  Icons.email_outlined,
                  email.isNotEmpty ? email : 'No Email',
                ),
                const SizedBox(height: 8),
                _buildInfoTag(
                  Icons.phone_outlined,
                  phone.isNotEmpty ? phone : 'No Phone',
                ),

                const Spacer(),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onMessage,
                        icon: const Icon(Icons.message_rounded, size: 16),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.textColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey[200]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (onVerify != null) ...[
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: onVerify,
                          icon: const Icon(
                            Icons.verified_user_outlined,
                            size: 16,
                          ),
                          label: const Text('Verify'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: Colors.green,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Reject / Delete Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        tooltip: 'Reject/Remove Student',
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _buildCourseInfo() {
    final programName = student['program']?['name'];
    final departmentName = student['department']?['name'];

    // Prefer program name, fallback to department name, then 'General'
    final displayName = programName ?? departmentName ?? 'General';

    final startYear = student['batch']?['start_year'];
    final endYear = student['batch']?['end_year'];

    if (startYear != null && endYear != null) {
      return '$displayName • $startYear-${endYear.toString().substring(2)}';
    }
    return displayName;
  }
}
