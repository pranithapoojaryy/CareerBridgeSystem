// Enhanced Learning Course Models with Curriculum Metadata

class LearningCourse {
  final String id;
  final String title;
  final String description;
  final String providerName;
  final String providerLogo;
  final String category;
  final String difficulty;

  // Curriculum Metadata
  final String? curriculumCode;
  final String? prerequisites;
  final String? targetRole;
  final int? estimatedDurationWeeks;
  final String? placementRelevance; // High, Medium, Low
  final List<String> skillsGained;
  final String? learningOutcomes;
  final String? domainType; // IT, Management, General

  // Course Details
  final int durationHours;
  final double rating;
  final int studentsEnrolled;
  final bool hasCertificate;
  final int skillPoints;
  final double price;
  final String currency;
  final List<String> tags;
  final String thumbnailAsset;
  final List<CourseSection> sections;
  final bool isEnrolled;
  final double progress;

  // Optional Domain-Specific Metadata
  final ITCourseMetadata? itMetadata;
  final ManagementCourseMetadata? managementMetadata;

  LearningCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.providerName,
    required this.providerLogo,
    required this.category,
    required this.difficulty,
    this.curriculumCode,
    this.prerequisites,
    this.targetRole,
    this.estimatedDurationWeeks,
    this.placementRelevance,
    this.skillsGained = const [],
    this.learningOutcomes,
    this.domainType,
    required this.durationHours,
    required this.rating,
    required this.studentsEnrolled,
    required this.hasCertificate,
    this.skillPoints = 0,
    this.price = 0.0,
    this.currency = 'INR',
    this.tags = const [],
    this.thumbnailAsset = '',
    this.sections = const [],
    this.isEnrolled = false,
    this.progress = 0.0,
    this.itMetadata,
    this.managementMetadata,
  });

  int get totalLectures =>
      sections.fold(0, (sum, sec) => sum + sec.lectures.length);

  factory LearningCourse.fromJson(Map<String, dynamic> json) {
    return LearningCourse(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      providerName: json['provider_name'] ?? 'Unknown',
      providerLogo: '',
      category: json['category'] ?? 'General',
      difficulty: json['difficulty'] ?? 'Beginner',
      curriculumCode: json['curriculum_code'],
      prerequisites: json['prerequisites'],
      targetRole: json['target_role'],
      estimatedDurationWeeks: json['estimated_duration_weeks'],
      placementRelevance: json['placement_relevance'],
      skillsGained: json['skills_gained'] != null
          ? List<String>.from(json['skills_gained'])
          : [],
      learningOutcomes: json['learning_outcomes'],
      domainType: json['domain_type'],
      durationHours: json['estimated_duration_weeks'] ?? 0,
      rating: 4.5,
      studentsEnrolled: json['enrollment_count'] ?? 0,
      hasCertificate: json['has_certificate'] ?? false,
      skillPoints: json['skill_points'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      tags: List<String>.from(json['tags'] ?? []),
      thumbnailAsset: json['thumbnail_url'] ?? '',
      sections:
          ((json['sections'] as List?)
                    ?.map((e) => CourseSection.fromJson(e))
                    .toList() ??
                [])
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'provider_name': providerName,
      'category': category,
      'difficulty': difficulty,
      'curriculum_code': curriculumCode,
      'prerequisites': prerequisites,
      'target_role': targetRole,
      'estimated_duration_weeks': estimatedDurationWeeks,
      'placement_relevance': placementRelevance,
      'skills_gained': skillsGained,
      'learning_outcomes': learningOutcomes,
      'domain_type': domainType,
      'price': price,
      'has_certificate': hasCertificate,
      'skill_points': skillPoints,
      'tags': tags,
      'thumbnail_url': thumbnailAsset,
    };
  }

  LearningCourse copyWith({
    String? id,
    String? title,
    String? description,
    String? providerName,
    String? providerLogo,
    String? category,
    String? difficulty,
    String? curriculumCode,
    String? prerequisites,
    String? targetRole,
    int? estimatedDurationWeeks,
    String? placementRelevance,
    List<String>? skillsGained,
    String? learningOutcomes,
    String? domainType,
    int? durationHours,
    double? rating,
    int? studentsEnrolled,
    bool? hasCertificate,
    int? skillPoints,
    double? price,
    String? currency,
    List<String>? tags,
    String? thumbnailAsset,
    List<CourseSection>? sections,
    bool? isEnrolled,
    double? progress,
    ITCourseMetadata? itMetadata,
    ManagementCourseMetadata? managementMetadata,
  }) {
    return LearningCourse(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      providerName: providerName ?? this.providerName,
      providerLogo: providerLogo ?? this.providerLogo,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      curriculumCode: curriculumCode ?? this.curriculumCode,
      prerequisites: prerequisites ?? this.prerequisites,
      targetRole: targetRole ?? this.targetRole,
      estimatedDurationWeeks:
          estimatedDurationWeeks ?? this.estimatedDurationWeeks,
      placementRelevance: placementRelevance ?? this.placementRelevance,
      skillsGained: skillsGained ?? this.skillsGained,
      learningOutcomes: learningOutcomes ?? this.learningOutcomes,
      domainType: domainType ?? this.domainType,
      durationHours: durationHours ?? this.durationHours,
      rating: rating ?? this.rating,
      studentsEnrolled: studentsEnrolled ?? this.studentsEnrolled,
      hasCertificate: hasCertificate ?? this.hasCertificate,
      skillPoints: skillPoints ?? this.skillPoints,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      tags: tags ?? this.tags,
      thumbnailAsset: thumbnailAsset ?? this.thumbnailAsset,
      sections: sections ?? this.sections,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      progress: progress ?? this.progress,
      itMetadata: itMetadata ?? this.itMetadata,
      managementMetadata: managementMetadata ?? this.managementMetadata,
    );
  }
}

