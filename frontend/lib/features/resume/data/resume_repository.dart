import 'dart:io';
import 'dart:convert';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // Still used in templates
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger_service.dart';
import '../domain/resume_template.dart';
import '../domain/resume_model.dart';

class ModernTemplate extends ResumeTemplate {
  @override
  String get id => 'modern';

  @override
  String get name => 'Modern Blue';

  @override
  String get description => 'A clean, two-column layout with blue accents.';

  @override
  String get thumbnailAsset => 'assets/templates/modern.png';

  @override
  Future<Uint8List> generatePdf(ResumeProject project) async {
    final pdf = pw.Document();

    // Pre-fetch profile image if exists
    pw.ImageProvider? profileImage;
    try {
      final header =
          project.sections.firstWhere(
                (s) =>
                    s is HeaderSection &&
                    s.photoUrl != null &&
                    s.photoUrl!.isNotEmpty,
                orElse: () => HeaderSection.create(),
              )
              as HeaderSection?;

      if (header != null &&
          header.photoUrl != null &&
          header.photoUrl!.isNotEmpty) {
        if (header.photoUrl!.startsWith('data:')) {
          final base64String = header.photoUrl!.split(',').last;
          profileImage = pw.MemoryImage(base64Decode(base64String));
        } else {
          // Attempt to load network image
          profileImage = await networkImage(header.photoUrl!);
        }
      }
    } catch (e) {
      LoggerService.error('Error loading PDF image', e);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(project.design.pageMargin),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final section in project.sections)
                if (section.isVisible) ...[
                  _buildPdfSection(
                    section,
                    project.design,
                    profileImage: profileImage,
                  ),
                  pw.SizedBox(height: project.design.sectionSpacing),
                ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfSection(
    ResumeSection section,
    GlobalDesign design, {
    pw.ImageProvider? profileImage,
  }) {
    if (section is HeaderSection) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (profileImage != null)
            pw.Container(
              width: 60,
              height: 60,
              margin: const pw.EdgeInsets.only(right: 16),
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                image: pw.DecorationImage(
                  image: profileImage,
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  section.fullName,
                  style: pw.TextStyle(
                    fontSize: design.baseFontSize * 2.4,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  [
                    section.email,
                    section.phone,
                    section.linkedin,
                    section.location,
                  ].where((s) => s != null && s.isNotEmpty).join(' | '),
                  style: pw.TextStyle(
                    fontSize: design.baseFontSize,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (section is SummarySection) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            section.title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: design.baseFontSize * 1.4,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Divider(color: PdfColors.blue900),
          pw.Text(
            section.text,
            style: pw.TextStyle(fontSize: design.baseFontSize),
          ),
        ],
      );
    }
    if (section is ExperienceSection) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            section.title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: design.baseFontSize * 1.4,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Divider(color: PdfColors.blue900),
          ...section.items.map(
            (item) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      item.role,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: design.baseFontSize * 1.1,
                      ),
                    ),
                    pw.Text(
                      '${item.startDate} - ${item.isCurrent ? "Present" : item.endDate}',
                      style: pw.TextStyle(
                        fontSize: design.baseFontSize * 0.9,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  item.company,
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    fontSize: design.baseFontSize,
                  ),
                ),
                pw.Text(
                  item.description,
                  style: pw.TextStyle(fontSize: design.baseFontSize),
                ),
                pw.SizedBox(height: 8),
              ],
            ),
          ),
        ],
      );
    }
    // Similar implementation for Education and Skills
    if (section is SkillsSection) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            section.title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: design.baseFontSize * 1.4,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Divider(color: PdfColors.blue900),
          pw.Wrap(
            spacing: 8,
            runSpacing: 4,
            children: section.skills
                .map(
                  (s) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      s,
                      style: pw.TextStyle(fontSize: design.baseFontSize),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      );
    }
    if (section is ProjectSection) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            section.title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: design.baseFontSize * 1.4,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Divider(color: PdfColors.blue900),
          ...section.items.map(
            (item) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      item.name,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: design.baseFontSize * 1.1,
                      ),
                    ),
                    if (item.link.isNotEmpty)
                      pw.Text(
                        item.link,
                        style: pw.TextStyle(
                          fontSize: design.baseFontSize * 0.9,
                          color: PdfColors.blue,
                        ),
                      ),
                  ],
                ),
                pw.Text(
                  item.role,
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    fontSize: design.baseFontSize,
                  ),
                ),
                pw.Text(
                  item.description,
                  style: pw.TextStyle(fontSize: design.baseFontSize),
                ),
                pw.SizedBox(height: 8),
              ],
            ),
          ),
        ],
      );
    }
    if (section is CertificateSection) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            section.title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: design.baseFontSize * 1.4,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Divider(color: PdfColors.blue900),
          ...section.items.map(
            (item) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.name,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: design.baseFontSize,
                      ),
                    ),
                    pw.Text(
                      item.issuer,
                      style: pw.TextStyle(fontSize: design.baseFontSize * 0.9),
                    ),
                  ],
                ),
                pw.Text(
                  item.date,
                  style: pw.TextStyle(
                    fontSize: design.baseFontSize * 0.9,
                    color: PdfColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (section is LanguagesSection) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            section.title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: design.baseFontSize * 1.4,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Divider(color: PdfColors.blue900),
          ...section.items.map(
            (item) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  item.name,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: design.baseFontSize,
                  ),
                ),
                pw.Text(
                  item.proficiency,
                  style: pw.TextStyle(fontSize: design.baseFontSize),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (section is VolunteeringSection) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            section.title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: design.baseFontSize * 1.4,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Divider(color: PdfColors.blue900),
          ...section.items.map(
            (item) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      item.role,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: design.baseFontSize * 1.1,
                      ),
                    ),
                    pw.Text(
                      '${item.startDate} - ${item.isCurrent ? "Present" : item.endDate}',
                      style: pw.TextStyle(
                        fontSize: design.baseFontSize * 0.9,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  item.company,
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    fontSize: design.baseFontSize,
                  ),
                ),
                pw.Text(
                  item.description,
                  style: pw.TextStyle(fontSize: design.baseFontSize),
                ),
                pw.SizedBox(height: 8),
              ],
            ),
          ),
        ],
      );
    }

    return pw.SizedBox();
  }
}

