import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_enrollment.freezed.dart';
part 'course_enrollment.g.dart';

/// Model for student enrollment data visible to college
@freezed
class CourseEnrollment with _$CourseEnrollment {
  const factory CourseEnrollment({
    required String enrollmentId,
    required String studentId,
    required String studentName,
    required String studentEmail,
    String? studentMobile,
    String? studentCollege,
    String? usn,
    String? department,
    int? semester,
    double? cgpa,
    required String courseId,
    required String courseName,
    @Default(0) double progressPercent,
    @Default(false) bool isCompleted,
    String? currentSectionName,
    @Default(0) int assessmentsCompleted,
    double? averageScore,
    required DateTime enrolledAt,
  }) = _CourseEnrollment;

  factory CourseEnrollment.fromJson(Map<String, dynamic> json) =>
      _$CourseEnrollmentFromJson(json);
}