// IT-Specific Metadata
class ITCourseMetadata {
  final List<String> programmingLanguages;
  final List<String> toolsFrameworks;
  final bool codePracticeRequired;
  final int miniProjectsCount;
  final bool githubSubmissionRequired;
  final String? systemDesignLevel;
  final bool labSessionsRequired;

  ITCourseMetadata({
    this.programmingLanguages = const [],
    this.toolsFrameworks = const [],
    this.codePracticeRequired = false,
    this.miniProjectsCount = 0,
    this.githubSubmissionRequired = false,
    this.systemDesignLevel,
    this.labSessionsRequired = false,
  });

  factory ITCourseMetadata.fromJson(Map<String, dynamic> json) {
    return ITCourseMetadata(
      programmingLanguages: List<String>.from(
        json['programming_languages'] ?? [],
      ),
      toolsFrameworks: List<String>.from(json['tools_frameworks'] ?? []),
      codePracticeRequired: json['code_practice_required'] ?? false,
      miniProjectsCount: json['mini_projects_count'] ?? 0,
      githubSubmissionRequired: json['github_submission_required'] ?? false,
      systemDesignLevel: json['system_design_level'],
      labSessionsRequired: json['lab_sessions_required'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'programming_languages': programmingLanguages,
      'tools_frameworks': toolsFrameworks,
      'code_practice_required': codePracticeRequired,
      'mini_projects_count': miniProjectsCount,
      'github_submission_required': githubSubmissionRequired,
      'system_design_level': systemDesignLevel,
      'lab_sessions_required': labSessionsRequired,
    };
  }
}

// Management-Specific Metadata
class ManagementCourseMetadata {
  final bool caseStudiesRequired;
  final bool presentationRequired;
  final bool groupActivityRequired;
  final String? communicationSkillWeight;
  final List<String> industryExamples;
  final bool rolePlayRequired;
  final bool reportSubmissionRequired;

  ManagementCourseMetadata({
    this.caseStudiesRequired = false,
    this.presentationRequired = false,
    this.groupActivityRequired = false,
    this.communicationSkillWeight,
    this.industryExamples = const [],
    this.rolePlayRequired = false,
    this.reportSubmissionRequired = false,
  });