class CreativeTemplate extends ResumeTemplate {
  @override
  String get id => 'creative';

  @override
  String get name => 'Creative Modern';

  @override
  String get description => 'A two-column layout with a colorful sidebar.';

  @override
  String get thumbnailAsset => 'assets/templates/creative.png';

  @override
  Future<Uint8List> generatePdf(ResumeProject project) async {
    final pdf = pw.Document();

    // Pre-fetch profile image
    pw.ImageProvider? profileImage;
    if (project.sections.any((s) => s is HeaderSection && s.photoUrl != null)) {
      try {
        final header =
            project.sections.firstWhere((s) => s is HeaderSection)
                as HeaderSection;
        if (header.photoUrl != null && header.photoUrl!.isNotEmpty) {
          if (header.photoUrl!.startsWith('data:')) {
            final base64String = header.photoUrl!.split(',').last;
            profileImage = pw.MemoryImage(base64Decode(base64String));
          } else {
            profileImage = await networkImage(header.photoUrl!);
          }
        }
      } catch (e) {
        LoggerService.error('Error in PDF generation fallback', e);
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero, // Custom margin handling for sidebar
        build: (pw.Context context) {
          final sidebarTypes = [
            SectionType.header,
            SectionType.skills,
            SectionType.languages,
            SectionType.certificates,
            SectionType.volunteering,
          ];
          final sidebarSections = project.sections
              .where((s) => sidebarTypes.contains(s.type))
              .toList();
          final mainSections = project.sections
              .where((s) => !sidebarTypes.contains(s.type))
              .toList();

          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Sidebar
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  color: PdfColors.blue50,
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: sidebarSections.map((s) {
                      if (!s.isVisible) return pw.SizedBox();
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 20),
                        child: _buildSidebarSection(
                          s,
                          project.design,
                          profileImage,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Main Content
              pw.Expanded(
                flex: 7,
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: mainSections.map((s) {
                      if (!s.isVisible) return pw.SizedBox();
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 20),
                        child: _buildMainSection(s, project.design),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSidebarSection(
    ResumeSection section,
    GlobalDesign design,
    pw.ImageProvider? profileImage,
  ) {
    if (section is HeaderSection) {
      return pw.Column(
        children: [
          if (profileImage != null)
            pw.Container(
              height: 100,
              width: 100,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                image: pw.DecorationImage(
                  image: profileImage,
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
          pw.SizedBox(height: 10),
          pw.Text(
            section.fullName,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            section.email,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            section.phone,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (section.location != null)
            pw.Text(
              section.location!,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10),
            ),
        ],
      );
    }
    // Re-use Logic for other sections but styled for sidebar (e.g. smaller text)
    // For brevity, using simplified versions
    if (section is SkillsSection) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            section.title.toUpperCase(),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Wrap(
            spacing: 5,
            runSpacing: 5,
            children: section.skills
                .map(
                  (s) => pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(
                        width: 3,
                        height: 3,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.black,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(s, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          section.title.toUpperCase(),
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.Text('Items...', style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildMainSection(ResumeSection section, GlobalDesign design) {
    // Re-use Modern template logic loosely or implement specific main content styling
    // For fast implementation, basic rendering:
    if (section is SummarySection) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            section.title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Divider(color: PdfColors.blue900),
          pw.Text(section.text),
        ],
      );
    }
    if (section is ExperienceSection) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            section.title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Divider(color: PdfColors.blue900),
          ...section.items
              .map(
                (item) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.role,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          item.company,
                          style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                        ),
                        pw.Text('${item.startDate} - ${item.endDate}'),
                      ],
                    ),
                    pw.Text(item.description),
                    pw.SizedBox(height: 8),
                  ],
                ),
              )
              .toList(),
        ],
      );
    }
    if (section is ProjectSection) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            section.title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Divider(color: PdfColors.blue900),
          ...section.items
              .map(
                (item) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.name,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(item.description),
                    pw.SizedBox(height: 8),
                  ],
                ),
              )
              .toList(),
        ],
      );
    }
    // Fallback
    return pw.Text(section.title);
  }
}

