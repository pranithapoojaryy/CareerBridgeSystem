class MockDefinition {
  final String id;
  final String title;
  final String? description;
  final String? collegeId;
  final int timeLimitMinutes;
  final bool isActive;
  final DateTime createdAt;

  MockDefinition({
    required this.id,
    required this.title,
    this.description,
    this.collegeId,
    this.timeLimitMinutes = 30,
    this.isActive = true,
    required this.createdAt,
  });

  factory MockDefinition.fromJson(Map<String, dynamic> json) {
    return MockDefinition(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      collegeId: json['college_id'],
      timeLimitMinutes: json['time_limit_minutes'] ?? 30,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'college_id': collegeId,
      'time_limit_minutes': timeLimitMinutes,
      'is_active': isActive,
    };
  }
}

class MockAttempt {
  final String id;
  final String studentId;
  final String mockId;
  final String status; // 'in_progress', 'submitted', 'graded'
  final int? totalScore;
  final String? facultyFeedback;
  final DateTime startedAt;
  final DateTime? submittedAt;

  // Joined Fields (Optional)
  final String? studentName;
  final String? mockTitle;
  final String? videoPath;

  MockAttempt({
    required this.id,
    required this.studentId,
    required this.mockId,
    required this.status,
    this.totalScore,
    this.facultyFeedback,
    required this.startedAt,
    this.submittedAt,
    this.studentName,
    this.mockTitle,
    this.videoPath,
  });

  factory MockAttempt.fromJson(Map<String, dynamic> json) {
    return MockAttempt(
      id: json['id'],
      studentId: json['student_id'],
      mockId: json['mock_id'],
      status: json['status'],
      totalScore: json['total_score'],
      facultyFeedback: json['faculty_feedback'],
      startedAt: DateTime.parse(json['started_at']),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : null,
      studentName:
          json['student_name'] ??
          (json['profiles'] != null ? json['profiles']['full_name'] : null),
      mockTitle: json['mock_definitions'] != null
          ? json['mock_definitions']['title']
          : null,
      videoPath: json['video_path'],
    );
  }
}
