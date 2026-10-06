import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum SectionType {
  header,
  summary,
  experience,
  education,
  projects,
  skills,
  certificates,
  languages,
  volunteering,
  custom,
}

class ResumeProject {
  String id;
  String userId;
  String title;
  GlobalDesign design;
  List<ResumeSection> sections;
  DateTime lastModified;

  ResumeProject({
    required this.id,
    required this.userId,
    this.title = 'Untitled Resume',
    required this.design,
    required this.sections,
    required this.lastModified,
  });

  factory ResumeProject.create(String userId) {
    return ResumeProject(
      id: const Uuid().v4(),
      userId: userId,
      design: GlobalDesign.dflt(),
      sections: [
        HeaderSection.create(),
        SummarySection.create(),
        ExperienceSection.create(),
        EducationSection.create(),
        SkillsSection.create(),
      ],
      lastModified: DateTime.now(),
    );
  }

  ResumeProject copyWith({
    String? title,
    GlobalDesign? design,
    List<ResumeSection>? sections,
  }) {
    return ResumeProject(
      id: id,
      userId: userId,
      title: title ?? this.title,
      design: design ?? this.design,
      sections: sections ?? this.sections.map((s) => s.copy()).toList(),
      lastModified: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'design': design.toJson(),
    'sections': sections.map((s) => s.toJson()).toList(),
    'lastModified': lastModified.toIso8601String(),
  };

  factory ResumeProject.fromJson(Map<String, dynamic> json) {
    return ResumeProject(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String? ?? 'Untitled Resume',
      design: GlobalDesign.fromJson(json['design'] as Map<String, dynamic>),
      sections: (json['sections'] as List<dynamic>)
          .map(
            (s) => ResumeSectionSerializer.fromJson(s as Map<String, dynamic>),
          )
          .toList(),
      lastModified:
          DateTime.tryParse(json['lastModified'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class GlobalDesign {
  String fontParam; // e.g. 'Inter'
  double baseFontSize;
  Color primaryColor;
  Color secondaryColor;
  Color backgroundColor;
  double pageMargin;
  double sectionSpacing;
  String templateId;

  GlobalDesign({
    required this.fontParam,
    required this.baseFontSize,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.pageMargin,
    required this.sectionSpacing,
    this.templateId = 'modern',
  });

  factory GlobalDesign.dflt() {
    return GlobalDesign(
      fontParam: 'Inter',
      baseFontSize: 10.0,
      primaryColor: const Color(0xFF2563EB), // Blue 600
      secondaryColor: const Color(0xFF1E40AF), // Blue 800
      backgroundColor: Colors.white,
      pageMargin: 20.0,
      sectionSpacing: 15.0,
      templateId: 'modern',
    );
  }

  GlobalDesign copyWith({
    String? fontParam,
    double? baseFontSize,
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    double? pageMargin,
    double? sectionSpacing,
    String? templateId,
  }) {
    return GlobalDesign(
      fontParam: fontParam ?? this.fontParam,
      baseFontSize: baseFontSize ?? this.baseFontSize,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      pageMargin: pageMargin ?? this.pageMargin,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      templateId: templateId ?? this.templateId,
    );
  }

  Map<String, dynamic> toJson() => {
    'fontParam': fontParam,
    'baseFontSize': baseFontSize,
    'primaryColor': primaryColor.toARGB32(),
    'secondaryColor': secondaryColor.toARGB32(),
    'backgroundColor': backgroundColor.toARGB32(),
    'pageMargin': pageMargin,
    'sectionSpacing': sectionSpacing,
    'templateId': templateId,
  };

  factory GlobalDesign.fromJson(Map<String, dynamic> json) {
    return GlobalDesign(
      fontParam: json['fontParam'] as String? ?? 'Inter',
      baseFontSize: (json['baseFontSize'] as num?)?.toDouble() ?? 10.0,
      primaryColor: Color(json['primaryColor'] as int? ?? 0xFF2563EB),
      secondaryColor: Color(json['secondaryColor'] as int? ?? 0xFF1E40AF),
      backgroundColor: Color(json['backgroundColor'] as int? ?? 0xFFFFFFFF),
      pageMargin: (json['pageMargin'] as num?)?.toDouble() ?? 20.0,
      sectionSpacing: (json['sectionSpacing'] as num?)?.toDouble() ?? 15.0,
      templateId: json['templateId'] as String? ?? 'modern',
    );
  }
}

abstract class ResumeSection {
  String id;
  String title;
  SectionType type;
  bool isVisible;
  SectionStyle style;

  ResumeSection({
    required this.id,
    required this.title,
    required this.type,
    this.isVisible = true,
    required this.style,
  });

  ResumeSection copy();
  Map<String, dynamic> toJson();

  /// Shared base fields — call super.toJson() and merge in subclass.
  Map<String, dynamic> _baseJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'isVisible': isVisible,
    'marginTop': style.marginTop,
    'marginBottom': style.marginBottom,
  };
}

class SectionStyle {
  double? marginTop;
  double? marginBottom;

  SectionStyle({this.marginTop, this.marginBottom});
}

// --- Specific Section Implementations ---

class HeaderSection extends ResumeSection {
  String fullName;
  String email;
  String phone;
  String? linkedin;
  String? portfolio;
  String? location;
  String? photoUrl;

  HeaderSection({
    required super.id,
    required super.title,
    super.type = SectionType.header,
    required super.style,
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.linkedin,
    this.portfolio,
    this.location,
    this.photoUrl,
  });

  factory HeaderSection.create() {
    return HeaderSection(
      id: const Uuid().v4(),
      title: 'Personal Details',
      style: SectionStyle(),
    );
  }

  @override
  ResumeSection copy() {
    return HeaderSection(
      id: id,
      title: title,
      style: SectionStyle(
        marginTop: style.marginTop,
        marginBottom: style.marginBottom,
      ),
      fullName: fullName,
      email: email,
      phone: phone,
      linkedin: linkedin,
      portfolio: portfolio,
      location: location,
      photoUrl: photoUrl,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ..._baseJson(),
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'linkedin': linkedin,
    'portfolio': portfolio,
    'location': location,
    'photoUrl': photoUrl,
  };
}

class SummarySection extends ResumeSection {
  String text;

  SummarySection({
    required super.id,
    required super.title,
    super.type = SectionType.summary,
    required super.style,
    this.text = '',
  });

  factory SummarySection.create() {
    return SummarySection(
      id: const Uuid().v4(),
      title: 'Professional Summary',
      style: SectionStyle(),
    );
  }

  @override
  ResumeSection copy() {
    return SummarySection(
      id: id,
      title: title,
      style: SectionStyle(
        marginTop: style.marginTop,
        marginBottom: style.marginBottom,
      ),
      text: text,
    );
  }

  @override
  Map<String, dynamic> toJson() => {..._baseJson(), 'text': text};
}

class ExperienceSection extends ResumeSection {
  List<ExperienceItem> items;

  ExperienceSection({
    required super.id,
    required super.title,
    super.type = SectionType.experience,
    required super.style,
    required this.items,
  });

  factory ExperienceSection.create() {
    return ExperienceSection(
      id: const Uuid().v4(),
      title: 'Experience',
      style: SectionStyle(),
      items: [],
    );
  }

  @override
  ResumeSection copy() {
    return ExperienceSection(
      id: id,
      title: title,
      style: SectionStyle(
        marginTop: style.marginTop,
        marginBottom: style.marginBottom,
      ),
      items: items.map((e) => e.copy()).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ..._baseJson(),
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class ExperienceItem {
  String id;
  String company;
  String role;
  String location;
  String startDate; // e.g. "Jan 2020"
  String endDate;
  bool isCurrent;
  String description;

  ExperienceItem({
    required this.id,
    this.company = '',
    this.role = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.isCurrent = false,
    this.description = '',
  });

  factory ExperienceItem.create() {
    return ExperienceItem(id: const Uuid().v4());
  }

  ExperienceItem copy() {
    return ExperienceItem(
      id: id,
      company: company,
      role: role,
      location: location,
      startDate: startDate,
      endDate: endDate,
      isCurrent: isCurrent,
      description: description,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company': company,
    'role': role,
    'location': location,
    'startDate': startDate,
    'endDate': endDate,
    'isCurrent': isCurrent,
    'description': description,
  };

  factory ExperienceItem.fromJson(Map<String, dynamic> json) => ExperienceItem(
    id: json['id'] as String? ?? const Uuid().v4(),
    company: json['company'] as String? ?? '',
    role: json['role'] as String? ?? '',
    location: json['location'] as String? ?? '',
    startDate: json['startDate'] as String? ?? '',
    endDate: json['endDate'] as String? ?? '',
    isCurrent: json['isCurrent'] as bool? ?? false,
    description: json['description'] as String? ?? '',
  );
}

class EducationSection extends ResumeSection {
  List<EducationItem> items;

  EducationSection({
    required super.id,
    required super.title,
    super.type = SectionType.education,
    required super.style,
    required this.items,
  });

  factory EducationSection.create() {
    return EducationSection(
      id: const Uuid().v4(),
      title: 'Education',
      style: SectionStyle(),
      items: [],
    );
  }

  @override
  ResumeSection copy() {
    return EducationSection(
      id: id,
      title: title,
      style: SectionStyle(
        marginTop: style.marginTop,
        marginBottom: style.marginBottom,
      ),
      items: items.map((e) => e.copy()).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ..._baseJson(),
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class EducationItem {
  String id;
  String school;
  String degree;
  String location;
  String startDate;
  String endDate;
  String? grade;

  EducationItem({
    required this.id,
    this.school = '',
    this.degree = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.grade,
  });

  factory EducationItem.create() {
    return EducationItem(id: const Uuid().v4());
  }

  EducationItem copy() {
    return EducationItem(
      id: id,
      school: school,
      degree: degree,
      location: location,
      startDate: startDate,
      endDate: endDate,
      grade: grade,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'school': school,
    'degree': degree,
    'location': location,
    'startDate': startDate,
    'endDate': endDate,
    'grade': grade,
  };

  factory EducationItem.fromJson(Map<String, dynamic> json) => EducationItem(
    id: json['id'] as String? ?? const Uuid().v4(),
    school: json['school'] as String? ?? '',
    degree: json['degree'] as String? ?? '',
    location: json['location'] as String? ?? '',
    startDate: json['startDate'] as String? ?? '',
    endDate: json['endDate'] as String? ?? '',
    grade: json['grade'] as String?,
  );
}

class SkillsSection extends ResumeSection {
  List<String> skills;

  SkillsSection({
    required super.id,
    required super.title,
    super.type = SectionType.skills,
    required super.style,
    required this.skills,
  });

  factory SkillsSection.create() {
    return SkillsSection(
      id: const Uuid().v4(),
      title: 'Skills',
      style: SectionStyle(),
      skills: [],
    );
  }

  @override
  ResumeSection copy() {
    return SkillsSection(
      id: id,
      title: title,
      style: SectionStyle(
        marginTop: style.marginTop,
        marginBottom: style.marginBottom,
      ),
      skills: List.from(skills),
    );
  }

  @override
  Map<String, dynamic> toJson() => {..._baseJson(), 'skills': skills};
}

class ProjectSection extends ResumeSection {
  List<ProjectItem> items;

  ProjectSection({
    required super.id,
    required super.title,
    super.type = SectionType.projects,
    required super.style,
    required this.items,
  });

  factory ProjectSection.create() => ProjectSection(
    id: const Uuid().v4(),
    title: 'Projects',
    style: SectionStyle(),
    items: [],
  );

  @override
  ResumeSection copy() => ProjectSection(
    id: id,
    title: title,
    style: style,
    items: items.map((e) => e.copy()).toList(),
  );

  @override
  Map<String, dynamic> toJson() => {
    ..._baseJson(),
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class ProjectItem {
  String id;
  String name;
  String role;
  String startDate;
  String endDate;
  String link;
  String description;

  ProjectItem({
    required this.id,
    this.name = '',
    this.role = '',
    this.startDate = '',
    this.endDate = '',
    this.link = '',
    this.description = '',
  });

  factory ProjectItem.create() => ProjectItem(id: const Uuid().v4());

  ProjectItem copy() => ProjectItem(
    id: id,
    name: name,
    role: role,
    startDate: startDate,
    endDate: endDate,
    link: link,
    description: description,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'startDate': startDate,
    'endDate': endDate,
    'link': link,
    'description': description,
  };

  factory ProjectItem.fromJson(Map<String, dynamic> json) => ProjectItem(
    id: json['id'] as String? ?? const Uuid().v4(),
    name: json['name'] as String? ?? '',
    role: json['role'] as String? ?? '',
    startDate: json['startDate'] as String? ?? '',
    endDate: json['endDate'] as String? ?? '',
    link: json['link'] as String? ?? '',
    description: json['description'] as String? ?? '',
  );
}

class CertificateSection extends ResumeSection {
  List<CertificateItem> items;

  CertificateSection({
    required super.id,
    required super.title,
    super.type = SectionType.certificates,
    required super.style,
    required this.items,
  });

  factory CertificateSection.create() => CertificateSection(
    id: const Uuid().v4(),
    title: 'Certifications',
    style: SectionStyle(),
    items: [],
  );

  @override
  ResumeSection copy() => CertificateSection(
    id: id,
    title: title,
    style: style,
    items: items.map((e) => e.copy()).toList(),
  );

  @override
  Map<String, dynamic> toJson() => {
    ..._baseJson(),
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class CertificateItem {
  String id;
  String name;
  String issuer;
  String date;
  String link;

  CertificateItem({
    required this.id,
    this.name = '',
    this.issuer = '',
    this.date = '',
    this.link = '',
  });

  factory CertificateItem.create() => CertificateItem(id: const Uuid().v4());

  CertificateItem copy() => CertificateItem(
    id: id,
    name: name,
    issuer: issuer,
    date: date,
    link: link,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'issuer': issuer,
    'date': date,
    'link': link,
  };

  factory CertificateItem.fromJson(Map<String, dynamic> json) =>
      CertificateItem(
        id: json['id'] as String? ?? const Uuid().v4(),
        name: json['name'] as String? ?? '',
        issuer: json['issuer'] as String? ?? '',
        date: json['date'] as String? ?? '',
        link: json['link'] as String? ?? '',
      );
}

class LanguagesSection extends ResumeSection {
  List<LanguageItem> items;

  LanguagesSection({
    required super.id,
    required super.title,
    super.type = SectionType.languages,
    required super.style,
    required this.items,
  });

  factory LanguagesSection.create() => LanguagesSection(
    id: const Uuid().v4(),
    title: 'Languages',
    style: SectionStyle(),
    items: [],
  );

  @override
  ResumeSection copy() => LanguagesSection(
    id: id,
    title: title,
    style: style,
    items: items.map((e) => e.copy()).toList(),
  );

  @override
  Map<String, dynamic> toJson() => {
    ..._baseJson(),
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class LanguageItem {
  String id;
  String name;
  String proficiency;

  LanguageItem({required this.id, this.name = '', this.proficiency = ''});

  factory LanguageItem.create() => LanguageItem(id: const Uuid().v4());

  LanguageItem copy() =>
      LanguageItem(id: id, name: name, proficiency: proficiency);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'proficiency': proficiency,
  };

  factory LanguageItem.fromJson(Map<String, dynamic> json) => LanguageItem(
    id: json['id'] as String? ?? const Uuid().v4(),
    name: json['name'] as String? ?? '',
    proficiency: json['proficiency'] as String? ?? '',
  );
}

class VolunteeringSection extends ResumeSection {
  List<ExperienceItem> items;

  VolunteeringSection({
    required super.id,
    required super.title,
    super.type = SectionType.volunteering,
    required super.style,
    required this.items,
  });

  factory VolunteeringSection.create() => VolunteeringSection(
    id: const Uuid().v4(),
    title: 'Volunteering',
    style: SectionStyle(),
    items: [],
  );

  @override
  ResumeSection copy() => VolunteeringSection(
    id: id,
    title: title,
    style: style,
    items: items.map((e) => e.copy()).toList(),
  );

  @override
  Map<String, dynamic> toJson() => {
    ..._baseJson(),
    'items': items.map((e) => e.toJson()).toList(),
  };
}

// ---------- Polymorphic deserializer ----------

class ResumeSectionSerializer {
  static ResumeSection fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? '';
    final style = SectionStyle(
      marginTop: (json['marginTop'] as num?)?.toDouble(),
      marginBottom: (json['marginBottom'] as num?)?.toDouble(),
    );
    final id = json['id'] as String? ?? const Uuid().v4();
    final title = json['title'] as String? ?? '';
    final isVisible = json['isVisible'] as bool? ?? true;

    switch (typeStr) {
      case 'header':
        return HeaderSection(
          id: id,
          title: title,
          style: style,
          fullName: json['fullName'] as String? ?? '',
          email: json['email'] as String? ?? '',
          phone: json['phone'] as String? ?? '',
          linkedin: json['linkedin'] as String?,
          portfolio: json['portfolio'] as String?,
          location: json['location'] as String?,
          photoUrl: json['photoUrl'] as String?,
        )..isVisible = isVisible;
      case 'summary':
        return SummarySection(
          id: id,
          title: title,
          style: style,
          text: json['text'] as String? ?? '',
        )..isVisible = isVisible;
      case 'experience':
        return ExperienceSection(
          id: id,
          title: title,
          style: style,
          items: (json['items'] as List<dynamic>? ?? [])
              .map((e) => ExperienceItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        )..isVisible = isVisible;
      case 'education':
        return EducationSection(
          id: id,
          title: title,
          style: style,
          items: (json['items'] as List<dynamic>? ?? [])
              .map((e) => EducationItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        )..isVisible = isVisible;
      case 'skills':
        return SkillsSection(
          id: id,
          title: title,
          style: style,
          skills: List<String>.from(json['skills'] as List? ?? []),
        )..isVisible = isVisible;
      case 'projects':
        return ProjectSection(
          id: id,
          title: title,
          style: style,
          items: (json['items'] as List<dynamic>? ?? [])
              .map((e) => ProjectItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        )..isVisible = isVisible;
      case 'certificates':
        return CertificateSection(
          id: id,
          title: title,
          style: style,
          items: (json['items'] as List<dynamic>? ?? [])
              .map((e) => CertificateItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        )..isVisible = isVisible;
      case 'languages':
        return LanguagesSection(
          id: id,
          title: title,
          style: style,
          items: (json['items'] as List<dynamic>? ?? [])
              .map((e) => LanguageItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        )..isVisible = isVisible;
      case 'volunteering':
        return VolunteeringSection(
          id: id,
          title: title,
          style: style,
          items: (json['items'] as List<dynamic>? ?? [])
              .map((e) => ExperienceItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        )..isVisible = isVisible;
      default:
        return SummarySection(id: id, title: title, style: style)
          ..isVisible = isVisible;
    }
  }
}