class IvyTemplate extends ResumeTemplate {
  @override
  String get id => 'ivy';

  @override
  String get name => 'Ivy League';

  @override
  String get description => 'Professional Times New Roman layout.';

  @override
  String get thumbnailAsset => 'assets/templates/ivy.png';

  @override
  Future<Uint8List> generatePdf(ResumeProject project) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40), // Classic margin
        theme: pw.ThemeData.withFont(
          base: pw.Font.times(),
          bold: pw.Font.timesBold(),
          italic: pw.Font.timesItalic(),
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final section in project.sections)
                if (section.isVisible) ...[
                  _buildSection(section),
                  pw.SizedBox(height: 15),
                ],
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  pw.Widget _buildSection(ResumeSection section) {
    if (section is HeaderSection) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            section.fullName.toUpperCase(),
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            [
              section.email,
              section.phone,
              section.location ?? '',
            ].where((s) => s.isNotEmpty).join(' | '),
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Divider(thickness: 1, color: PdfColors.black),
        ],
      );
    }
    if (section is SummarySection) {
      return pw.Text(section.text, textAlign: pw.TextAlign.justify);
    }
    // Generic logic for simple lists
    if (section is ExperienceSection) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            section.title.toUpperCase(),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.SizedBox(height: 5),
          ...section.items
              .map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            item.role,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text('${item.startDate} - ${item.endDate}'),
                        ],
                      ),
                      pw.Text(
                        item.company,
                        style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                      ),
                      pw.Text(item.description),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          section.title.toUpperCase(),
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            decoration: pw.TextDecoration.underline,
          ),
        ),
        pw.SizedBox(height: 5),
        // Basic dump for others
        if (section is SkillsSection)
          pw.Text(section.skills.join(', '))
        else if (section is EducationSection)
          ...section.items
              .map((e) => pw.Text('${e.school} - ${e.degree}'))
              .toList()
        else
          pw.Text('Section content...'),
      ],
    );
  }
}

class ClassicTemplate extends ResumeTemplate {
  @override
  String get id => 'classic';

  @override
  String get name => 'Classic Minimal';

  @override
  String get description =>
      'Traditional single-column format suitable for all industries.';

  @override
  String get thumbnailAsset => 'assets/templates/classic.png';

  @override
  Future<Uint8List> generatePdf(ResumeProject project) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final section in project.sections)
                if (section.isVisible) ...[
                  _buildSection(section, project.design),
                  pw.SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSection(ResumeSection section, GlobalDesign design) {
    if (section is HeaderSection) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            section.fullName.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            [
              section.email,
              section.phone,
              section.location ?? '',
              section.linkedin ?? '',
            ].where((s) => s.isNotEmpty).join('  |  '),
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 0.5, color: PdfColors.black),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          section.title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Divider(thickness: 0.5, color: PdfColors.black),
        pw.SizedBox(height: 4),
        if (section is SummarySection)
          pw.Text(
            section.text,
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.justify,
          )
        else if (section is ExperienceSection)
          ...section.items.map((item) => _buildExperienceItem(item))
        else if (section is EducationSection)
          ...section.items.map((item) => _buildEducationItem(item))
        else if (section is ProjectSection)
          ...section.items.map((item) => _buildProjectItem(item))
        else if (section is SkillsSection)
          pw.Text(
            section.skills.join(', '),
            style: const pw.TextStyle(fontSize: 10),
          )
        else if (section is CertificateSection)
          ...section.items.map(
            (item) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${item.name} (${item.issuer})',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(item.date, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          )
        else if (section is LanguagesSection)
          pw.Text(
            section.items.map((l) => '${l.name} (${l.proficiency})').join(', '),
            style: const pw.TextStyle(fontSize: 10),
          )
        else if (section is VolunteeringSection)
          ...section.items.map((item) => _buildExperienceItem(item)),
      ],
    );
  }

  pw.Widget _buildExperienceItem(ExperienceItem item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                item.company,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '${item.startDate} - ${item.isCurrent ? "Present" : item.endDate}',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
              ),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(item.role, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(item.location, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              item.description,
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.justify,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildEducationItem(EducationItem item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                item.school,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '${item.startDate} - ${item.endDate}',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
              ),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${item.degree}${item.grade != null ? " ($item.grade)" : ""}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(item.location, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProjectItem(ProjectItem item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                item.name,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '${item.startDate} - ${item.endDate}',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
              ),
            ],
          ),
          pw.Text(
            '${item.role}${item.link.isNotEmpty ? " | $item.link" : ""}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (item.description.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              item.description,
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.justify,
            ),
          ],
        ],
      ),
    );
  }
}

