import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class StudentExportService {
  Future<Uint8List> generateStudentReport({
    required List<Map<String, dynamic>> students,
    required String collegeName,
    String? reportTitle,
  }) async {
    final pdf = pw.Document();

    // Load Fonts
    final fontOutfit = await PdfGoogleFonts.outfitRegular();
    final fontOutfitBold = await PdfGoogleFonts.outfitBold();

    // Colors from AppTheme
    final primaryColor = PdfColor.fromInt(0xFF6EC9F5);
    final secondaryColor = PdfColor.fromInt(0xFF4A90E2);
    final textColor = PdfColor.fromInt(0xFF2D3748);
    final greyColor = PdfColor.fromInt(0xFF718096);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        collegeName.toUpperCase(),
                        style: pw.TextStyle(
                          font: fontOutfitBold,
                          fontSize: 18,
                          color: secondaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        reportTitle ?? 'Student Management Report',
                        style: pw.TextStyle(
                          font: fontOutfitBold,
                          fontSize: 24,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Generated on',
                        style: pw.TextStyle(
                          font: fontOutfit,
                          fontSize: 10,
                          color: greyColor,
                        ),
                      ),
                      pw.Text(
                        DateFormat('MMM d, yyyy').format(DateTime.now()),
                        style: pw.TextStyle(
                          font: fontOutfitBold,
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: primaryColor, thickness: 2),
              pw.SizedBox(height: 24),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'CareerBridge - Campus Placement Platform',
                    style: pw.TextStyle(
                      font: fontOutfit,
                      fontSize: 10,
                      color: greyColor,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(
                      font: fontOutfit,
                      fontSize: 10,
                      color: greyColor,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Stats Row
            pw.Row(
              children: [
                _buildStatItem(
                  'Total Students',
                  students.length.toString(),
                  fontOutfit,
                  fontOutfitBold,
                  secondaryColor,
                ),
                pw.SizedBox(width: 24),
                _buildStatItem(
                  'Avg CGPA',
                  _calculateAvgCgpa(students),
                  fontOutfit,
                  fontOutfitBold,
                  const PdfColor.fromInt(0xFF48BB78), // Green
                ),
                pw.SizedBox(width: 24),
                _buildStatItem(
                  'Placed',
                  _countPlaced(students),
                  fontOutfit,
                  fontOutfitBold,
                  const PdfColor.fromInt(0xFFECC94B), // Yellow/Gold
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // Students Table
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(3), // Name
                1: const pw.FlexColumnWidth(2), // USN
                2: const pw.FlexColumnWidth(2), // Dept
                3: const pw.FlexColumnWidth(1), // CGPA
                4: const pw.FlexColumnWidth(2), // Status
              },
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              children: [
                // Table Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell(
                      'Student Name',
                      fontOutfitBold,
                      isHeader: true,
                    ),
                    _buildTableCell('USN', fontOutfitBold, isHeader: true),
                    _buildTableCell(
                      'Department',
                      fontOutfitBold,
                      isHeader: true,
                    ),
                    _buildTableCell('CGPA', fontOutfitBold, isHeader: true),
                    _buildTableCell('Status', fontOutfitBold, isHeader: true),
                  ],
                ),
                // Table Rows
                ...students.map((student) {
                  final profile = _getProfile(student);
                  return pw.TableRow(
                    children: [
                      _buildTableCell(
                        student['full_name'] ?? 'N/A',
                        fontOutfit,
                      ),
                      _buildTableCell(profile['usn'] ?? 'N/A', fontOutfit),
                      _buildTableCell(
                        student['department']?['name'] ?? 'N/A',
                        fontOutfit,
                      ),
                      _buildTableCell(
                        (profile['cgpa'] ?? 0.0).toStringAsFixed(2),
                        fontOutfit,
                      ),
                      _buildTableCell(
                        profile['placement_status']?.toString().toUpperCase() ??
                            'SEEKING',
                        fontOutfit,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildStatItem(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold,
    PdfColor color,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColor(color.red, color.green, color.blue, 0.3),
          ),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(font: fontBold, fontSize: 18, color: color),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Map<String, dynamic> _getProfile(Map<String, dynamic> student) {
    if (student['student_profiles'] is List) {
      final list = student['student_profiles'] as List;
      return list.isNotEmpty ? list[0] : {};
    }
    return student['student_profiles'] ?? {};
  }

  String _calculateAvgCgpa(List<Map<String, dynamic>> students) {
    if (students.isEmpty) return '0.00';
    final cgpas = students
        .map((s) => (_getProfile(s)['cgpa'] ?? 0.0) as num)
        .toList();
    final validCgpas = cgpas.where((c) => c > 0).toList();
    if (validCgpas.isEmpty) return '0.00';
    return (validCgpas.reduce((a, b) => a + b) / validCgpas.length)
        .toStringAsFixed(2);
  }

  String _countPlaced(List<Map<String, dynamic>> students) {
    return students
        .where((s) => _getProfile(s)['placement_status'] == 'placed')
        .length
        .toString();
  }
}
