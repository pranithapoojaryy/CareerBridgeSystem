// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CollegeAnalyticsImpl _$$CollegeAnalyticsImplFromJson(
  Map<String, dynamic> json,
) => _$CollegeAnalyticsImpl(
  totalStudents: (json['totalStudents'] as num).toInt(),
  activeStudents: (json['activeStudents'] as num).toInt(),
  connectedCompanies: (json['connectedCompanies'] as num).toInt(),
  pendingCompanyRequests: (json['pendingCompanyRequests'] as num).toInt(),
  studentsInMock: (json['studentsInMock'] as num).toInt(),
  mockInterviewsTaken: (json['mockInterviewsTaken'] as num).toInt(),
  studentsSelected: (json['studentsSelected'] as num).toInt(),
  enrollmentTrends: (json['enrollmentTrends'] as List<dynamic>)
      .map((e) => EnrollmentTrend.fromJson(e as Map<String, dynamic>))
      .toList(),
  departmentStats: (json['departmentStats'] as List<dynamic>)
      .map((e) => DeptPlacementStats.fromJson(e as Map<String, dynamic>))
      .toList(),
  topCompanies: (json['topCompanies'] as List<dynamic>)
      .map((e) => CompanyPlacementInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
  recentPlacements: (json['recentPlacements'] as List<dynamic>)
      .map((e) => StudentPlacementInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
  applicationFunnel: ApplicationFunnel.fromJson(
    json['applicationFunnel'] as Map<String, dynamic>,
  ),
  activeAssignments: (json['activeAssignments'] as num).toInt(),
  totalCollegeCourses: (json['totalCollegeCourses'] as num).toInt(),
  engagementMetrics: (json['engagementMetrics'] as List<dynamic>)
      .map((e) => EngagementMetric.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$CollegeAnalyticsImplToJson(
  _$CollegeAnalyticsImpl instance,
) => <String, dynamic>{
  'totalStudents': instance.totalStudents,
  'activeStudents': instance.activeStudents,
  'connectedCompanies': instance.connectedCompanies,
  'pendingCompanyRequests': instance.pendingCompanyRequests,
  'studentsInMock': instance.studentsInMock,
  'mockInterviewsTaken': instance.mockInterviewsTaken,
  'studentsSelected': instance.studentsSelected,
  'enrollmentTrends': instance.enrollmentTrends,
  'departmentStats': instance.departmentStats,
  'topCompanies': instance.topCompanies,
  'recentPlacements': instance.recentPlacements,
  'applicationFunnel': instance.applicationFunnel,
  'activeAssignments': instance.activeAssignments,
  'totalCollegeCourses': instance.totalCollegeCourses,
  'engagementMetrics': instance.engagementMetrics,
};

_$EnrollmentTrendImpl _$$EnrollmentTrendImplFromJson(
  Map<String, dynamic> json,
) => _$EnrollmentTrendImpl(
  date: DateTime.parse(json['date'] as String),
  enrollments: (json['enrollments'] as num).toInt(),
  completions: (json['completions'] as num).toInt(),
);

Map<String, dynamic> _$$EnrollmentTrendImplToJson(
  _$EnrollmentTrendImpl instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'enrollments': instance.enrollments,
  'completions': instance.completions,
};

_$EngagementMetricImpl _$$EngagementMetricImplFromJson(
  Map<String, dynamic> json,
) => _$EngagementMetricImpl(
  label: json['label'] as String,
  value: (json['value'] as num).toInt(),
  percentage: (json['percentage'] as num).toDouble(),
);

Map<String, dynamic> _$$EngagementMetricImplToJson(
  _$EngagementMetricImpl instance,
) => <String, dynamic>{
  'label': instance.label,
  'value': instance.value,
  'percentage': instance.percentage,
};

_$DeptPlacementStatsImpl _$$DeptPlacementStatsImplFromJson(
  Map<String, dynamic> json,
) => _$DeptPlacementStatsImpl(
  department: json['department'] as String,
  totalStudents: (json['totalStudents'] as num).toInt(),
  placedStudents: (json['placedStudents'] as num).toInt(),
  placementRate: (json['placementRate'] as num).toDouble(),
);

Map<String, dynamic> _$$DeptPlacementStatsImplToJson(
  _$DeptPlacementStatsImpl instance,
) => <String, dynamic>{
  'department': instance.department,
  'totalStudents': instance.totalStudents,
  'placedStudents': instance.placedStudents,
  'placementRate': instance.placementRate,
};

_$CompanyPlacementInfoImpl _$$CompanyPlacementInfoImplFromJson(
  Map<String, dynamic> json,
) => _$CompanyPlacementInfoImpl(
  companyName: json['companyName'] as String,
  logoUrl: json['logoUrl'] as String?,
  applications: (json['applications'] as num).toInt(),
  selections: (json['selections'] as num).toInt(),
  selectionRate: (json['selectionRate'] as num).toDouble(),
  averagePackage: (json['averagePackage'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$CompanyPlacementInfoImplToJson(
  _$CompanyPlacementInfoImpl instance,
) => <String, dynamic>{
  'companyName': instance.companyName,
  'logoUrl': instance.logoUrl,
  'applications': instance.applications,
  'selections': instance.selections,
  'selectionRate': instance.selectionRate,
  'averagePackage': instance.averagePackage,
};

_$StudentPlacementInfoImpl _$$StudentPlacementInfoImplFromJson(
  Map<String, dynamic> json,
) => _$StudentPlacementInfoImpl(
  studentId: json['studentId'] as String,
  studentName: json['studentName'] as String,
  department: json['department'] as String?,
  batch: json['batch'] as String?,
  status: json['status'] as String,
  mockAttempts: (json['mockAttempts'] as num).toInt(),
  placedCompany: json['placedCompany'] as String,
  packageAmount: (json['packageAmount'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$StudentPlacementInfoImplToJson(
  _$StudentPlacementInfoImpl instance,
) => <String, dynamic>{
  'studentId': instance.studentId,
  'studentName': instance.studentName,
  'department': instance.department,
  'batch': instance.batch,
  'status': instance.status,
  'mockAttempts': instance.mockAttempts,
  'placedCompany': instance.placedCompany,
  'packageAmount': instance.packageAmount,
};

_$ApplicationFunnelImpl _$$ApplicationFunnelImplFromJson(
  Map<String, dynamic> json,
) => _$ApplicationFunnelImpl(
  totalApplied: (json['totalApplied'] as num).toInt(),
  shortlisted: (json['shortlisted'] as num).toInt(),
  interviewed: (json['interviewed'] as num).toInt(),
  selected: (json['selected'] as num).toInt(),
);

Map<String, dynamic> _$$ApplicationFunnelImplToJson(
  _$ApplicationFunnelImpl instance,
) => <String, dynamic>{
  'totalApplied': instance.totalApplied,
  'shortlisted': instance.shortlisted,
  'interviewed': instance.interviewed,
  'selected': instance.selected,
};

_$StudentCoursePerformanceImpl _$$StudentCoursePerformanceImplFromJson(
  Map<String, dynamic> json,
) => _$StudentCoursePerformanceImpl(
  studentId: json['studentId'] as String,
  studentName: json['studentName'] as String,
  progress: (json['progress'] as num).toDouble(),
  quizScore: (json['quizScore'] as num).toDouble(),
  lastAccessed: json['lastAccessed'] as String,
);

Map<String, dynamic> _$$StudentCoursePerformanceImplToJson(
  _$StudentCoursePerformanceImpl instance,
) => <String, dynamic>{
  'studentId': instance.studentId,
  'studentName': instance.studentName,
  'progress': instance.progress,
  'quizScore': instance.quizScore,
  'lastAccessed': instance.lastAccessed,
};
