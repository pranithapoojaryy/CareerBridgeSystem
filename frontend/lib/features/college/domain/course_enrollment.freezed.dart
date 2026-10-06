// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course_enrollment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CourseEnrollment _$CourseEnrollmentFromJson(Map<String, dynamic> json) {
  return _CourseEnrollment.fromJson(json);
}

/// @nodoc
mixin _$CourseEnrollment {
  String get enrollmentId => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  String get studentName => throw _privateConstructorUsedError;
  String get studentEmail => throw _privateConstructorUsedError;
  String? get studentMobile => throw _privateConstructorUsedError;
  String? get studentCollege => throw _privateConstructorUsedError;
  String? get usn => throw _privateConstructorUsedError;
  String? get department => throw _privateConstructorUsedError;
  int? get semester => throw _privateConstructorUsedError;
  double? get cgpa => throw _privateConstructorUsedError;
  String get courseId => throw _privateConstructorUsedError;
  String get courseName => throw _privateConstructorUsedError;
  double get progressPercent => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  String? get currentSectionName => throw _privateConstructorUsedError;
  int get assessmentsCompleted => throw _privateConstructorUsedError;
  double? get averageScore => throw _privateConstructorUsedError;
  DateTime get enrolledAt => throw _privateConstructorUsedError;

  /// Serializes this CourseEnrollment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CourseEnrollment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CourseEnrollmentCopyWith<CourseEnrollment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CourseEnrollmentCopyWith<$Res> {
  factory $CourseEnrollmentCopyWith(
    CourseEnrollment value,
    $Res Function(CourseEnrollment) then,
  ) = _$CourseEnrollmentCopyWithImpl<$Res, CourseEnrollment>;
  @useResult
  $Res call({
    String enrollmentId,
    String studentId,
    String studentName,
    String studentEmail,
    String? studentMobile,
    String? studentCollege,
    String? usn,
    String? department,
    int? semester,
    double? cgpa,
    String courseId,
    String courseName,
    double progressPercent,
    bool isCompleted,
    String? currentSectionName,
    int assessmentsCompleted,
    double? averageScore,
    DateTime enrolledAt,
  });
}

