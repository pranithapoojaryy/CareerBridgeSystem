class TestAssignment {
  final String id;
  final String testId;
  final String assignedBy;
  final String assignedByRole;
  final String organizationId;
  final String
  assignmentType; // 'individual', 'department', 'batch', 'all_students'
  final String? assignedToUser;
  final String? assignedToDepartment;
  final String? assignedToBatch;
  final DateTime startDate;
  final DateTime? deadline;
  final int maxAttempts;
  final bool isMandatory;
  final double weightage;
  final int totalAssigned;
  final int totalCompleted;
  final int totalPending;
  final double? averageScore;

  // Populated when fetching with test details
  final String? testTitle;
  final String? testDescription;
  final int? durationMinutes;
  final int? totalQuestions;
  final bool isAttempted;
  final double? myScore;
  final String? myStatus;

  TestAssignment({
    required this.id,
    required this.testId,
    required this.assignedBy,
    required this.assignedByRole,
    required this.organizationId,
    required this.assignmentType,
    this.assignedToUser,
    this.assignedToDepartment,
    this.assignedToBatch,
    required this.startDate,
    this.deadline,
    this.maxAttempts = 1,
    this.isMandatory = false,
    this.weightage = 15.0,
    this.totalAssigned = 0,
    this.totalCompleted = 0,
    this.totalPending = 0,
    this.averageScore,
    this.testTitle,
    this.testDescription,
    this.durationMinutes,
    this.totalQuestions,
    this.isAttempted = false,
    this.myScore,
    this.myStatus,
  });

  factory TestAssignment.fromJson(Map<String, dynamic> json) {
    return TestAssignment(
      id: json['id'] as String? ?? '',
      testId: json['test_id'] as String? ?? '',
      assignedBy: json['assigned_by'] as String? ?? '',
      assignedByRole: json['assigned_by_role'] as String? ?? 'unknown',
      organizationId: json['organization_id'] as String? ?? '',
      assignmentType: json['assignment_type'] as String? ?? 'individual',
      assignedToUser: json['assigned_to_user'] as String?,
      assignedToDepartment: json['assigned_to_department'] as String?,
      assignedToBatch: json['assigned_to_batch'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : DateTime.now(),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      maxAttempts: json['max_attempts'] as int? ?? 1,
      isMandatory: json['is_mandatory'] as bool? ?? false,
      weightage: (json['weightage'] as num?)?.toDouble() ?? 15.0,
      totalAssigned: json['total_assigned'] as int? ?? 0,
      totalCompleted: json['total_completed'] as int? ?? 0,
      totalPending: json['total_pending'] as int? ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble(),
      testTitle: json['test_title'] as String?,
      testDescription: json['test_description'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      totalQuestions: json['total_questions'] as int?,
      isAttempted: json['is_attempted'] as bool? ?? false,
      myScore: (json['my_score'] as num?)?.toDouble(),
      myStatus: json['my_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'test_id': testId,
      'assigned_by': assignedBy,
      'assigned_by_role': assignedByRole,
      'organization_id': organizationId,
      'assignment_type': assignmentType,
      'assigned_to_user': assignedToUser,
      'assigned_to_department': assignedToDepartment,
      'assigned_to_batch': assignedToBatch,
      'start_date': startDate.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'max_attempts': maxAttempts,
      'is_mandatory': isMandatory,
      'weightage': weightage,
      'total_assigned': totalAssigned,
      'total_completed': totalCompleted,
      'total_pending': totalPending,
      'average_score': averageScore,
    };
  }

  bool get isExpired => deadline != null && deadline!.isBefore(DateTime.now());
  bool get isActive => !isExpired && startDate.isBefore(DateTime.now());

  Duration? get timeRemaining {
    if (deadline == null) return null;
    final remaining = deadline!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  bool get isCompleted => false; // TODO: Implement logic based on user attempts

  double get completionRate {
    if (totalAssigned == 0) return 0.0;
    return totalCompleted / totalAssigned;
  }
}
