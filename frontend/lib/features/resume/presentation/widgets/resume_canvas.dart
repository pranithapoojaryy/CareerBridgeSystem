import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../domain/resume_model.dart';
import '../resume_provider.dart';

class ResumeCanvas extends ConsumerWidget {
  const ResumeCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(resumeProjectProvider);
    final selectedId = ref.watch(selectedIdProvider);

    if (project == null) {
      return const Center(child: Text('Loading or No Project Selected'));
    }

    // A4 aspect ratio approximation for screen
    // Width: 210mm, Height: 297mm => Ratio ~0.707
    final a4Ratio = 210 / 297;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AspectRatio(
          aspectRatio: a4Ratio,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: project.design.backgroundColor,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _buildLayout(context, ref, project, selectedId),
          ),
        ),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    WidgetRef ref,
    ResumeProject project,
    String? selectedId,
  ) {
    if (project.design.templateId == 'creative') {
      return _buildCreativeLayout(context, ref, project, selectedId);
    }
    // Default or Modern/Ivy (Single Column)
    return Padding(
      padding: EdgeInsets.all(project.design.pageMargin),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: project.sections.length,
        separatorBuilder: (_, __) =>
            SizedBox(height: project.design.sectionSpacing),
        itemBuilder: (context, index) {
          final section = project.sections[index];
          if (!section.isVisible) return const SizedBox.shrink();

          final isSelected = section.id == selectedId;

          return GestureDetector(
            onTap: () {
              ref.read(selectedIdProvider.notifier).state = section.id;
            },
            child: Container(
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 2)
                    : Border.all(color: Colors.transparent),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(4),
              child: _buildSectionWidget(section, project.design),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreativeLayout(
    BuildContext context,
    WidgetRef ref,
    ResumeProject project,
    String? selectedId,
  ) {
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            color: project.design.primaryColor.withValues(alpha: 0.05),
            padding: EdgeInsets.all(project.design.pageMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: sidebarSections.map((section) {
                if (!section.isVisible) return const SizedBox.shrink();
                final isSelected = section.id == selectedId;
                return GestureDetector(
                  onTap: () =>
                      ref.read(selectedIdProvider.notifier).state = section.id,
                  child: Container(
                    margin: EdgeInsets.only(
                      bottom: project.design.sectionSpacing,
                    ),
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(color: Colors.blue, width: 2)
                          : Border.all(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _buildSectionWidget(
                      section,
                      project.design,
                      isSidebar: true,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: Container(
            padding: EdgeInsets.all(project.design.pageMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: mainSections.map((section) {
                if (!section.isVisible) return const SizedBox.shrink();
                final isSelected = section.id == selectedId;
                return GestureDetector(
                  onTap: () =>
                      ref.read(selectedIdProvider.notifier).state = section.id,
                  child: Container(
                    margin: EdgeInsets.only(
                      bottom: project.design.sectionSpacing,
                    ),
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(color: Colors.blue, width: 2)
                          : Border.all(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _buildSectionWidget(section, project.design),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionWidget(
    ResumeSection section,
    GlobalDesign design, {
    bool isSidebar = false,
  }) {
    if (design.templateId == 'ivy') {
      design = GlobalDesign(
        fontParam: 'Times New Roman',
        baseFontSize: design.baseFontSize,
        primaryColor: Colors.black,
        secondaryColor: Colors.black,
        backgroundColor: design.backgroundColor,
        pageMargin: design.pageMargin,
        sectionSpacing: design.sectionSpacing,
        templateId: 'ivy',
      );
    } else if (design.templateId == 'classic') {
      design = GlobalDesign(
        fontParam: 'Georgia', // Professional serif fallback
        baseFontSize: design.baseFontSize,
        primaryColor: Colors.black,
        secondaryColor: Colors.black,
        backgroundColor: design.backgroundColor,
        pageMargin: design.pageMargin,
        sectionSpacing: design.sectionSpacing,
        templateId: 'classic',
      );
    }

    switch (section.type) {
      case SectionType.header:
        if (section is HeaderSection)
          return _HeaderWidget(section: section, design: design);
        break;
      case SectionType.summary:
        if (section is SummarySection)
          return _SummaryWidget(section: section, design: design);
        break;
      case SectionType.experience:
        if (section is ExperienceSection)
          return _ExperienceWidget(section: section, design: design);
        break;
      case SectionType.education:
        if (section is EducationSection)
          return _EducationWidget(section: section, design: design);
        break;
      case SectionType.skills:
        if (section is SkillsSection)
          return _SkillsWidget(section: section, design: design);
        break;
      case SectionType.projects:
        if (section is ProjectSection)
          return _ProjectWidget(section: section, design: design);
        break;
      case SectionType.certificates:
        if (section is CertificateSection)
          return _CertificateWidget(section: section, design: design);
        break;
      case SectionType.languages:
        if (section is LanguagesSection)
          return _LanguagesWidget(section: section, design: design);
        break;
      case SectionType.volunteering:
        if (section is VolunteeringSection)
          return _VolunteeringWidget(section: section, design: design);
        break;
      default:
        return Text('Unknown Section: ${section.title}');
    }
    return const SizedBox.shrink();
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final GlobalDesign design;
  const _SectionTitle({required this.title, required this.design});

  @override
  Widget build(BuildContext context) {
    final isClassic = design.templateId == 'classic';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: design.baseFontSize * (isClassic ? 1.2 : 1.4),
            fontWeight: FontWeight.bold,
            color: isClassic ? Colors.black : design.secondaryColor,
            fontFamily: design.fontParam,
            letterSpacing: isClassic ? 1.1 : null,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          height: 0.5,
          color: isClassic
              ? Colors.black
              : design.secondaryColor.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

class _HeaderWidget extends StatelessWidget {
  final HeaderSection section;
  final GlobalDesign design;
  const _HeaderWidget({required this.section, required this.design});

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (section.photoUrl != null && section.photoUrl!.isNotEmpty) {
      if (section.photoUrl!.startsWith('data:')) {
        try {
          final base64String = section.photoUrl!.split(',').last;
          imageProvider = MemoryImage(base64Decode(base64String));
        } catch (e) {
          debugPrint('Error decoding base64 image: $e');
        }
      } else {
        imageProvider = NetworkImage(section.photoUrl!);
      }
    }

    final isClassic = design.templateId == 'classic';

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isClassic
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (imageProvider != null && !isClassic)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: imageProvider,
                  backgroundColor: design.primaryColor.withValues(alpha: 0.1),
                ),
              ),
            Flexible(
              child: Column(
                crossAxisAlignment: isClassic
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    isClassic
                        ? section.fullName.toUpperCase()
                        : section.fullName,
                    style: TextStyle(
                      fontSize: design.baseFontSize * (isClassic ? 2.0 : 2.4),
                      fontWeight: FontWeight.bold,
                      color: design.primaryColor,
                      fontFamily: design.fontParam,
                      letterSpacing: isClassic ? 1.2 : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [
                          section.email,
                          section.phone,
                          section.location ?? '',
                          section.linkedin ?? '',
                          section.portfolio ?? '',
                        ]
                        .where((s) => s.isNotEmpty)
                        .join(isClassic ? '  |  ' : ' | '),
                    textAlign: isClassic ? TextAlign.center : TextAlign.start,
                    style: TextStyle(
                      fontSize: design.baseFontSize,
                      color: Colors.black87,
                      fontFamily: design.fontParam,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isClassic) ...[
          const SizedBox(height: 8),
          const Divider(thickness: 0.5, color: Colors.black),
        ],
      ],
    );
  }
}

class _SummaryWidget extends StatelessWidget {
  final SummarySection section;
  final GlobalDesign design;
  const _SummaryWidget({required this.section, required this.design});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: section.title, design: design),
        Text(
          section.text,
          style: TextStyle(
            fontSize: design.baseFontSize,
            fontFamily: design.fontParam,
          ),
        ),
      ],
    );
  }
}

class _ExperienceWidget extends StatelessWidget {
  final ExperienceSection section;
  final GlobalDesign design;
  const _ExperienceWidget({required this.section, required this.design});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: section.title, design: design),
        ...section.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.role,
                      style: TextStyle(
                        fontSize: design.baseFontSize * 1.1,
                        fontWeight: FontWeight.bold,
                        fontFamily: design.fontParam,
                      ),
                    ),
                    Text(
                      '${item.startDate} - ${item.isCurrent ? "Present" : item.endDate}',
                      style: TextStyle(
                        fontSize: design.baseFontSize * 0.9,
                        color: Colors.grey[600],
                        fontFamily: design.fontParam,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${item.company}${item.location.isNotEmpty ? ", ${item.location}" : ""}',
                  style: TextStyle(
                    fontSize: design.baseFontSize,
                    fontStyle: FontStyle.italic,
                    fontFamily: design.fontParam,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: design.baseFontSize,
                    fontFamily: design.fontParam,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EducationWidget extends StatelessWidget {
  final EducationSection section;
  final GlobalDesign design;
  const _EducationWidget({required this.section, required this.design});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: section.title, design: design),
        ...section.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.school,
                      style: TextStyle(
                        fontSize: design.baseFontSize * 1.1,
                        fontWeight: FontWeight.bold,
                        fontFamily: design.fontParam,
                      ),
                    ),
                    Text(
                      '${item.startDate} - ${item.endDate}',
                      style: TextStyle(
                        fontSize: design.baseFontSize * 0.9,
                        color: Colors.grey[600],
                        fontFamily: design.fontParam,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${item.degree}${item.location.isNotEmpty ? ", ${item.location}" : ""}',
                  style: TextStyle(
                    fontSize: design.baseFontSize,
                    fontFamily: design.fontParam,
                  ),
                ),
                if (item.grade != null && item.grade!.isNotEmpty)
                  Text(
                    'Grade: ${item.grade}',
                    style: TextStyle(
                      fontSize: design.baseFontSize * 0.9,
                      fontFamily: design.fontParam,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkillsWidget extends StatelessWidget {
  final SkillsSection section;
  final GlobalDesign design;
  const _SkillsWidget({required this.section, required this.design});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: section.title, design: design),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: section.skills
              .map(
                (skill) => Chip(
                  label: Text(
                    skill,
                    style: TextStyle(
                      fontSize: design.baseFontSize,
                      fontFamily: design.fontParam,
                    ),
                  ),
                  backgroundColor: design.primaryColor.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ProjectWidget extends StatelessWidget {
  final ProjectSection section;
  final GlobalDesign design;
  const _ProjectWidget({required this.section, required this.design});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: section.title, design: design),
        ...section.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: design.baseFontSize * 1.1,
                        fontWeight: FontWeight.bold,
                        fontFamily: design.fontParam,
                      ),
                    ),
                    if (item.link.isNotEmpty)
                      Text(
                        item.link,
                        style: TextStyle(
                          fontSize: design.baseFontSize * 0.9,
                          color: Colors.blue,
                          fontFamily: design.fontParam,
                        ),
                      ),
                  ],
                ),
                Text(
                  item.role,
                  style: TextStyle(
                    fontSize: design.baseFontSize,
                    fontStyle: FontStyle.italic,
                    fontFamily: design.fontParam,
                  ),
                ),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: design.baseFontSize,
                    fontFamily: design.fontParam,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CertificateWidget extends StatelessWidget {
  final CertificateSection section;
  final GlobalDesign design;
  const _CertificateWidget({required this.section, required this.design});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: section.title, design: design),
        ...section.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: design.baseFontSize,
                        fontFamily: design.fontParam,
                      ),
                    ),
                    Text(
                      item.issuer,
                      style: TextStyle(
                        fontSize: design.baseFontSize * 0.9,
                        fontFamily: design.fontParam,
                      ),
                    ),
                  ],
                ),
                Text(
                  item.date,
                  style: TextStyle(
                    fontSize: design.baseFontSize * 0.9,
                    color: Colors.grey,
                    fontFamily: design.fontParam,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguagesWidget extends StatelessWidget {
  final LanguagesSection section;
  final GlobalDesign design;
  const _LanguagesWidget({required this.section, required this.design});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: section.title, design: design),
        ...section.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: design.baseFontSize,
                    fontFamily: design.fontParam,
                  ),
                ),
                Text(
                  item.proficiency,
                  style: TextStyle(
                    fontSize: design.baseFontSize,
                    fontFamily: design.fontParam,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VolunteeringWidget extends StatelessWidget {
  final VolunteeringSection section;
  final GlobalDesign design;
  const _VolunteeringWidget({required this.section, required this.design});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: section.title, design: design),
        ...section.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.role,
                      style: TextStyle(
                        fontSize: design.baseFontSize * 1.1,
                        fontWeight: FontWeight.bold,
                        fontFamily: design.fontParam,
                      ),
                    ),
                    Text(
                      '${item.startDate} - ${item.isCurrent ? "Present" : item.endDate}',
                      style: TextStyle(
                        fontSize: design.baseFontSize * 0.9,
                        color: Colors.grey[600],
                        fontFamily: design.fontParam,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${item.company}${item.location.isNotEmpty ? ", ${item.location}" : ""}',
                  style: TextStyle(
                    fontSize: design.baseFontSize,
                    fontStyle: FontStyle.italic,
                    fontFamily: design.fontParam,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: design.baseFontSize,
                    fontFamily: design.fontParam,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