/// @nodoc
class _$CourseEnrollmentCopyWithImpl<$Res, $Val extends CourseEnrollment>
    implements $CourseEnrollmentCopyWith<$Res> {
  _$CourseEnrollmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CourseEnrollment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enrollmentId = null,
    Object? studentId = null,
    Object? studentName = null,
    Object? studentEmail = null,
    Object? studentMobile = freezed,
    Object? studentCollege = freezed,
    Object? usn = freezed,
    Object? department = freezed,
    Object? semester = freezed,
    Object? cgpa = freezed,
    Object? courseId = null,
    Object? courseName = null,
    Object? progressPercent = null,
    Object? isCompleted = null,
    Object? currentSectionName = freezed,
    Object? assessmentsCompleted = null,
    Object? averageScore = freezed,
    Object? enrolledAt = null,
  }) {
    return _then(
      _value.copyWith(
            enrollmentId: null == enrollmentId
                ? _value.enrollmentId
                : enrollmentId // ignore: cast_nullable_to_non_nullable
                      as String,
            studentId: null == studentId
                ? _value.studentId
                : studentId // ignore: cast_nullable_to_non_nullable
                      as String,
            studentName: null == studentName
                ? _value.studentName
                : studentName // ignore: cast_nullable_to_non_nullable
                      as String,
            studentEmail: null == studentEmail
                ? _value.studentEmail
                : studentEmail // ignore: cast_nullable_to_non_nullable
                      as String,
            studentMobile: freezed == studentMobile
                ? _value.studentMobile
                : studentMobile // ignore: cast_nullable_to_non_nullable
                      as String?,
            studentCollege: freezed == studentCollege
                ? _value.studentCollege
                : studentCollege // ignore: cast_nullable_to_non_nullable
                      as String?,
            usn: freezed == usn
                ? _value.usn
                : usn // ignore: cast_nullable_to_non_nullable
                      as String?,
            department: freezed == department
                ? _value.department
                : department // ignore: cast_nullable_to_non_nullable
                      as String?,
            semester: freezed == semester
                ? _value.semester
                : semester // ignore: cast_nullable_to_non_nullable
                      as int?,
            cgpa: freezed == cgpa
                ? _value.cgpa
                : cgpa // ignore: cast_nullable_to_non_nullable
                      as double?,
            courseId: null == courseId
                ? _value.courseId
                : courseId // ignore: cast_nullable_to_non_nullable
                      as String,
            courseName: null == courseName
                ? _value.courseName
                : courseName // ignore: cast_nullable_to_non_nullable
                      as String,
            progressPercent: null == progressPercent
                ? _value.progressPercent
                : progressPercent // ignore: cast_nullable_to_non_nullable
                      as double,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            currentSectionName: freezed == currentSectionName
                ? _value.currentSectionName
                : currentSectionName // ignore: cast_nullable_to_non_nullable
                      as String?,
            assessmentsCompleted: null == assessmentsCompleted
                ? _value.assessmentsCompleted
                : assessmentsCompleted // ignore: cast_nullable_to_non_nullable
                      as int,
            averageScore: freezed == averageScore
                ? _value.averageScore
                : averageScore // ignore: cast_nullable_to_non_nullable
                      as double?,
            enrolledAt: null == enrolledAt
                ? _value.enrolledAt
                : enrolledAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CourseEnrollmentImplCopyWith<$Res>
    implements $CourseEnrollmentCopyWith<$Res> {
  factory _$$CourseEnrollmentImplCopyWith(
    _$CourseEnrollmentImpl value,
    $Res Function(_$CourseEnrollmentImpl) then,
  ) = __$$CourseEnrollmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String enrollmentId,
    String studentId,
    String studentName,
    String studentEmail,
    String? studentMobile,
    String? studentCollege,
    String? usn,
    String? department,
    int? semester,
    double? cgpa,
    String courseId,
    String courseName,
    double progressPercent,
    bool isCompleted,
    String? currentSectionName,
    int assessmentsCompleted,
    double? averageScore,
    DateTime enrolledAt,
  });
}

/// @nodoc
class __$$CourseEnrollmentImplCopyWithImpl<$Res>
    extends _$CourseEnrollmentCopyWithImpl<$Res, _$CourseEnrollmentImpl>
    implements _$$CourseEnrollmentImplCopyWith<$Res> {
  __$$CourseEnrollmentImplCopyWithImpl(
    _$CourseEnrollmentImpl _value,
    $Res Function(_$CourseEnrollmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CourseEnrollment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enrollmentId = null,
    Object? studentId = null,
    Object? studentName = null,
    Object? studentEmail = null,
    Object? studentMobile = freezed,
    Object? studentCollege = freezed,
    Object? usn = freezed,
    Object? department = freezed,
    Object? semester = freezed,
    Object? cgpa = freezed,
    Object? courseId = null,
    Object? courseName = null,
    Object? progressPercent = null,
    Object? isCompleted = null,
    Object? currentSectionName = freezed,
    Object? assessmentsCompleted = null,
    Object? averageScore = freezed,
    Object? enrolledAt = null,
  }) {
    return _then(
      _$CourseEnrollmentImpl(
        enrollmentId: null == enrollmentId
            ? _value.enrollmentId
            : enrollmentId // ignore: cast_nullable_to_non_nullable
                  as String,
        studentId: null == studentId
            ? _value.studentId
            : studentId // ignore: cast_nullable_to_non_nullable
                  as String,
        studentName: null == studentName
            ? _value.studentName
            : studentName // ignore: cast_nullable_to_non_nullable
                  as String,
        studentEmail: null == studentEmail
            ? _value.studentEmail
            : studentEmail // ignore: cast_nullable_to_non_nullable
                  as String,
        studentMobile: freezed == studentMobile
            ? _value.studentMobile
            : studentMobile // ignore: cast_nullable_to_non_nullable
                  as String?,
        studentCollege: freezed == studentCollege
            ? _value.studentCollege
            : studentCollege // ignore: cast_nullable_to_non_nullable
                  as String?,
        usn: freezed == usn
            ? _value.usn
            : usn // ignore: cast_nullable_to_non_nullable
                  as String?,
        department: freezed == department
            ? _value.department
            : department // ignore: cast_nullable_to_non_nullable
                  as String?,
        semester: freezed == semester
            ? _value.semester
            : semester // ignore: cast_nullable_to_non_nullable
                  as int?,
        cgpa: freezed == cgpa
            ? _value.cgpa
            : cgpa // ignore: cast_nullable_to_non_nullable
                  as double?,
        courseId: null == courseId
            ? _value.courseId
            : courseId // ignore: cast_nullable_to_non_nullable
                  as String,
        courseName: null == courseName
            ? _value.courseName
            : courseName // ignore: cast_nullable_to_non_nullable
                  as String,
        progressPercent: null == progressPercent
            ? _value.progressPercent
            : progressPercent // ignore: cast_nullable_to_non_nullable
                  as double,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        currentSectionName: freezed == currentSectionName
            ? _value.currentSectionName
            : currentSectionName // ignore: cast_nullable_to_non_nullable
                  as String?,
        assessmentsCompleted: null == assessmentsCompleted
            ? _value.assessmentsCompleted
            : assessmentsCompleted // ignore: cast_nullable_to_non_nullable
                  as int,
        averageScore: freezed == averageScore
            ? _value.averageScore
            : averageScore // ignore: cast_nullable_to_non_nullable
                  as double?,
        enrolledAt: null == enrolledAt
            ? _value.enrolledAt
            : enrolledAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CourseEnrollmentImpl implements _CourseEnrollment {
  const _$CourseEnrollmentImpl({
    required this.enrollmentId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    this.studentMobile,
    this.studentCollege,
    this.usn,
    this.department,
    this.semester,
    this.cgpa,
    required this.courseId,
    required this.courseName,
    this.progressPercent = 0,
    this.isCompleted = false,
    this.currentSectionName,
    this.assessmentsCompleted = 0,
    this.averageScore,
    required this.enrolledAt,
  });

  factory _$CourseEnrollmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$CourseEnrollmentImplFromJson(json);

  @override
  final String enrollmentId;
  @override
  final String studentId;
  @override
  final String studentName;
  @override
  final String studentEmail;
  @override
  final String? studentMobile;
  @override
  final String? studentCollege;
  @override
  final String? usn;
  @override
  final String? department;
  @override
  final int? semester;
  @override
  final double? cgpa;
  @override
  final String courseId;
  @override
  final String courseName;
  @override
  @JsonKey()
  final double progressPercent;
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  final String? currentSectionName;
  @override
  @JsonKey()
  final int assessmentsCompleted;
  @override
  final double? averageScore;
  @override
  final DateTime enrolledAt;

  @override
  String toString() {
    return 'CourseEnrollment(enrollmentId: $enrollmentId, studentId: $studentId, studentName: $studentName, studentEmail: $studentEmail, studentMobile: $studentMobile, studentCollege: $studentCollege, usn: $usn, department: $department, semester: $semester, cgpa: $cgpa, courseId: $courseId, courseName: $courseName, progressPercent: $progressPercent, isCompleted: $isCompleted, currentSectionName: $currentSectionName, assessmentsCompleted: $assessmentsCompleted, averageScore: $averageScore, enrolledAt: $enrolledAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CourseEnrollmentImpl &&
            (identical(other.enrollmentId, enrollmentId) ||
                other.enrollmentId == enrollmentId) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.studentName, studentName) ||
                other.studentName == studentName) &&
            (identical(other.studentEmail, studentEmail) ||
                other.studentEmail == studentEmail) &&
            (identical(other.studentMobile, studentMobile) ||
                other.studentMobile == studentMobile) &&
            (identical(other.studentCollege, studentCollege) ||
                other.studentCollege == studentCollege) &&
            (identical(other.usn, usn) || other.usn == usn) &&
            (identical(other.department, department) ||
                other.department == department) &&
            (identical(other.semester, semester) ||
                other.semester == semester) &&
            (identical(other.cgpa, cgpa) || other.cgpa == cgpa) &&
            (identical(other.courseId, courseId) ||
                other.courseId == courseId) &&
            (identical(other.courseName, courseName) ||
                other.courseName == courseName) &&
            (identical(other.progressPercent, progressPercent) ||
                other.progressPercent == progressPercent) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.currentSectionName, currentSectionName) ||
                other.currentSectionName == currentSectionName) &&
            (identical(other.assessmentsCompleted, assessmentsCompleted) ||
                other.assessmentsCompleted == assessmentsCompleted) &&
            (identical(other.averageScore, averageScore) ||
                other.averageScore == averageScore) &&
            (identical(other.enrolledAt, enrolledAt) ||
                other.enrolledAt == enrolledAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    enrollmentId,
    studentId,
    studentName,
    studentEmail,
    studentMobile,
    studentCollege,
    usn,
    department,
    semester,
    cgpa,
    courseId,
    courseName,
    progressPercent,
    isCompleted,
    currentSectionName,
    assessmentsCompleted,
    averageScore,
    enrolledAt,
  );

  /// Create a copy of CourseEnrollment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CourseEnrollmentImplCopyWith<_$CourseEnrollmentImpl> get copyWith =>
      __$$CourseEnrollmentImplCopyWithImpl<_$CourseEnrollmentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CourseEnrollmentImplToJson(this);
  }
}

abstract class _CourseEnrollment implements CourseEnrollment {
  const factory _CourseEnrollment({
    required final String enrollmentId,
    required final String studentId,
    required final String studentName,
    required final String studentEmail,
    final String? studentMobile,
    final String? studentCollege,
    final String? usn,
    final String? department,
    final int? semester,
    final double? cgpa,
    required final String courseId,
    required final String courseName,
    final double progressPercent,
    final bool isCompleted,
    final String? currentSectionName,
    final int assessmentsCompleted,
    final double? averageScore,
    required final DateTime enrolledAt,
  }) = _$CourseEnrollmentImpl;

  factory _CourseEnrollment.fromJson(Map<String, dynamic> json) =
      _$CourseEnrollmentImpl.fromJson;

  @override
  String get enrollmentId;
  @override
  String get studentId;
  @override
  String get studentName;
  @override
  String get studentEmail;
  @override
  String? get studentMobile;
  @override
  String? get studentCollege;
  @override
  String? get usn;
  @override
  String? get department;
  @override
  int? get semester;
  @override
  double? get cgpa;
  @override
  String get courseId;
  @override
  String get courseName;
  @override
  double get progressPercent;
  @override
  bool get isCompleted;
  @override
  String? get currentSectionName;
  @override
  int get assessmentsCompleted;
  @override
  double? get averageScore;
  @override
  DateTime get enrolledAt;

  /// Create a copy of CourseEnrollment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CourseEnrollmentImplCopyWith<_$CourseEnrollmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
