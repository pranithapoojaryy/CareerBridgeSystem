// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'round_submission.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RoundSubmission _$RoundSubmissionFromJson(Map<String, dynamic> json) {
  return _RoundSubmission.fromJson(json);
}

/// @nodoc
mixin _$RoundSubmission {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'application_id')
  String get applicationId => throw _privateConstructorUsedError;
  @JsonKey(name: 'round_id')
  String get roundId => throw _privateConstructorUsedError;
  @JsonKey(name: 'submission_type')
  String get submissionType => throw _privateConstructorUsedError;
  @JsonKey(name: 'text_response')
  String? get textResponse => throw _privateConstructorUsedError;
  @JsonKey(name: 'video_url')
  String? get videoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_urls')
  List<String>? get fileUrls => throw _privateConstructorUsedError;
  @JsonKey(name: 'coding_response')
  Map<String, dynamic>? get codingResponse =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'submitted_at')
  DateTime get submittedAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError; // Joined data
  RoundEvaluation? get evaluation => throw _privateConstructorUsedError;

  /// Serializes this RoundSubmission to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RoundSubmission
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoundSubmissionCopyWith<RoundSubmission> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoundSubmissionCopyWith<$Res> {
  factory $RoundSubmissionCopyWith(
    RoundSubmission value,
    $Res Function(RoundSubmission) then,
  ) = _$RoundSubmissionCopyWithImpl<$Res, RoundSubmission>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'application_id') String applicationId,
    @JsonKey(name: 'round_id') String roundId,
    @JsonKey(name: 'submission_type') String submissionType,
    @JsonKey(name: 'text_response') String? textResponse,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'file_urls') List<String>? fileUrls,
    @JsonKey(name: 'coding_response') Map<String, dynamic>? codingResponse,
    @JsonKey(name: 'submitted_at') DateTime submittedAt,
    String status,
    RoundEvaluation? evaluation,
  });

  $RoundEvaluationCopyWith<$Res>? get evaluation;
}

