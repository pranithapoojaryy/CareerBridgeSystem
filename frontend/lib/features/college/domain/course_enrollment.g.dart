// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_enrollment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CourseEnrollmentImpl _$$CourseEnrollmentImplFromJson(
  Map<String, dynamic> json,
) => _$CourseEnrollmentImpl(
  enrollmentId: json['enrollmentId'] as String,
  studentId: json['studentId'] as String,
  studentName: json['studentName'] as String,
  studentEmail: json['studentEmail'] as String,
  studentMobile: json['studentMobile'] as String?,
  studentCollege: json['studentCollege'] as String?,
  usn: json['usn'] as String?,
  department: json['department'] as String?,
  semester: (json['semester'] as num?)?.toInt(),
  cgpa: (json['cgpa'] as num?)?.toDouble(),
  courseId: json['courseId'] as String,
  courseName: json['courseName'] as String,
  progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0,
  isCompleted: json['isCompleted'] as bool? ?? false,
  currentSectionName: json['currentSectionName'] as String?,
  assessmentsCompleted: (json['assessmentsCompleted'] as num?)?.toInt() ?? 0,
  averageScore: (json['averageScore'] as num?)?.toDouble(),
  enrolledAt: DateTime.parse(json['enrolledAt'] as String),
);

Map<String, dynamic> _$$CourseEnrollmentImplToJson(
  _$CourseEnrollmentImpl instance,
) => <String, dynamic>{
  'enrollmentId': instance.enrollmentId,
  'studentId': instance.studentId,
  'studentName': instance.studentName,
  'studentEmail': instance.studentEmail,
  'studentMobile': instance.studentMobile,
  'studentCollege': instance.studentCollege,
  'usn': instance.usn,
  'department': instance.department,
  'semester': instance.semester,
  'cgpa': instance.cgpa,
  'courseId': instance.courseId,
  'courseName': instance.courseName,
  'progressPercent': instance.progressPercent,
  'isCompleted': instance.isCompleted,
  'currentSectionName': instance.currentSectionName,
  'assessmentsCompleted': instance.assessmentsCompleted,
  'averageScore': instance.averageScore,
  'enrolledAt': instance.enrolledAt.toIso8601String(),
};