  factory ManagementCourseMetadata.fromJson(Map<String, dynamic> json) {
    return ManagementCourseMetadata(
      caseStudiesRequired: json['case_studies_required'] ?? false,
      presentationRequired: json['presentation_required'] ?? false,
      groupActivityRequired: json['group_activity_required'] ?? false,
      communicationSkillWeight: json['communication_skill_weight'],
      industryExamples: List<String>.from(json['industry_examples'] ?? []),
      rolePlayRequired: json['role_play_required'] ?? false,
      reportSubmissionRequired: json['report_submission_required'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'case_studies_required': caseStudiesRequired,
      'presentation_required': presentationRequired,
      'group_activity_required': groupActivityRequired,
      'communication_skill_weight': communicationSkillWeight,
      'industry_examples': industryExamples,
      'role_play_required': rolePlayRequired,
      'report_submission_required': reportSubmissionRequired,
    };
  }
}

class CourseSection {
  final String id;
  final String title;
  final int orderIndex;
  final String? description;
  final String? moduleType; // Theory, Practice, Assessment
  final double? estimatedHours;
  final bool isMandatory;
  final String unlockRule; // Sequential, Manual, Free
  final List<String> skillsCovered;
  final bool assessmentRequired;
  final String? completionCriteria;
  final List<CourseLecture> lectures;

  CourseSection({
    required this.id,
    required this.title,
    this.orderIndex = 0,
    this.description,
    this.moduleType,
    this.estimatedHours,
    this.isMandatory = true,
    this.unlockRule = 'Sequential',
    this.skillsCovered = const [],
    this.assessmentRequired = false,
    this.completionCriteria,
    required this.lectures,
  });

  factory CourseSection.fromJson(Map<String, dynamic> json) {
    var lecturesList =
        ((json['lectures'] as List?)
                  ?.map((e) => CourseLecture.fromJson(e))
                  .toList() ??
              [])
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return CourseSection(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      orderIndex: json['order_index'] ?? 0,
      description: json['description'],
      moduleType: json['module_type'],
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble(),
      isMandatory: json['is_mandatory'] ?? true,
      unlockRule: json['unlock_rule'] ?? 'Sequential',
      skillsCovered: json['skills_covered'] != null
          ? List<String>.from(json['skills_covered'])
          : [],
      assessmentRequired: json['assessment_required'] ?? false,
      completionCriteria: json['completion_criteria'],
      lectures: lecturesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'order_index': orderIndex,
      'description': description,
      'module_type': moduleType,
      'estimated_hours': estimatedHours,
      'is_mandatory': isMandatory,
      'unlock_rule': unlockRule,
      'skills_covered': skillsCovered,
      'assessment_required': assessmentRequired,
      'completion_criteria': completionCriteria,
    };
  }
}

class CourseLecture {
  final String id;
  final String title;
  final int orderIndex;
  final String? description;
  final String type; // video, article, quiz
  final String? sourceType; // youtube, gdrive, uploaded, external
  final int durationMinutes;
  final String contentUrl;
  final bool isMandatory;
  final bool isCompleted;
  final bool isLocked;

  CourseLecture({
    required this.id,
    required this.title,
    this.orderIndex = 0,
    this.description,
    required this.type,
    this.sourceType,
    required this.durationMinutes,
    this.contentUrl = '',
    this.isMandatory = true,
    this.isCompleted = false,
    this.isLocked = true,
  });

  factory CourseLecture.fromJson(Map<String, dynamic> json) {
    return CourseLecture(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      orderIndex: json['order_index'] ?? 0,
      description: json['description'],
      type: json['content_type'] ?? 'video',
      sourceType: json['source_type'],
      durationMinutes: json['duration_minutes'] ?? 0,
      contentUrl: json['content_url'] ?? '',
      isMandatory: json['is_mandatory'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'order_index': orderIndex,
      'description': description,
      'content_type': type,
      'source_type': sourceType,
      'duration_minutes': durationMinutes,
      'content_url': contentUrl,
      'is_mandatory': isMandatory,
    };
  }
}