/// @nodoc
class _$RoundSubmissionCopyWithImpl<$Res, $Val extends RoundSubmission>
    implements $RoundSubmissionCopyWith<$Res> {
  _$RoundSubmissionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoundSubmission
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? applicationId = null,
    Object? roundId = null,
    Object? submissionType = null,
    Object? textResponse = freezed,
    Object? videoUrl = freezed,
    Object? fileUrls = freezed,
    Object? codingResponse = freezed,
    Object? submittedAt = null,
    Object? status = null,
    Object? evaluation = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            applicationId: null == applicationId
                ? _value.applicationId
                : applicationId // ignore: cast_nullable_to_non_nullable
                      as String,
            roundId: null == roundId
                ? _value.roundId
                : roundId // ignore: cast_nullable_to_non_nullable
                      as String,
            submissionType: null == submissionType
                ? _value.submissionType
                : submissionType // ignore: cast_nullable_to_non_nullable
                      as String,
            textResponse: freezed == textResponse
                ? _value.textResponse
                : textResponse // ignore: cast_nullable_to_non_nullable
                      as String?,
            videoUrl: freezed == videoUrl
                ? _value.videoUrl
                : videoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            fileUrls: freezed == fileUrls
                ? _value.fileUrls
                : fileUrls // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            codingResponse: freezed == codingResponse
                ? _value.codingResponse
                : codingResponse // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            submittedAt: null == submittedAt
                ? _value.submittedAt
                : submittedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            evaluation: freezed == evaluation
                ? _value.evaluation
                : evaluation // ignore: cast_nullable_to_non_nullable
                      as RoundEvaluation?,
          )
          as $Val,
    );
  }

  /// Create a copy of RoundSubmission
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RoundEvaluationCopyWith<$Res>? get evaluation {
    if (_value.evaluation == null) {
      return null;
    }

    return $RoundEvaluationCopyWith<$Res>(_value.evaluation!, (value) {
      return _then(_value.copyWith(evaluation: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RoundSubmissionImplCopyWith<$Res>
    implements $RoundSubmissionCopyWith<$Res> {
  factory _$$RoundSubmissionImplCopyWith(
    _$RoundSubmissionImpl value,
    $Res Function(_$RoundSubmissionImpl) then,
  ) = __$$RoundSubmissionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'application_id') String applicationId,
    @JsonKey(name: 'round_id') String roundId,
    @JsonKey(name: 'submission_type') String submissionType,
    @JsonKey(name: 'text_response') String? textResponse,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'file_urls') List<String>? fileUrls,
    @JsonKey(name: 'coding_response') Map<String, dynamic>? codingResponse,
    @JsonKey(name: 'submitted_at') DateTime submittedAt,
    String status,
    RoundEvaluation? evaluation,
  });

  @override
  $RoundEvaluationCopyWith<$Res>? get evaluation;
}

/// @nodoc
class __$$RoundSubmissionImplCopyWithImpl<$Res>
    extends _$RoundSubmissionCopyWithImpl<$Res, _$RoundSubmissionImpl>
    implements _$$RoundSubmissionImplCopyWith<$Res> {
  __$$RoundSubmissionImplCopyWithImpl(
    _$RoundSubmissionImpl _value,
    $Res Function(_$RoundSubmissionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RoundSubmission
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? applicationId = null,
    Object? roundId = null,
    Object? submissionType = null,
    Object? textResponse = freezed,
    Object? videoUrl = freezed,
    Object? fileUrls = freezed,
    Object? codingResponse = freezed,
    Object? submittedAt = null,
    Object? status = null,
    Object? evaluation = freezed,
  }) {
    return _then(
      _$RoundSubmissionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        applicationId: null == applicationId
            ? _value.applicationId
            : applicationId // ignore: cast_nullable_to_non_nullable
                  as String,
        roundId: null == roundId
            ? _value.roundId
            : roundId // ignore: cast_nullable_to_non_nullable
                  as String,
        submissionType: null == submissionType
            ? _value.submissionType
            : submissionType // ignore: cast_nullable_to_non_nullable
                  as String,
        textResponse: freezed == textResponse
            ? _value.textResponse
            : textResponse // ignore: cast_nullable_to_non_nullable
                  as String?,
        videoUrl: freezed == videoUrl
            ? _value.videoUrl
            : videoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        fileUrls: freezed == fileUrls
            ? _value._fileUrls
            : fileUrls // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        codingResponse: freezed == codingResponse
            ? _value._codingResponse
            : codingResponse // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        submittedAt: null == submittedAt
            ? _value.submittedAt
            : submittedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        evaluation: freezed == evaluation
            ? _value.evaluation
            : evaluation // ignore: cast_nullable_to_non_nullable
                  as RoundEvaluation?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RoundSubmissionImpl implements _RoundSubmission {
  const _$RoundSubmissionImpl({
    required this.id,
    @JsonKey(name: 'application_id') required this.applicationId,
    @JsonKey(name: 'round_id') required this.roundId,
    @JsonKey(name: 'submission_type') required this.submissionType,
    @JsonKey(name: 'text_response') this.textResponse,
    @JsonKey(name: 'video_url') this.videoUrl,
    @JsonKey(name: 'file_urls') final List<String>? fileUrls,
    @JsonKey(name: 'coding_response')
    final Map<String, dynamic>? codingResponse,
    @JsonKey(name: 'submitted_at') required this.submittedAt,
    this.status = 'pending',
    this.evaluation,
  }) : _fileUrls = fileUrls,
       _codingResponse = codingResponse;

  factory _$RoundSubmissionImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoundSubmissionImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'application_id')
  final String applicationId;
  @override
  @JsonKey(name: 'round_id')
  final String roundId;
  @override
  @JsonKey(name: 'submission_type')
  final String submissionType;
  @override
  @JsonKey(name: 'text_response')
  final String? textResponse;
  @override
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  final List<String>? _fileUrls;
  @override
  @JsonKey(name: 'file_urls')
  List<String>? get fileUrls {
    final value = _fileUrls;
    if (value == null) return null;
    if (_fileUrls is EqualUnmodifiableListView) return _fileUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _codingResponse;
  @override
  @JsonKey(name: 'coding_response')
  Map<String, dynamic>? get codingResponse {
    final value = _codingResponse;
    if (value == null) return null;
    if (_codingResponse is EqualUnmodifiableMapView) return _codingResponse;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'submitted_at')
  final DateTime submittedAt;
  @override
  @JsonKey()
  final String status;
  // Joined data
  @override
  final RoundEvaluation? evaluation;

  @override
  String toString() {
    return 'RoundSubmission(id: $id, applicationId: $applicationId, roundId: $roundId, submissionType: $submissionType, textResponse: $textResponse, videoUrl: $videoUrl, fileUrls: $fileUrls, codingResponse: $codingResponse, submittedAt: $submittedAt, status: $status, evaluation: $evaluation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoundSubmissionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.applicationId, applicationId) ||
                other.applicationId == applicationId) &&
            (identical(other.roundId, roundId) || other.roundId == roundId) &&
            (identical(other.submissionType, submissionType) ||
                other.submissionType == submissionType) &&
            (identical(other.textResponse, textResponse) ||
                other.textResponse == textResponse) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
            const DeepCollectionEquality().equals(other._fileUrls, _fileUrls) &&
            const DeepCollectionEquality().equals(
              other._codingResponse,
              _codingResponse,
            ) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.evaluation, evaluation) ||
                other.evaluation == evaluation));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    applicationId,
    roundId,
    submissionType,
    textResponse,
    videoUrl,
    const DeepCollectionEquality().hash(_fileUrls),
    const DeepCollectionEquality().hash(_codingResponse),
    submittedAt,
    status,
    evaluation,
  );

  /// Create a copy of RoundSubmission
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoundSubmissionImplCopyWith<_$RoundSubmissionImpl> get copyWith =>
      __$$RoundSubmissionImplCopyWithImpl<_$RoundSubmissionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RoundSubmissionImplToJson(this);
  }
}

