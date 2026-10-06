import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/certificate_service.dart';
import '../domain/certificate.dart';
import 'widgets/certificate_viewer_widget.dart';

class CertificateScreen extends StatelessWidget {
  final String studentName;
  final String courseName;
  final DateTime completionDate;
  final String certificateId;

  const CertificateScreen({
    super.key,
    required this.studentName,
    required this.courseName,
    required this.completionDate,
    required this.certificateId,
  });

  @override
  Widget build(BuildContext context) {
    // Construct a Certificate object for the viewer
    // Note: Some fields are mocked or derived since they aren't passed explicitly yet
    final certificate = CourseCertificate(
      id: certificateId,
      studentId: 'current-user', // Placeholder
      courseId: 'current-course', // Placeholder
      certificateNumber: certificateId,
      issuedAt: completionDate,
      courseScore: 100.0, // Assumed 100% since completed
      finalGrade: 'A', // Placeholder
      providerName: 'CareerBridge', // Default provider
      courseTitle: courseName,
      studentName: studentName,
      skillsAcquired: ['Course Completion'], // Placeholder
      isVerified: true,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        title: Text(
          'Course Certificate',
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
        child: CertificateViewerWidget(
          certificate: certificate,
          onDownload: () async {
            try {
              final pdfBytes = await CertificateService().generateCertificate(
                studentName: studentName,
                courseName: courseName,
                completionDate: completionDate,
                certificateId: certificateId,
              );
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: 'Certificate_$certificateId.pdf',
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error generating PDF: $e')),
              );
            }
          },
        ),
      ),
    );
  }
}
