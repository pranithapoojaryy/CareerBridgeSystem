import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class CertificateService {
  Future<Uint8List> generateCertificate({
    required String studentName,
    required String courseName,
    required DateTime completionDate,
    required String certificateId,
  }) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('MMMM d, yyyy').format(completionDate);

    // Load Fonts
    final fontCinzel = await PdfGoogleFonts.cinzelBold();
    final fontGreatVibes = await PdfGoogleFonts.greatVibesRegular();
    final fontPlayfair = await PdfGoogleFonts.playfairDisplayBold();
    final fontOutfit = await PdfGoogleFonts.outfitRegular();
    final fontOutfitBold = await PdfGoogleFonts.outfitBold();

    // Classic Colors
    final goldColor = PdfColor.fromInt(0xFFFFD700);
    final darkBlue = PdfColor.fromInt(0xFF1E3A8A);
    final greyShade = PdfColor.fromInt(0xFF757575); // Grey 600 approx

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(16), // Match widget margin
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(color: PdfColors.white),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12), // Reduced from 24
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: goldColor, width: 8),
              ),
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20, // Reduced from 40
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColor(
                      goldColor.red,
                      goldColor.green,
                      goldColor.blue,
                      0.3,
                    ), // 0.3 opacity simulated
                    width: 2,
                  ),
                ),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.max, // Changed to max
                  children: [
                    // Header
                    pw.Text(
                      'CERTIFICATE',
                      style: pw.TextStyle(
                        font: fontCinzel,
                        fontSize: 36, // Reduced from 40
                        fontWeight: pw.FontWeight.bold,
                        color: darkBlue,
                        letterSpacing: 8,
                      ),
                    ),
                    pw.Text(
                      'OF COMPLETION',
                      style: pw.TextStyle(
                        font: fontOutfitBold,
                        fontSize: 12, // Reduced from 14
                        fontWeight: pw.FontWeight.bold,
                        color: goldColor,
                        letterSpacing: 4,
                      ),
                    ),
                    pw.SizedBox(height: 32), // Reduced from 48
                    // Introduction
                    pw.Text(
                      'This is to certify that',
                      style: pw.TextStyle(
                        font: fontOutfit,
                        fontSize: 14, // Reduced from 16
                        color: greyShade,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.SizedBox(height: 12), // Reduced from 16
                    // Student Name
                    pw.Text(
                      studentName,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: fontGreatVibes,
                        fontSize: 56, // Reduced from 64
                        color: darkBlue,
                      ),
                    ),
                    pw.Container(height: 2, width: 200, color: goldColor),
                    pw.SizedBox(height: 20), // Reduced from 24
                    // Action
                    pw.Text(
                      'has successfully completed the course',
                      style: pw.TextStyle(
                        font: fontOutfit,
                        fontSize: 14, // Reduced from 16
                        color: greyShade,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.SizedBox(height: 20), // Reduced from 24
                    // Course Name
                    pw.Text(
                      courseName,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: fontPlayfair,
                        fontSize: 28, // Reduced from 32
                        fontWeight: pw.FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                    pw.SizedBox(height: 12), // Reduced from 16
                    pw.Text(
                      'Issued on $dateStr',
                      style: pw.TextStyle(
                        font: fontOutfitBold,
                        fontSize: 12, // Reduced from 14
                        color: greyShade,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    pw.Spacer(), // Replaced fixed SizedBox with Spacer
                    // Footer Section
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // Left: Provider
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              // Icon: School
                              pw.SvgImage(
                                svg: '''
                                 <svg viewBox="0 0 24 24">
                                   <path fill="#1E3A8A" d="M5 13.18v4L12 21l7-3.82v-4L12 17l-7-3.82zM12 3L1 9l11 6 9-4.91V17h2V9L12 3z"/>
                                 </svg>
                               ''',
                                width: 40,
                                height: 40,
                              ),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                'Provider', // Placeholder
                                style: pw.TextStyle(
                                  font: fontOutfitBold,
                                  fontWeight: pw.FontWeight.bold,
                                  color: darkBlue,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.Container(
                                margin: const pw.EdgeInsets.only(top: 8),
                                height: 1,
                                width: 100,
                                color: PdfColors.grey400,
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Course Provider',
                                style: pw.TextStyle(
                                  font: fontOutfit,
                                  fontSize: 10,
                                  color: greyShade,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Center: CareerBridge
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              // Icon: Verified
                              pw.SvgImage(
                                svg: '''
                                 <svg viewBox="0 0 24 24">
                                   <path fill="#1E3A8A" d="M23 12l-2.44-2.78.34-3.68-3.61-.82-1.89-3.18L12 3 8.6 1.54 6.71 4.72l-3.61.81.34 3.68L1 12l2.44 2.78-.34 3.69 3.61.82 1.89 3.18L12 21l3.4 1.46 1.89-3.18 3.61-.82-.34-3.68L23 12zm-10 5l-4-4 1.41-1.41L10 14.17l6.59-6.59L18 9l-8 8z"/>
                                 </svg>
                               ''',
                                width: 40,
                                height: 40,
                              ),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                'CareerBridge',
                                style: pw.TextStyle(
                                  font: fontOutfitBold,
                                  fontWeight: pw.FontWeight.bold,
                                  color: darkBlue,
                                ),
                              ),
                              pw.Container(
                                margin: const pw.EdgeInsets.only(top: 8),
                                height: 1,
                                width: 100,
                                color: PdfColors.grey400,
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Platform Partner',
                                style: pw.TextStyle(
                                  font: fontOutfit,
                                  fontSize: 10,
                                  color: greyShade,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right: QR & ID
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.all(4),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(
                                    color: darkBlue,
                                    width: 2,
                                  ),
                                ),
                                child: pw.BarcodeWidget(
                                  data:
                                      'https://CareerBridge.com/verify/$certificateId',
                                  barcode: pw.Barcode.qrCode(),
                                  width: 50,
                                  height: 50,
                                  color: darkBlue,
                                  drawText: false,
                                ),
                              ),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                'Certificate ID:',
                                style: pw.TextStyle(
                                  font: fontOutfit,
                                  fontSize: 10,
                                  color: greyShade,
                                ),
                              ),
                              pw.Text(
                                certificateId,
                                style: pw.TextStyle(
                                  font: fontOutfitBold,
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: darkBlue,
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
          );
        },
      ),
    );

    return pdf.save();
  }
}