abstract class _RoundSubmission implements RoundSubmission {
  const factory _RoundSubmission({
    required final String id,
    @JsonKey(name: 'application_id') required final String applicationId,
    @JsonKey(name: 'round_id') required final String roundId,
    @JsonKey(name: 'submission_type') required final String submissionType,
    @JsonKey(name: 'text_response') final String? textResponse,
    @JsonKey(name: 'video_url') final String? videoUrl,
    @JsonKey(name: 'file_urls') final List<String>? fileUrls,
    @JsonKey(name: 'coding_response')
    final Map<String, dynamic>? codingResponse,
    @JsonKey(name: 'submitted_at') required final DateTime submittedAt,
    final String status,
    final RoundEvaluation? evaluation,
  }) = _$RoundSubmissionImpl;

  factory _RoundSubmission.fromJson(Map<String, dynamic> json) =
      _$RoundSubmissionImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'application_id')
  String get applicationId;
  @override
  @JsonKey(name: 'round_id')
  String get roundId;
  @override
  @JsonKey(name: 'submission_type')
  String get submissionType;
  @override
  @JsonKey(name: 'text_response')
  String? get textResponse;
  @override
  @JsonKey(name: 'video_url')
  String? get videoUrl;
  @override
  @JsonKey(name: 'file_urls')
  List<String>? get fileUrls;
  @override
  @JsonKey(name: 'coding_response')
  Map<String, dynamic>? get codingResponse;
  @override
  @JsonKey(name: 'submitted_at')
  DateTime get submittedAt;
  @override
  String get status; // Joined data
  @override
  RoundEvaluation? get evaluation;

  /// Create a copy of RoundSubmission
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoundSubmissionImplCopyWith<_$RoundSubmissionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RoundEvaluation _$RoundEvaluationFromJson(Map<String, dynamic> json) {
  return _RoundEvaluation.fromJson(json);
}

