// Certificate and Skill Domain Models

class CourseCertificate {
  final String id;
  final String studentId;
  final String courseId;
  final String certificateNumber;
  final DateTime issuedAt;
  final double courseScore;
  final String finalGrade;
  final String providerName;
  final String courseTitle;
  final String studentName;
  final List<String> skillsAcquired;
  final bool isVerified;
  final String? verificationUrl;
  final String? certificateUrl;

  CourseCertificate({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.certificateNumber,
    required this.issuedAt,
    required this.courseScore,
    required this.finalGrade,
    required this.providerName,
    required this.courseTitle,
    required this.studentName,
    required this.skillsAcquired,
    this.isVerified = true,
    this.verificationUrl,
    this.certificateUrl,
  });

  factory CourseCertificate.fromJson(Map<String, dynamic> json) {
    return CourseCertificate(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      courseId: json['course_id'] ?? '',
      certificateNumber: json['certificate_number'] ?? '',
      issuedAt: DateTime.tryParse(json['issued_at'] ?? '') ?? DateTime.now(),
      courseScore: (json['course_score'] as num?)?.toDouble() ?? 0.0,
      finalGrade: json['final_grade'] ?? '',
      providerName: json['provider_name'] ?? '',
      courseTitle: json['course_title'] ?? '',
      studentName: json['student_name'] ?? '',
      skillsAcquired: json['skills_acquired'] != null
          ? List<String>.from(json['skills_acquired'])
          : [],
      isVerified: json['is_verified'] ?? true,
      verificationUrl: json['verification_url'],
      certificateUrl: json['certificate_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'course_id': courseId,
      'certificate_number': certificateNumber,
      'issued_at': issuedAt.toIso8601String(),
      'course_score': courseScore,
      'final_grade': finalGrade,
      'provider_name': providerName,
      'course_title': courseTitle,
      'student_name': studentName,
      'skills_acquired': skillsAcquired,
      'is_verified': isVerified,
      'verification_url': verificationUrl,
      'certificate_url': certificateUrl,
    };
  }
}

class StudentSkillScore {
  final String id;
  final String studentId;
  final String skillName;
  final String? skillCategory;
  final double currentScore;
  final int assessmentCount;
  final DateTime lastUpdated;
  final List<String> acquiredFromCourses;

  StudentSkillScore({
    required this.id,
    required this.studentId,
    required this.skillName,
    this.skillCategory,
    required this.currentScore,
    required this.assessmentCount,
    required this.lastUpdated,
    this.acquiredFromCourses = const [],
  });

  factory StudentSkillScore.fromJson(Map<String, dynamic> json) {
    return StudentSkillScore(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      skillName: json['skill_name'] ?? '',
      skillCategory: json['skill_category'],
      currentScore: (json['current_score'] as num?)?.toDouble() ?? 0.0,
      assessmentCount: json['assessment_count'] ?? 0,
      lastUpdated:
          DateTime.tryParse(json['last_updated'] ?? '') ?? DateTime.now(),
      acquiredFromCourses: json['acquired_from_courses'] != null
          ? List<String>.from(json['acquired_from_courses'])
          : [],
    );
  }

  // Get proficiency level based on score
  String get proficiencyLevel {
    if (currentScore >= 90) return 'Expert';
    if (currentScore >= 75) return 'Advanced';
    if (currentScore >= 60) return 'Intermediate';
    if (currentScore >= 40) return 'Beginner';
    return 'Novice';
  }

  // Get color for skill level
  int get skillColor {
    if (currentScore >= 90) return 0xFF10B981; // Green
    if (currentScore >= 75) return 0xFF3B82F6; // Blue
    if (currentScore >= 60) return 0xFF8B5CF6; // Purple
    if (currentScore >= 40) return 0xFFF59E0B; // Orange
    return 0xFFEF4444; // Red
  }
}

class SkillHistory {
  final String id;
  final String studentId;
  final String skillName;
  final double scoreChange;
  final double newScore;
  final String sourceType;
  final String? sourceId;
  final DateTime recordedAt;

  SkillHistory({
    required this.id,
    required this.studentId,
    required this.skillName,
    required this.scoreChange,
    required this.newScore,
    required this.sourceType,
    this.sourceId,
    required this.recordedAt,
  });

  factory SkillHistory.fromJson(Map<String, dynamic> json) {
    return SkillHistory(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      skillName: json['skill_name'] ?? '',
      scoreChange: (json['score_change'] as num?)?.toDouble() ?? 0.0,
      newScore: (json['new_score'] as num?)?.toDouble() ?? 0.0,
      sourceType: json['source_type'] ?? '',
      sourceId: json['source_id'],
      recordedAt:
          DateTime.tryParse(json['recorded_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class CourseSkillMapping {
  final String id;
  final String courseId;
  final String skillName;
  final String? skillCategory;
  final double weightage;

  CourseSkillMapping({
    required this.id,
    required this.courseId,
    required this.skillName,
    this.skillCategory,
    this.weightage = 1.0,
  });

  factory CourseSkillMapping.fromJson(Map<String, dynamic> json) {
    return CourseSkillMapping(
      id: json['id'] ?? '',
      courseId: json['course_id'] ?? '',
      skillName: json['skill_name'] ?? '',
      skillCategory: json['skill_category'],
      weightage: (json['weightage'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'skill_name': skillName,
      'skill_category': skillCategory,
      'weightage': weightage,
    };
  }
}

class AssessmentSkillMapping {
  final String id;
  final String assessmentId;
  final String skillName;
  final double weightage;

  AssessmentSkillMapping({
    required this.id,
    required this.assessmentId,
    required this.skillName,
    this.weightage = 1.0,
  });

  factory AssessmentSkillMapping.fromJson(Map<String, dynamic> json) {
    return AssessmentSkillMapping(
      id: json['id'] ?? '',
      assessmentId: json['assessment_id'] ?? '',
      skillName: json['skill_name'] ?? '',
      weightage: (json['weightage'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assessment_id': assessmentId,
      'skill_name': skillName,
      'weightage': weightage,
    };
  }
}
