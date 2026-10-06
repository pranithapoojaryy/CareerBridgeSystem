// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_round.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

JobRound _$JobRoundFromJson(Map<String, dynamic> json) {
  return _JobRound.fromJson(json);
}

/// @nodoc
mixin _$JobRound {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'job_id')
  String get jobId => throw _privateConstructorUsedError;
  @JsonKey(name: 'round_number')
  int get roundNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'round_type')
  String get roundType => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get instructions => throw _privateConstructorUsedError;
  @JsonKey(name: 'submission_type')
  String? get submissionType => throw _privateConstructorUsedError;
  DateTime? get deadline => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_minutes')
  int? get durationMinutes => throw _privateConstructorUsedError;
  @JsonKey(name: 'evaluation_criteria')
  Map<String, dynamic>? get evaluationCriteria =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'is_mandatory')
  bool get isMandatory => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this JobRound to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JobRound
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JobRoundCopyWith<JobRound> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JobRoundCopyWith<$Res> {
  factory $JobRoundCopyWith(JobRound value, $Res Function(JobRound) then) =
      _$JobRoundCopyWithImpl<$Res, JobRound>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'job_id') String jobId,
    @JsonKey(name: 'round_number') int roundNumber,
    @JsonKey(name: 'round_type') String roundType,
    String title,
    String? instructions,
    @JsonKey(name: 'submission_type') String? submissionType,
    DateTime? deadline,
    @JsonKey(name: 'duration_minutes') int? durationMinutes,
    @JsonKey(name: 'evaluation_criteria')
    Map<String, dynamic>? evaluationCriteria,
    @JsonKey(name: 'is_mandatory') bool isMandatory,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$JobRoundCopyWithImpl<$Res, $Val extends JobRound>
    implements $JobRoundCopyWith<$Res> {
  _$JobRoundCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JobRound
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? jobId = null,
    Object? roundNumber = null,
    Object? roundType = null,
    Object? title = null,
    Object? instructions = freezed,
    Object? submissionType = freezed,
    Object? deadline = freezed,
    Object? durationMinutes = freezed,
    Object? evaluationCriteria = freezed,
    Object? isMandatory = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            jobId: null == jobId
                ? _value.jobId
                : jobId // ignore: cast_nullable_to_non_nullable
                      as String,
            roundNumber: null == roundNumber
                ? _value.roundNumber
                : roundNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            roundType: null == roundType
                ? _value.roundType
                : roundType // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            instructions: freezed == instructions
                ? _value.instructions
                : instructions // ignore: cast_nullable_to_non_nullable
                      as String?,
            submissionType: freezed == submissionType
                ? _value.submissionType
                : submissionType // ignore: cast_nullable_to_non_nullable
                      as String?,
            deadline: freezed == deadline
                ? _value.deadline
                : deadline // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            durationMinutes: freezed == durationMinutes
                ? _value.durationMinutes
                : durationMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            evaluationCriteria: freezed == evaluationCriteria
                ? _value.evaluationCriteria
                : evaluationCriteria // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            isMandatory: null == isMandatory
                ? _value.isMandatory
                : isMandatory // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$JobRoundImplCopyWith<$Res>
    implements $JobRoundCopyWith<$Res> {
  factory _$$JobRoundImplCopyWith(
    _$JobRoundImpl value,
    $Res Function(_$JobRoundImpl) then,
  ) = __$$JobRoundImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'job_id') String jobId,
    @JsonKey(name: 'round_number') int roundNumber,
    @JsonKey(name: 'round_type') String roundType,
    String title,
    String? instructions,
    @JsonKey(name: 'submission_type') String? submissionType,
    DateTime? deadline,
    @JsonKey(name: 'duration_minutes') int? durationMinutes,
    @JsonKey(name: 'evaluation_criteria')
    Map<String, dynamic>? evaluationCriteria,
    @JsonKey(name: 'is_mandatory') bool isMandatory,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$JobRoundImplCopyWithImpl<$Res>
    extends _$JobRoundCopyWithImpl<$Res, _$JobRoundImpl>
    implements _$$JobRoundImplCopyWith<$Res> {
  __$$JobRoundImplCopyWithImpl(
    _$JobRoundImpl _value,
    $Res Function(_$JobRoundImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JobRound
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? jobId = null,
    Object? roundNumber = null,
    Object? roundType = null,
    Object? title = null,
    Object? instructions = freezed,
    Object? submissionType = freezed,
    Object? deadline = freezed,
    Object? durationMinutes = freezed,
    Object? evaluationCriteria = freezed,
    Object? isMandatory = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$JobRoundImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        jobId: null == jobId
            ? _value.jobId
            : jobId // ignore: cast_nullable_to_non_nullable
                  as String,
        roundNumber: null == roundNumber
            ? _value.roundNumber
            : roundNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        roundType: null == roundType
            ? _value.roundType
            : roundType // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        instructions: freezed == instructions
            ? _value.instructions
            : instructions // ignore: cast_nullable_to_non_nullable
                  as String?,
        submissionType: freezed == submissionType
            ? _value.submissionType
            : submissionType // ignore: cast_nullable_to_non_nullable
                  as String?,
        deadline: freezed == deadline
            ? _value.deadline
            : deadline // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        durationMinutes: freezed == durationMinutes
            ? _value.durationMinutes
            : durationMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        evaluationCriteria: freezed == evaluationCriteria
            ? _value._evaluationCriteria
            : evaluationCriteria // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        isMandatory: null == isMandatory
            ? _value.isMandatory
            : isMandatory // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$JobRoundImpl extends _JobRound {
  const _$JobRoundImpl({
    required this.id,
    @JsonKey(name: 'job_id') required this.jobId,
    @JsonKey(name: 'round_number') required this.roundNumber,
    @JsonKey(name: 'round_type') required this.roundType,
    required this.title,
    this.instructions,
    @JsonKey(name: 'submission_type') this.submissionType,
    this.deadline,
    @JsonKey(name: 'duration_minutes') this.durationMinutes,
    @JsonKey(name: 'evaluation_criteria')
    final Map<String, dynamic>? evaluationCriteria,
    @JsonKey(name: 'is_mandatory') this.isMandatory = true,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  }) : _evaluationCriteria = evaluationCriteria,
       super._();

  factory _$JobRoundImpl.fromJson(Map<String, dynamic> json) =>
      _$$JobRoundImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'job_id')
  final String jobId;
  @override
  @JsonKey(name: 'round_number')
  final int roundNumber;
  @override
  @JsonKey(name: 'round_type')
  final String roundType;
  @override
  final String title;
  @override
  final String? instructions;
  @override
  @JsonKey(name: 'submission_type')
  final String? submissionType;
  @override
  final DateTime? deadline;
  @override
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  final Map<String, dynamic>? _evaluationCriteria;
  @override
  @JsonKey(name: 'evaluation_criteria')
  Map<String, dynamic>? get evaluationCriteria {
    final value = _evaluationCriteria;
    if (value == null) return null;
    if (_evaluationCriteria is EqualUnmodifiableMapView)
      return _evaluationCriteria;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'is_mandatory')
  final bool isMandatory;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'JobRound(id: $id, jobId: $jobId, roundNumber: $roundNumber, roundType: $roundType, title: $title, instructions: $instructions, submissionType: $submissionType, deadline: $deadline, durationMinutes: $durationMinutes, evaluationCriteria: $evaluationCriteria, isMandatory: $isMandatory, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JobRoundImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.jobId, jobId) || other.jobId == jobId) &&
            (identical(other.roundNumber, roundNumber) ||
                other.roundNumber == roundNumber) &&
            (identical(other.roundType, roundType) ||
                other.roundType == roundType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.instructions, instructions) ||
                other.instructions == instructions) &&
            (identical(other.submissionType, submissionType) ||
                other.submissionType == submissionType) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            const DeepCollectionEquality().equals(
              other._evaluationCriteria,
              _evaluationCriteria,
            ) &&
            (identical(other.isMandatory, isMandatory) ||
                other.isMandatory == isMandatory) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    jobId,
    roundNumber,
    roundType,
    title,
    instructions,
    submissionType,
    deadline,
    durationMinutes,
    const DeepCollectionEquality().hash(_evaluationCriteria),
    isMandatory,
    createdAt,
    updatedAt,
  );

  /// Create a copy of JobRound
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JobRoundImplCopyWith<_$JobRoundImpl> get copyWith =>
      __$$JobRoundImplCopyWithImpl<_$JobRoundImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JobRoundImplToJson(this);
  }
}