/// @nodoc
mixin _$RoundEvaluation {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'submission_id')
  String get submissionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'evaluator_id')
  String? get evaluatorId => throw _privateConstructorUsedError;
  double? get score => throw _privateConstructorUsedError;
  String? get feedback => throw _privateConstructorUsedError;
  Map<String, dynamic>? get remarks => throw _privateConstructorUsedError;
  String? get decision => throw _privateConstructorUsedError;
  @JsonKey(name: 'evaluated_at')
  DateTime? get evaluatedAt => throw _privateConstructorUsedError;

  /// Serializes this RoundEvaluation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RoundEvaluation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoundEvaluationCopyWith<RoundEvaluation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoundEvaluationCopyWith<$Res> {
  factory $RoundEvaluationCopyWith(
    RoundEvaluation value,
    $Res Function(RoundEvaluation) then,
  ) = _$RoundEvaluationCopyWithImpl<$Res, RoundEvaluation>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'submission_id') String submissionId,
    @JsonKey(name: 'evaluator_id') String? evaluatorId,
    double? score,
    String? feedback,
    Map<String, dynamic>? remarks,
    String? decision,
    @JsonKey(name: 'evaluated_at') DateTime? evaluatedAt,
  });
}

/// @nodoc
class _$RoundEvaluationCopyWithImpl<$Res, $Val extends RoundEvaluation>
    implements $RoundEvaluationCopyWith<$Res> {
  _$RoundEvaluationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoundEvaluation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? submissionId = null,
    Object? evaluatorId = freezed,
    Object? score = freezed,
    Object? feedback = freezed,
    Object? remarks = freezed,
    Object? decision = freezed,
    Object? evaluatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            submissionId: null == submissionId
                ? _value.submissionId
                : submissionId // ignore: cast_nullable_to_non_nullable
                      as String,
            evaluatorId: freezed == evaluatorId
                ? _value.evaluatorId
                : evaluatorId // ignore: cast_nullable_to_non_nullable
                      as String?,
            score: freezed == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as double?,
            feedback: freezed == feedback
                ? _value.feedback
                : feedback // ignore: cast_nullable_to_non_nullable
                      as String?,
            remarks: freezed == remarks
                ? _value.remarks
                : remarks // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            decision: freezed == decision
                ? _value.decision
                : decision // ignore: cast_nullable_to_non_nullable
                      as String?,
            evaluatedAt: freezed == evaluatedAt
                ? _value.evaluatedAt
                : evaluatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RoundEvaluationImplCopyWith<$Res>
    implements $RoundEvaluationCopyWith<$Res> {
  factory _$$RoundEvaluationImplCopyWith(
    _$RoundEvaluationImpl value,
    $Res Function(_$RoundEvaluationImpl) then,
  ) = __$$RoundEvaluationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'submission_id') String submissionId,
    @JsonKey(name: 'evaluator_id') String? evaluatorId,
    double? score,
    String? feedback,
    Map<String, dynamic>? remarks,
    String? decision,
    @JsonKey(name: 'evaluated_at') DateTime? evaluatedAt,
  });
}

