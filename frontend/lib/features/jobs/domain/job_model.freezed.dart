// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Job _$JobFromJson(Map<String, dynamic> json) {
  return _Job.fromJson(json);
}

/// @nodoc
mixin _$Job {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'recruiter_id')
  String get recruiterId => throw _privateConstructorUsedError;
  @JsonKey(name: 'organization_id')
  String? get organizationId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String? get requirements => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  @JsonKey(name: 'salary_range')
  String? get salaryRange => throw _privateConstructorUsedError;
  @JsonKey(name: 'job_type')
  String? get jobType => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_featured')
  bool get isFeatured => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'screening_questions', fromJson: normalizeScreeningQuestions)
  List<Map<String, dynamic>>? get screeningQuestions =>
      throw _privateConstructorUsedError;
  Map<String, dynamic>? get organization => throw _privateConstructorUsedError;

  /// Serializes this Job to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Job
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JobCopyWith<Job> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JobCopyWith<$Res> {
  factory $JobCopyWith(Job value, $Res Function(Job) then) =
      _$JobCopyWithImpl<$Res, Job>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'recruiter_id') String recruiterId,
    @JsonKey(name: 'organization_id') String? organizationId,
    String title,
    String description,
    String? requirements,
    String? location,
    @JsonKey(name: 'salary_range') String? salaryRange,
    @JsonKey(name: 'job_type') String? jobType,
    @JsonKey(name: 'is_featured') bool isFeatured,
    String status,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'screening_questions', fromJson: normalizeScreeningQuestions)
    List<Map<String, dynamic>>? screeningQuestions,
    Map<String, dynamic>? organization,
  });
}

/// @nodoc
class _$JobCopyWithImpl<$Res, $Val extends Job> implements $JobCopyWith<$Res> {
  _$JobCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Job
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? recruiterId = null,
    Object? organizationId = freezed,
    Object? title = null,
    Object? description = null,
    Object? requirements = freezed,
    Object? location = freezed,
    Object? salaryRange = freezed,
    Object? jobType = freezed,
    Object? isFeatured = null,
    Object? status = null,
    Object? createdAt = null,
    Object? screeningQuestions = freezed,
    Object? organization = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            recruiterId: null == recruiterId
                ? _value.recruiterId
                : recruiterId // ignore: cast_nullable_to_non_nullable
                      as String,
            organizationId: freezed == organizationId
                ? _value.organizationId
                : organizationId // ignore: cast_nullable_to_non_nullable
                      as String?,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            requirements: freezed == requirements
                ? _value.requirements
                : requirements // ignore: cast_nullable_to_non_nullable
                      as String?,
            location: freezed == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String?,
            salaryRange: freezed == salaryRange
                ? _value.salaryRange
                : salaryRange // ignore: cast_nullable_to_non_nullable
                      as String?,
            jobType: freezed == jobType
                ? _value.jobType
                : jobType // ignore: cast_nullable_to_non_nullable
                      as String?,
            isFeatured: null == isFeatured
                ? _value.isFeatured
                : isFeatured // ignore: cast_nullable_to_non_nullable
                      as bool,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            screeningQuestions: freezed == screeningQuestions
                ? _value.screeningQuestions
                : screeningQuestions // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>?,
            organization: freezed == organization
                ? _value.organization
                : organization // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$JobImplCopyWith<$Res> implements $JobCopyWith<$Res> {
  factory _$$JobImplCopyWith(_$JobImpl value, $Res Function(_$JobImpl) then) =
      __$$JobImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'recruiter_id') String recruiterId,
    @JsonKey(name: 'organization_id') String? organizationId,
    String title,
    String description,
    String? requirements,
    String? location,
    @JsonKey(name: 'salary_range') String? salaryRange,
    @JsonKey(name: 'job_type') String? jobType,
    @JsonKey(name: 'is_featured') bool isFeatured,
    String status,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'screening_questions', fromJson: normalizeScreeningQuestions)
    List<Map<String, dynamic>>? screeningQuestions,
    Map<String, dynamic>? organization,
  });
}

