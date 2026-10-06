import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class CertificationCard extends StatelessWidget {
  final Map<String, dynamic> certification;
  final VoidCallback onTap;
  final VoidCallback onValidate;
  final VoidCallback onDelete;

  const CertificationCard({
    super.key,
    required this.certification,
    required this.onTap,
    required this.onValidate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final certificateName =
        certification['certificate_name'] ?? 'Unknown Certificate';
    final validationStatus = certification['validation_status'] ?? 'pending';
    final validationScore = certification['validation_score'] ?? 0;
    final skillPointsAwarded = certification['skill_points_awarded'] ?? 0;
    final provider = certification['certification_providers'];
    final providerName = provider?['name'] ?? 'Unknown Provider';
    final providerLogo = provider?['logo_url'];
    final trustScore = provider?['trust_score'] ?? 0;
    final issueDate = certification['issue_date'];
    final expiryDate = certification['expiry_date'];
    final extractedSkills =
        certification['extracted_skills'] as Map<String, dynamic>? ?? {};

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(validationStatus).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Status and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          validationStatus,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(validationStatus),
                            size: 12,
                            color: _getStatusColor(validationStatus),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusLabel(validationStatus),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(validationStatus),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'validate':
                            onValidate();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (validationStatus == 'pending' ||
                            validationStatus == 'rejected')
                          const PopupMenuItem(
                            value: 'validate',
                            child: Row(
                              children: [
                                Icon(Icons.refresh_rounded, size: 16),
                                SizedBox(width: 8),
                                Text('Re-validate'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                size: 16,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: const Icon(Icons.more_vert_rounded, size: 20),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Provider Info
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: providerLogo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                providerLogo,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.school_rounded,
                                  color: Colors.grey[600],
                                ),
                              ),
                            )
                          : Icon(Icons.school_rounded, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            providerName,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 12,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Trust: ${trustScore}%',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Certificate Name
                Text(
                  certificateName,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Rejection Reason (if rejected)
                if (validationStatus == 'rejected') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: Colors.red[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Reason for Rejection',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          certification['rejection_reason'] ??
                              'Your certificate cannot be verified.',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.red[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Validation Score (if validated)
                if (validationStatus == 'verified' && validationScore > 0) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Confidence: ${validationScore}%',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Skills Gained
                if (extractedSkills.isNotEmpty) ...[
                  Text(
                    'Skills Gained:',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: extractedSkills.keys.take(3).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          skill,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],

                // Points Awarded
                if (skillPointsAwarded > 0) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        size: 16,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+${skillPointsAwarded} skill points',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                const Spacer(),

                // Dates
                if (issueDate != null || expiryDate != null) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (issueDate != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Issued',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _formatDate(issueDate),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textColor,
                              ),
                            ),
                          ],
                        ),
                      if (expiryDate != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Expires',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _formatDate(expiryDate),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isExpired(expiryDate)
                                    ? Colors.red[600]
                                    : AppTheme.textColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
      case 'college_verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'unverified':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'verified':
      case 'college_verified':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.pending_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'unverified':
        return Icons.help_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'verified':
        return 'VERIFIED';
      case 'college_verified':
        return 'COLLEGE VERIFIED';
      case 'pending':
        return 'PENDING';
      case 'rejected':
        return 'REJECTED';
      case 'unverified':
        return 'UNVERIFIED';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  bool _isExpired(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }
}
