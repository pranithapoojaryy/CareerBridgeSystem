import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_theme.dart';

/// Job Drive Card - Displays individual job posting with recruiter-side aesthetic
class JobDriveCard extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobDriveCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final status = job['status'] ?? 'open';
    final statusColor = status == 'open'
        ? Colors.green
        : (status == 'closed' ? Colors.red : Colors.grey);

    final title = job['title'] ?? 'Untitled Job';
    final company = job['organization']?['name'] ?? 'Unknown Company';
    final logoUrl = job['organization']?['logo_url'];
    final location = job['location'] ?? 'Not specified';
    final jobType = job['job_type'] ?? 'Full-time';
    final date = DateTime.tryParse(job['created_at'] ?? '') ?? DateTime.now();

    // Parse application count from Supabase count aggregate
    int applicationCount = 0;
    final apps = job['applications'];
    if (apps is List && apps.isNotEmpty) {
      applicationCount = apps[0]['count'] ?? 0;
    } else if (apps is Map) {
      applicationCount = apps['count'] ?? 0;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Small logo in header
                    if (logoUrl != null && logoUrl.isNotEmpty)
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: NetworkImage(logoUrl),
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.business,
                          size: 14,
                          color: statusColor,
                        ),
                      ),
                    Text(
                      company.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  status.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.textColor,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (applicationCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$applicationCount App',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Grid Style Fields
                  _buildGridField(
                    'Location',
                    location,
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildGridField('Type', jobType, Icons.work_outline_rounded),
                  const SizedBox(height: 8),
                  _buildGridField(
                    'Posted On',
                    DateFormat('MMM d, yyyy').format(date),
                    Icons.calendar_today_outlined,
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),

          // Subtle Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade50)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  status == 'open'
                      ? 'Drive Status: Active'
                      : 'Drive Status: Closed',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