/// @nodoc
class __$$JobImplCopyWithImpl<$Res> extends _$JobCopyWithImpl<$Res, _$JobImpl>
    implements _$$JobImplCopyWith<$Res> {
  __$$JobImplCopyWithImpl(_$JobImpl _value, $Res Function(_$JobImpl) _then)
    : super(_value, _then);

  /// Create a copy of Job
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? recruiterId = null,
    Object? organizationId = freezed,
    Object? title = null,
    Object? description = null,
    Object? requirements = freezed,
    Object? location = freezed,
    Object? salaryRange = freezed,
    Object? jobType = freezed,
    Object? isFeatured = null,
    Object? status = null,
    Object? createdAt = null,
    Object? screeningQuestions = freezed,
    Object? organization = freezed,
  }) {
    return _then(
      _$JobImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        recruiterId: null == recruiterId
            ? _value.recruiterId
            : recruiterId // ignore: cast_nullable_to_non_nullable
                  as String,
        organizationId: freezed == organizationId
            ? _value.organizationId
            : organizationId // ignore: cast_nullable_to_non_nullable
                  as String?,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        requirements: freezed == requirements
            ? _value.requirements
            : requirements // ignore: cast_nullable_to_non_nullable
                  as String?,
        location: freezed == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String?,
        salaryRange: freezed == salaryRange
            ? _value.salaryRange
            : salaryRange // ignore: cast_nullable_to_non_nullable
                  as String?,
        jobType: freezed == jobType
            ? _value.jobType
            : jobType // ignore: cast_nullable_to_non_nullable
                  as String?,
        isFeatured: null == isFeatured
            ? _value.isFeatured
            : isFeatured // ignore: cast_nullable_to_non_nullable
                  as bool,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        screeningQuestions: freezed == screeningQuestions
            ? _value._screeningQuestions
            : screeningQuestions // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>?,
        organization: freezed == organization
            ? _value._organization
            : organization // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$JobImpl extends _Job {
  const _$JobImpl({
    required this.id,
    @JsonKey(name: 'recruiter_id') required this.recruiterId,
    @JsonKey(name: 'organization_id') this.organizationId,
    required this.title,
    required this.description,
    this.requirements,
    this.location,
    @JsonKey(name: 'salary_range') this.salaryRange,
    @JsonKey(name: 'job_type') this.jobType,
    @JsonKey(name: 'is_featured') this.isFeatured = false,
    this.status = 'open',
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'screening_questions', fromJson: normalizeScreeningQuestions)
    final List<Map<String, dynamic>>? screeningQuestions,
    final Map<String, dynamic>? organization,
  }) : _screeningQuestions = screeningQuestions,
       _organization = organization,
       super._();

  factory _$JobImpl.fromJson(Map<String, dynamic> json) =>
      _$$JobImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'recruiter_id')
  final String recruiterId;
  @override
  @JsonKey(name: 'organization_id')
  final String? organizationId;
  @override
  final String title;
  @override
  final String description;
  @override
  final String? requirements;
  @override
  final String? location;
  @override
  @JsonKey(name: 'salary_range')
  final String? salaryRange;
  @override
  @JsonKey(name: 'job_type')
  final String? jobType;
  @override
  @JsonKey(name: 'is_featured')
  final bool isFeatured;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final List<Map<String, dynamic>>? _screeningQuestions;
  @override
  @JsonKey(name: 'screening_questions', fromJson: normalizeScreeningQuestions)
  List<Map<String, dynamic>>? get screeningQuestions {
    final value = _screeningQuestions;
    if (value == null) return null;
    if (_screeningQuestions is EqualUnmodifiableListView)
      return _screeningQuestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _organization;
  @override
  Map<String, dynamic>? get organization {
    final value = _organization;
    if (value == null) return null;
    if (_organization is EqualUnmodifiableMapView) return _organization;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'Job(id: $id, recruiterId: $recruiterId, organizationId: $organizationId, title: $title, description: $description, requirements: $requirements, location: $location, salaryRange: $salaryRange, jobType: $jobType, isFeatured: $isFeatured, status: $status, createdAt: $createdAt, screeningQuestions: $screeningQuestions, organization: $organization)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JobImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.recruiterId, recruiterId) ||
                other.recruiterId == recruiterId) &&
            (identical(other.organizationId, organizationId) ||
                other.organizationId == organizationId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.requirements, requirements) ||
                other.requirements == requirements) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.salaryRange, salaryRange) ||
                other.salaryRange == salaryRange) &&
            (identical(other.jobType, jobType) || other.jobType == jobType) &&
            (identical(other.isFeatured, isFeatured) ||
                other.isFeatured == isFeatured) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(
              other._screeningQuestions,
              _screeningQuestions,
            ) &&
            const DeepCollectionEquality().equals(
              other._organization,
              _organization,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    recruiterId,
    organizationId,
    title,
    description,
    requirements,
    location,
    salaryRange,
    jobType,
    isFeatured,
    status,
    createdAt,
    const DeepCollectionEquality().hash(_screeningQuestions),
    const DeepCollectionEquality().hash(_organization),
  );

  /// Create a copy of Job
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JobImplCopyWith<_$JobImpl> get copyWith =>
      __$$JobImplCopyWithImpl<_$JobImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JobImplToJson(this);
  }
}

abstract class _Job extends Job {
  const factory _Job({
    required final String id,
    @JsonKey(name: 'recruiter_id') required final String recruiterId,
    @JsonKey(name: 'organization_id') final String? organizationId,
    required final String title,
    required final String description,
    final String? requirements,
    final String? location,
    @JsonKey(name: 'salary_range') final String? salaryRange,
    @JsonKey(name: 'job_type') final String? jobType,
    @JsonKey(name: 'is_featured') final bool isFeatured,
    final String status,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'screening_questions', fromJson: normalizeScreeningQuestions)
    final List<Map<String, dynamic>>? screeningQuestions,
    final Map<String, dynamic>? organization,
  }) = _$JobImpl;
  const _Job._() : super._();

  factory _Job.fromJson(Map<String, dynamic> json) = _$JobImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'recruiter_id')
  String get recruiterId;
  @override
  @JsonKey(name: 'organization_id')
  String? get organizationId;
  @override
  String get title;
  @override
  String get description;
  @override
  String? get requirements;
  @override
  String? get location;
  @override
  @JsonKey(name: 'salary_range')
  String? get salaryRange;
  @override
  @JsonKey(name: 'job_type')
  String? get jobType;
  @override
  @JsonKey(name: 'is_featured')
  bool get isFeatured;
  @override
  String get status;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'screening_questions', fromJson: normalizeScreeningQuestions)
  List<Map<String, dynamic>>? get screeningQuestions;
  @override
  Map<String, dynamic>? get organization;

  /// Create a copy of Job
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JobImplCopyWith<_$JobImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