/// @nodoc
class __$$RoundEvaluationImplCopyWithImpl<$Res>
    extends _$RoundEvaluationCopyWithImpl<$Res, _$RoundEvaluationImpl>
    implements _$$RoundEvaluationImplCopyWith<$Res> {
  __$$RoundEvaluationImplCopyWithImpl(
    _$RoundEvaluationImpl _value,
    $Res Function(_$RoundEvaluationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RoundEvaluation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? submissionId = null,
    Object? evaluatorId = freezed,
    Object? score = freezed,
    Object? feedback = freezed,
    Object? remarks = freezed,
    Object? decision = freezed,
    Object? evaluatedAt = freezed,
  }) {
    return _then(
      _$RoundEvaluationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        submissionId: null == submissionId
            ? _value.submissionId
            : submissionId // ignore: cast_nullable_to_non_nullable
                  as String,
        evaluatorId: freezed == evaluatorId
            ? _value.evaluatorId
            : evaluatorId // ignore: cast_nullable_to_non_nullable
                  as String?,
        score: freezed == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as double?,
        feedback: freezed == feedback
            ? _value.feedback
            : feedback // ignore: cast_nullable_to_non_nullable
                  as String?,
        remarks: freezed == remarks
            ? _value._remarks
            : remarks // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        decision: freezed == decision
            ? _value.decision
            : decision // ignore: cast_nullable_to_non_nullable
                  as String?,
        evaluatedAt: freezed == evaluatedAt
            ? _value.evaluatedAt
            : evaluatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RoundEvaluationImpl implements _RoundEvaluation {
  const _$RoundEvaluationImpl({
    required this.id,
    @JsonKey(name: 'submission_id') required this.submissionId,
    @JsonKey(name: 'evaluator_id') this.evaluatorId,
    this.score,
    this.feedback,
    final Map<String, dynamic>? remarks,
    this.decision,
    @JsonKey(name: 'evaluated_at') this.evaluatedAt,
  }) : _remarks = remarks;

  factory _$RoundEvaluationImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoundEvaluationImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'submission_id')
  final String submissionId;
  @override
  @JsonKey(name: 'evaluator_id')
  final String? evaluatorId;
  @override
  final double? score;
  @override
  final String? feedback;
  final Map<String, dynamic>? _remarks;
  @override
  Map<String, dynamic>? get remarks {
    final value = _remarks;
    if (value == null) return null;
    if (_remarks is EqualUnmodifiableMapView) return _remarks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? decision;
  @override
  @JsonKey(name: 'evaluated_at')
  final DateTime? evaluatedAt;

  @override
  String toString() {
    return 'RoundEvaluation(id: $id, submissionId: $submissionId, evaluatorId: $evaluatorId, score: $score, feedback: $feedback, remarks: $remarks, decision: $decision, evaluatedAt: $evaluatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoundEvaluationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.submissionId, submissionId) ||
                other.submissionId == submissionId) &&
            (identical(other.evaluatorId, evaluatorId) ||
                other.evaluatorId == evaluatorId) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.feedback, feedback) ||
                other.feedback == feedback) &&
            const DeepCollectionEquality().equals(other._remarks, _remarks) &&
            (identical(other.decision, decision) ||
                other.decision == decision) &&
            (identical(other.evaluatedAt, evaluatedAt) ||
                other.evaluatedAt == evaluatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    submissionId,
    evaluatorId,
    score,
    feedback,
    const DeepCollectionEquality().hash(_remarks),
    decision,
    evaluatedAt,
  );

  /// Create a copy of RoundEvaluation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoundEvaluationImplCopyWith<_$RoundEvaluationImpl> get copyWith =>
      __$$RoundEvaluationImplCopyWithImpl<_$RoundEvaluationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RoundEvaluationImplToJson(this);
  }
}

abstract class _RoundEvaluation implements RoundEvaluation {
  const factory _RoundEvaluation({
    required final String id,
    @JsonKey(name: 'submission_id') required final String submissionId,
    @JsonKey(name: 'evaluator_id') final String? evaluatorId,
    final double? score,
    final String? feedback,
    final Map<String, dynamic>? remarks,
    final String? decision,
    @JsonKey(name: 'evaluated_at') final DateTime? evaluatedAt,
  }) = _$RoundEvaluationImpl;

  factory _RoundEvaluation.fromJson(Map<String, dynamic> json) =
      _$RoundEvaluationImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'submission_id')
  String get submissionId;
  @override
  @JsonKey(name: 'evaluator_id')
  String? get evaluatorId;
  @override
  double? get score;
  @override
  String? get feedback;
  @override
  Map<String, dynamic>? get remarks;
  @override
  String? get decision;
  @override
  @JsonKey(name: 'evaluated_at')
  DateTime? get evaluatedAt;

  /// Create a copy of RoundEvaluation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoundEvaluationImplCopyWith<_$RoundEvaluationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
