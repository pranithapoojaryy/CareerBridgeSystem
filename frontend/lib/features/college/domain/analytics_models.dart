import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_models.freezed.dart';
part 'analytics_models.g.dart';

@freezed
class CollegeAnalytics with _$CollegeAnalytics {
  const factory CollegeAnalytics({
    required int totalStudents,
    required int activeStudents,
    required int connectedCompanies,
    required int pendingCompanyRequests,
    required int studentsInMock,
    required int mockInterviewsTaken,
    required int studentsSelected,
    required List<EnrollmentTrend> enrollmentTrends,
    required List<DeptPlacementStats> departmentStats,
    required List<CompanyPlacementInfo> topCompanies,
    required List<StudentPlacementInfo> recentPlacements,
    required ApplicationFunnel applicationFunnel,
    required int activeAssignments,
    required int totalCollegeCourses,
    required List<EngagementMetric> engagementMetrics,
  }) = _CollegeAnalytics;

  factory CollegeAnalytics.fromJson(Map<String, dynamic> json) =>
      _$CollegeAnalyticsFromJson(json);
}

@freezed
class EnrollmentTrend with _$EnrollmentTrend {
  const factory EnrollmentTrend({
    required DateTime date,
    required int enrollments,
    required int completions,
  }) = _EnrollmentTrend;

  factory EnrollmentTrend.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentTrendFromJson(json);
}

@freezed
class EngagementMetric with _$EngagementMetric {
  const factory EngagementMetric({
    required String label,
    required int value,
    required double percentage,
  }) = _EngagementMetric;

  factory EngagementMetric.fromJson(Map<String, dynamic> json) =>
      _$EngagementMetricFromJson(json);
}

@freezed
class DeptPlacementStats with _$DeptPlacementStats {
  const factory DeptPlacementStats({
    required String department,
    required int totalStudents,
    required int placedStudents,
    required double placementRate,
  }) = _DeptPlacementStats;

  factory DeptPlacementStats.fromJson(Map<String, dynamic> json) =>
      _$DeptPlacementStatsFromJson(json);
}

@freezed
class CompanyPlacementInfo with _$CompanyPlacementInfo {
  const factory CompanyPlacementInfo({
    required String companyName,
    String? logoUrl,
    required int applications,
    required int selections,
    required double selectionRate,
    double? averagePackage,
  }) = _CompanyPlacementInfo;

  factory CompanyPlacementInfo.fromJson(Map<String, dynamic> json) =>
      _$CompanyPlacementInfoFromJson(json);
}

@freezed
class StudentPlacementInfo with _$StudentPlacementInfo {
  const factory StudentPlacementInfo({
    required String studentId,
    required String studentName,
    String? department,
    String? batch,
    required String status,
    required int mockAttempts,
    required String placedCompany,
    double? packageAmount,
  }) = _StudentPlacementInfo;

  factory StudentPlacementInfo.fromJson(Map<String, dynamic> json) =>
      _$StudentPlacementInfoFromJson(json);
}

@freezed
class ApplicationFunnel with _$ApplicationFunnel {
  const factory ApplicationFunnel({
    required int totalApplied,
    required int shortlisted,
    required int interviewed,
    required int selected,
  }) = _ApplicationFunnel;

  factory ApplicationFunnel.fromJson(Map<String, dynamic> json) =>
      _$ApplicationFunnelFromJson(json);
}

@freezed
class StudentCoursePerformance with _$StudentCoursePerformance {
  const factory StudentCoursePerformance({
    required String studentId,
    required String studentName,
    required double progress,
    required double quizScore,
    required String lastAccessed,
  }) = _StudentCoursePerformance;

  factory StudentCoursePerformance.fromJson(Map<String, dynamic> json) =>
      _$StudentCoursePerformanceFromJson(json);
}
