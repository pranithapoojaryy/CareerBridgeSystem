import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../student/domain/certificate.dart';
import '../../../student/presentation/widgets/certificate_viewer_widget.dart';

class CertificateTemplatePreviewScreen extends StatelessWidget {
  final String? courseTitle;
  final String? providerName;

  const CertificateTemplatePreviewScreen({
    super.key,
    this.courseTitle,
    this.providerName,
  });

  @override
  Widget build(BuildContext context) {
    final sampleCertificate = CourseCertificate(
      id: 'sample-preview',
      studentId: 'preview',
      courseId: 'preview',
      certificateNumber: 'EH-2026-XXXXXX',
      issuedAt: DateTime.now(),
      courseScore: 92.5,
      finalGrade: 'A+',
      providerName: providerName ?? 'Your Institution Name',
      courseTitle: courseTitle ?? 'Sample Course Title',
      studentName: 'Student Name',
      skillsAcquired: ['Skill 1', 'Skill 2', 'Skill 3', 'Skill 4'],
      isVerified: true,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          'Certificate Template Preview',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Info Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                    AppTheme.secondaryColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Certificate Template',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This is how certificates will look when students complete your course and pass the final exam.',
                    style: GoogleFonts.outfit(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    '✓',
                    'Auto-generated upon final exam completion',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('✓', 'Unique certificate ID for each student'),
                  const SizedBox(height: 8),
                  _buildInfoRow('✓', 'QR code for instant verification'),
                  const SizedBox(height: 8),
                  _buildInfoRow('✓', 'Verified badge and skills listing'),
                ],
              ),
            ),

            // Certificate Preview
            CertificateViewerWidget(
              certificate: sampleCertificate,
              onDownload: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Students can download their certificates as PDF',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),

            // Customization Info
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Certificate Details',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Course Name',
                    courseTitle ?? 'Taken from your course',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Provider',
                    providerName ?? 'Your institution name',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow('Student Name', 'Automatically filled'),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Score & Grade',
                    'Based on final exam performance',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Skills',
                    'From course "Skills Gained" field',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    'Certificate ID',
                    'Unique: EH-YYYY-XXXXXX format',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          icon,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.outfit(fontSize: 13))),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
