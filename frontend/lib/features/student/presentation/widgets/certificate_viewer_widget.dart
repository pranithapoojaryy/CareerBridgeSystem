import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/certificate.dart';

class CertificateViewerWidget extends StatelessWidget {
  final CourseCertificate certificate;
  final VoidCallback? onDownload;

  const CertificateViewerWidget({
    super.key,
    required this.certificate,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Classic Certificate Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFFFD700), // Classic Gold
                  width: 8,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Text(
                      'CERTIFICATE',
                      style: GoogleFonts.cinzel(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A), // Dark Blue
                        letterSpacing: 8,
                      ),
                    ),
                    Text(
                      'OF COMPLETION',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700), // Gold
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Introduction
                    Text(
                      'This is to certify that',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Student Name
                    Text(
                      certificate.studentName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.greatVibes(
                        fontSize: 64,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    Container(
                      height: 2,
                      width: 200,
                      color: const Color(0xFFFFD700), // Underline
                    ),
                    const SizedBox(height: 24),

                    // Action
                    Text(
                      'has successfully completed the course',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Course Name
                    Text(
                      certificate.courseTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Issued on ${_formatDate(certificate.issuedAt)}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Footer Section (Signatures & Logos)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left: Provider
                        Expanded(
                          child: Column(
                            children: [
                              Icon(
                                Icons.school,
                                size: 40,
                                color: Color(0xFF1E3A8A),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                certificate.providerName,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                height: 1,
                                width: 100,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Course Provider',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Center: CareerBridge
                        Expanded(
                          child: Column(
                            children: [
                              Icon(
                                Icons.verified,
                                size: 40,
                                color: Color(0xFF1E3A8A),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'CareerBridge',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                height: 1,
                                width: 100,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Platform Partner',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right: QR & ID
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF1E3A8A),
                                    width: 2,
                                  ),
                                ),
                                child: QrImageView(
                                  data:
                                      'https://career-bridge-app.vercel.app/verify?id=${certificate.certificateNumber}',
                                  version: QrVersions.auto,
                                  size: 50,
                                  padding: EdgeInsets.zero,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Certificate ID:',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                certificate.certificateNumber,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded, size: 22),
                  label: Text(
                    'Download PDF',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