class ResumeRepository {
  final List<ResumeTemplate> _templates = [
    ModernTemplate(),
    IvyTemplate(),
    CreativeTemplate(),
    ClassicTemplate(),
  ];
  final SupabaseClient _supabase;

  ResumeRepository([SupabaseClient? client])
    : _supabase = client ?? Supabase.instance.client;

  List<ResumeTemplate> getTemplates() => _templates;

  ResumeTemplate getTemplateById(String id) {
    return _templates.firstWhere(
      (t) => t.id == id,
      orElse: () => _templates.first,
    );
  }

  Future<void> saveProject(ResumeProject project) async {
    try {
      final resumeData = {
        'id': project.id,
        'user_id': project.userId,
        'name': project.title,
        // We really need a content jsonB column to store the full object
        // For now, we are just mocking persistence of the main fields
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': project.lastModified.toIso8601String(),
      };

      // Upsert into resumes table (assuming it exists and has these fields)
      // await _supabase.from('resumes').upsert(resumeData);
      debugPrint('Saving project ${project.title} (Mock)');
    } catch (e) {
      LoggerService.error('Error saving resume project', e);
      rethrow;
    }
  }

  Future<ResumeProject?> getProject(String projectId) async {
    // Mock load
    return null;
  }

  Future<List<Map<String, dynamic>>> getResumes(String userId) async {
    return [];
  }

  // Upload PDF Resume
  Future<String> uploadResume({File? file, Uint8List? bytes}) async {
    try {
      if (file == null && bytes == null) {
        throw Exception('No file or bytes provided');
      }

      final userId = _supabase.auth.currentUser!.id;
      final fileName = '$userId/resume.pdf'; // Overwrite existing

      // Upload file to Supabase Storage
      if (kIsWeb) {
        if (bytes == null) throw Exception('Bytes required for web upload');
        await _supabase.storage
            .from('resumes')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'application/pdf',
              ),
            );
      } else {
        if (file == null) throw Exception('File required for mobile upload');
        await _supabase.storage
            .from('resumes')
            .upload(
              fileName,
              file,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'application/pdf',
              ),
            );
      }

      // Get Public URL with cache-busting timestamp so re-uploads
      // always load fresh content instead of the browser-cached old file.
      final baseUrl = _supabase.storage.from('resumes').getPublicUrl(fileName);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final url = '$baseUrl?v=$ts';

      // Update User Profile
      await _supabase
          .from('profiles')
          .update({'resume_url': url})
          .eq('id', userId);

      return url;
    } catch (e) {
      throw Exception('Failed to upload resume: $e');
    }
  }

  // Delete Resume
  Future<void> deleteResume() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final fileName = '$userId/resume.pdf';

      await _supabase.storage.from('resumes').remove([fileName]);

      await _supabase
          .from('profiles')
          .update({'resume_url': null})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete resume: $e');
    }
  }

  // Get Latest Resume URL
  Future<String?> getResumeUrl() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('profiles')
          .select('resume_url')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return response['resume_url'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Get Resume Feedback
  Future<List<Map<String, dynamic>>> getResumeFeedback() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('resume_feedback')
          .select('*, provider:provider_id(full_name, avatar_url, role)')
          .eq('student_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Add Feedback (For College/Recruiter)
  Future<void> addFeedback(String studentId, String content) async {
    try {
      final providerId = _supabase.auth.currentUser!.id;
      await _supabase.from('resume_feedback').insert({
        'student_id': studentId,
        'provider_id': providerId,
        'content': content,
      });
    } catch (e) {
      throw Exception('Failed to add feedback: $e');
    }
  }

  // Helper to get current user ID
  String getCurrentUserId() {
    return _supabase.auth.currentUser!.id;
  }
}