abstract class _JobRound extends JobRound {
  const factory _JobRound({
    required final String id,
    @JsonKey(name: 'job_id') required final String jobId,
    @JsonKey(name: 'round_number') required final int roundNumber,
    @JsonKey(name: 'round_type') required final String roundType,
    required final String title,
    final String? instructions,
    @JsonKey(name: 'submission_type') final String? submissionType,
    final DateTime? deadline,
    @JsonKey(name: 'duration_minutes') final int? durationMinutes,
    @JsonKey(name: 'evaluation_criteria')
    final Map<String, dynamic>? evaluationCriteria,
    @JsonKey(name: 'is_mandatory') final bool isMandatory,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$JobRoundImpl;
  const _JobRound._() : super._();

  factory _JobRound.fromJson(Map<String, dynamic> json) =
      _$JobRoundImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'job_id')
  String get jobId;
  @override
  @JsonKey(name: 'round_number')
  int get roundNumber;
  @override
  @JsonKey(name: 'round_type')
  String get roundType;
  @override
  String get title;
  @override
  String? get instructions;
  @override
  @JsonKey(name: 'submission_type')
  String? get submissionType;
  @override
  DateTime? get deadline;
  @override
  @JsonKey(name: 'duration_minutes')
  int? get durationMinutes;
  @override
  @JsonKey(name: 'evaluation_criteria')
  Map<String, dynamic>? get evaluationCriteria;
  @override
  @JsonKey(name: 'is_mandatory')
  bool get isMandatory;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of JobRound
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JobRoundImplCopyWith<_$JobRoundImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
