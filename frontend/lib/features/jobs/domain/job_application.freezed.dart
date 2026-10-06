// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_application.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

JobApplication _$JobApplicationFromJson(Map<String, dynamic> json) {
  return _JobApplication.fromJson(json);
}

/// @nodoc
mixin _$JobApplication {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'job_id')
  String get jobId => throw _privateConstructorUsedError;
  @JsonKey(name: 'student_id')
  String get studentId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_round')
  int get currentRound => throw _privateConstructorUsedError;
  @JsonKey(name: 'resume_url')
  String? get resumeUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'cover_letter')
  String? get coverLetter => throw _privateConstructorUsedError;
  @JsonKey(name: 'profile_snapshot')
  Map<String, dynamic>? get profileSnapshot =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'cover_note')
  String? get coverNote => throw _privateConstructorUsedError;
  @JsonKey(name: 'video_responses')
  List<Map<String, dynamic>>? get videoResponses =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'overall_score')
  double? get overallScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'applied_at')
  DateTime get createdAt => throw _privateConstructorUsedError; // Joined data
  Job? get job => throw _privateConstructorUsedError;
  Map<String, dynamic>? get student => throw _privateConstructorUsedError;
  List<JobRound>? get rounds => throw _privateConstructorUsedError;
  List<RoundSubmission>? get submissions => throw _privateConstructorUsedError;
  Offer? get offer => throw _privateConstructorUsedError;

  /// Serializes this JobApplication to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JobApplication
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JobApplicationCopyWith<JobApplication> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JobApplicationCopyWith<$Res> {
  factory $JobApplicationCopyWith(
    JobApplication value,
    $Res Function(JobApplication) then,
  ) = _$JobApplicationCopyWithImpl<$Res, JobApplication>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'job_id') String jobId,
    @JsonKey(name: 'student_id') String studentId,
    String status,
    @JsonKey(name: 'current_round') int currentRound,
    @JsonKey(name: 'resume_url') String? resumeUrl,
    @JsonKey(name: 'cover_letter') String? coverLetter,
    @JsonKey(name: 'profile_snapshot') Map<String, dynamic>? profileSnapshot,
    @JsonKey(name: 'cover_note') String? coverNote,
    @JsonKey(name: 'video_responses')
    List<Map<String, dynamic>>? videoResponses,
    @JsonKey(name: 'overall_score') double? overallScore,
    @JsonKey(name: 'applied_at') DateTime createdAt,
    Job? job,
    Map<String, dynamic>? student,
    List<JobRound>? rounds,
    List<RoundSubmission>? submissions,
    Offer? offer,
  });

  $JobCopyWith<$Res>? get job;
  $OfferCopyWith<$Res>? get offer;
}

/// @nodoc
class _$JobApplicationCopyWithImpl<$Res, $Val extends JobApplication>
    implements $JobApplicationCopyWith<$Res> {
  _$JobApplicationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JobApplication
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? jobId = null,
    Object? studentId = null,
    Object? status = null,
    Object? currentRound = null,
    Object? resumeUrl = freezed,
    Object? coverLetter = freezed,
    Object? profileSnapshot = freezed,
    Object? coverNote = freezed,
    Object? videoResponses = freezed,
    Object? overallScore = freezed,
    Object? createdAt = null,
    Object? job = freezed,
    Object? student = freezed,
    Object? rounds = freezed,
    Object? submissions = freezed,
    Object? offer = freezed,
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
            studentId: null == studentId
                ? _value.studentId
                : studentId // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            currentRound: null == currentRound
                ? _value.currentRound
                : currentRound // ignore: cast_nullable_to_non_nullable
                      as int,
            resumeUrl: freezed == resumeUrl
                ? _value.resumeUrl
                : resumeUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            coverLetter: freezed == coverLetter
                ? _value.coverLetter
                : coverLetter // ignore: cast_nullable_to_non_nullable
                      as String?,
            profileSnapshot: freezed == profileSnapshot
                ? _value.profileSnapshot
                : profileSnapshot // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            coverNote: freezed == coverNote
                ? _value.coverNote
                : coverNote // ignore: cast_nullable_to_non_nullable
                      as String?,
            videoResponses: freezed == videoResponses
                ? _value.videoResponses
                : videoResponses // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>?,
            overallScore: freezed == overallScore
                ? _value.overallScore
                : overallScore // ignore: cast_nullable_to_non_nullable
                      as double?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            job: freezed == job
                ? _value.job
                : job // ignore: cast_nullable_to_non_nullable
                      as Job?,
            student: freezed == student
                ? _value.student
                : student // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            rounds: freezed == rounds
                ? _value.rounds
                : rounds // ignore: cast_nullable_to_non_nullable
                      as List<JobRound>?,
            submissions: freezed == submissions
                ? _value.submissions
                : submissions // ignore: cast_nullable_to_non_nullable
                      as List<RoundSubmission>?,
            offer: freezed == offer
                ? _value.offer
                : offer // ignore: cast_nullable_to_non_nullable
                      as Offer?,
          )
          as $Val,
    );
  }

  /// Create a copy of JobApplication
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JobCopyWith<$Res>? get job {
    if (_value.job == null) {
      return null;
    }

    return $JobCopyWith<$Res>(_value.job!, (value) {
      return _then(_value.copyWith(job: value) as $Val);
    });
  }

  /// Create a copy of JobApplication
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OfferCopyWith<$Res>? get offer {
    if (_value.offer == null) {
      return null;
    }

    return $OfferCopyWith<$Res>(_value.offer!, (value) {
      return _then(_value.copyWith(offer: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$JobApplicationImplCopyWith<$Res>
    implements $JobApplicationCopyWith<$Res> {
  factory _$$JobApplicationImplCopyWith(
    _$JobApplicationImpl value,
    $Res Function(_$JobApplicationImpl) then,
  ) = __$$JobApplicationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'job_id') String jobId,
    @JsonKey(name: 'student_id') String studentId,
    String status,
    @JsonKey(name: 'current_round') int currentRound,
    @JsonKey(name: 'resume_url') String? resumeUrl,
    @JsonKey(name: 'cover_letter') String? coverLetter,
    @JsonKey(name: 'profile_snapshot') Map<String, dynamic>? profileSnapshot,
    @JsonKey(name: 'cover_note') String? coverNote,
    @JsonKey(name: 'video_responses')
    List<Map<String, dynamic>>? videoResponses,
    @JsonKey(name: 'overall_score') double? overallScore,
    @JsonKey(name: 'applied_at') DateTime createdAt,
    Job? job,
    Map<String, dynamic>? student,
    List<JobRound>? rounds,
    List<RoundSubmission>? submissions,
    Offer? offer,
  });

  @override
  $JobCopyWith<$Res>? get job;
  @override
  $OfferCopyWith<$Res>? get offer;
}

/// @nodoc
class __$$JobApplicationImplCopyWithImpl<$Res>
    extends _$JobApplicationCopyWithImpl<$Res, _$JobApplicationImpl>
    implements _$$JobApplicationImplCopyWith<$Res> {
  __$$JobApplicationImplCopyWithImpl(
    _$JobApplicationImpl _value,
    $Res Function(_$JobApplicationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JobApplication
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? jobId = null,
    Object? studentId = null,
    Object? status = null,
    Object? currentRound = null,
    Object? resumeUrl = freezed,
    Object? coverLetter = freezed,
    Object? profileSnapshot = freezed,
    Object? coverNote = freezed,
    Object? videoResponses = freezed,
    Object? overallScore = freezed,
    Object? createdAt = null,
    Object? job = freezed,
    Object? student = freezed,
    Object? rounds = freezed,
    Object? submissions = freezed,
    Object? offer = freezed,
  }) {
    return _then(
      _$JobApplicationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        jobId: null == jobId
            ? _value.jobId
            : jobId // ignore: cast_nullable_to_non_nullable
                  as String,
        studentId: null == studentId
            ? _value.studentId
            : studentId // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        currentRound: null == currentRound
            ? _value.currentRound
            : currentRound // ignore: cast_nullable_to_non_nullable
                  as int,
        resumeUrl: freezed == resumeUrl
            ? _value.resumeUrl
            : resumeUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        coverLetter: freezed == coverLetter
            ? _value.coverLetter
            : coverLetter // ignore: cast_nullable_to_non_nullable
                  as String?,
        profileSnapshot: freezed == profileSnapshot
            ? _value._profileSnapshot
            : profileSnapshot // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        coverNote: freezed == coverNote
            ? _value.coverNote
            : coverNote // ignore: cast_nullable_to_non_nullable
                  as String?,
        videoResponses: freezed == videoResponses
            ? _value._videoResponses
            : videoResponses // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>?,
        overallScore: freezed == overallScore
            ? _value.overallScore
            : overallScore // ignore: cast_nullable_to_non_nullable
                  as double?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        job: freezed == job
            ? _value.job
            : job // ignore: cast_nullable_to_non_nullable
                  as Job?,
        student: freezed == student
            ? _value._student
            : student // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        rounds: freezed == rounds
            ? _value._rounds
            : rounds // ignore: cast_nullable_to_non_nullable
                  as List<JobRound>?,
        submissions: freezed == submissions
            ? _value._submissions
            : submissions // ignore: cast_nullable_to_non_nullable
                  as List<RoundSubmission>?,
        offer: freezed == offer
            ? _value.offer
            : offer // ignore: cast_nullable_to_non_nullable
                  as Offer?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$JobApplicationImpl extends _JobApplication {
  const _$JobApplicationImpl({
    required this.id,
    @JsonKey(name: 'job_id') required this.jobId,
    @JsonKey(name: 'student_id') required this.studentId,
    this.status = 'applied',
    @JsonKey(name: 'current_round') this.currentRound = 0,
    @JsonKey(name: 'resume_url') this.resumeUrl,
    @JsonKey(name: 'cover_letter') this.coverLetter,
    @JsonKey(name: 'profile_snapshot')
    final Map<String, dynamic>? profileSnapshot,
    @JsonKey(name: 'cover_note') this.coverNote,
    @JsonKey(name: 'video_responses')
    final List<Map<String, dynamic>>? videoResponses,
    @JsonKey(name: 'overall_score') this.overallScore,
    @JsonKey(name: 'applied_at') required this.createdAt,
    this.job,
    final Map<String, dynamic>? student,
    final List<JobRound>? rounds,
    final List<RoundSubmission>? submissions,
    this.offer,
  }) : _profileSnapshot = profileSnapshot,
       _videoResponses = videoResponses,
       _student = student,
       _rounds = rounds,
       _submissions = submissions,
       super._();

  factory _$JobApplicationImpl.fromJson(Map<String, dynamic> json) =>
      _$$JobApplicationImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'job_id')
  final String jobId;
  @override
  @JsonKey(name: 'student_id')
  final String studentId;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'current_round')
  final int currentRound;
  @override
  @JsonKey(name: 'resume_url')
  final String? resumeUrl;
  @override
  @JsonKey(name: 'cover_letter')
  final String? coverLetter;
  final Map<String, dynamic>? _profileSnapshot;
  @override
  @JsonKey(name: 'profile_snapshot')
  Map<String, dynamic>? get profileSnapshot {
    final value = _profileSnapshot;
    if (value == null) return null;
    if (_profileSnapshot is EqualUnmodifiableMapView) return _profileSnapshot;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'cover_note')
  final String? coverNote;
  final List<Map<String, dynamic>>? _videoResponses;
  @override
  @JsonKey(name: 'video_responses')
  List<Map<String, dynamic>>? get videoResponses {
    final value = _videoResponses;
    if (value == null) return null;
    if (_videoResponses is EqualUnmodifiableListView) return _videoResponses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'overall_score')
  final double? overallScore;
  @override
  @JsonKey(name: 'applied_at')
  final DateTime createdAt;
  // Joined data
  @override
  final Job? job;
  final Map<String, dynamic>? _student;
  @override
  Map<String, dynamic>? get student {
    final value = _student;
    if (value == null) return null;
    if (_student is EqualUnmodifiableMapView) return _student;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<JobRound>? _rounds;
  @override
  List<JobRound>? get rounds {
    final value = _rounds;
    if (value == null) return null;
    if (_rounds is EqualUnmodifiableListView) return _rounds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<RoundSubmission>? _submissions;
  @override
  List<RoundSubmission>? get submissions {
    final value = _submissions;
    if (value == null) return null;
    if (_submissions is EqualUnmodifiableListView) return _submissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final Offer? offer;

  @override
  String toString() {
    return 'JobApplication(id: $id, jobId: $jobId, studentId: $studentId, status: $status, currentRound: $currentRound, resumeUrl: $resumeUrl, coverLetter: $coverLetter, profileSnapshot: $profileSnapshot, coverNote: $coverNote, videoResponses: $videoResponses, overallScore: $overallScore, createdAt: $createdAt, job: $job, student: $student, rounds: $rounds, submissions: $submissions, offer: $offer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JobApplicationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.jobId, jobId) || other.jobId == jobId) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.currentRound, currentRound) ||
                other.currentRound == currentRound) &&
            (identical(other.resumeUrl, resumeUrl) ||
                other.resumeUrl == resumeUrl) &&
            (identical(other.coverLetter, coverLetter) ||
                other.coverLetter == coverLetter) &&
            const DeepCollectionEquality().equals(
              other._profileSnapshot,
              _profileSnapshot,
            ) &&
            (identical(other.coverNote, coverNote) ||
                other.coverNote == coverNote) &&
            const DeepCollectionEquality().equals(
              other._videoResponses,
              _videoResponses,
            ) &&
            (identical(other.overallScore, overallScore) ||
                other.overallScore == overallScore) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.job, job) || other.job == job) &&
            const DeepCollectionEquality().equals(other._student, _student) &&
            const DeepCollectionEquality().equals(other._rounds, _rounds) &&
            const DeepCollectionEquality().equals(
              other._submissions,
              _submissions,
            ) &&
            (identical(other.offer, offer) || other.offer == offer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    jobId,
    studentId,
    status,
    currentRound,
    resumeUrl,
    coverLetter,
    const DeepCollectionEquality().hash(_profileSnapshot),
    coverNote,
    const DeepCollectionEquality().hash(_videoResponses),
    overallScore,
    createdAt,
    job,
    const DeepCollectionEquality().hash(_student),
    const DeepCollectionEquality().hash(_rounds),
    const DeepCollectionEquality().hash(_submissions),
    offer,
  );

  /// Create a copy of JobApplication
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JobApplicationImplCopyWith<_$JobApplicationImpl> get copyWith =>
      __$$JobApplicationImplCopyWithImpl<_$JobApplicationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$JobApplicationImplToJson(this);
  }
}

abstract class _JobApplication extends JobApplication {
  const factory _JobApplication({
    required final String id,
    @JsonKey(name: 'job_id') required final String jobId,
    @JsonKey(name: 'student_id') required final String studentId,
    final String status,
    @JsonKey(name: 'current_round') final int currentRound,
    @JsonKey(name: 'resume_url') final String? resumeUrl,
    @JsonKey(name: 'cover_letter') final String? coverLetter,
    @JsonKey(name: 'profile_snapshot')
    final Map<String, dynamic>? profileSnapshot,
    @JsonKey(name: 'cover_note') final String? coverNote,
    @JsonKey(name: 'video_responses')
    final List<Map<String, dynamic>>? videoResponses,
    @JsonKey(name: 'overall_score') final double? overallScore,
    @JsonKey(name: 'applied_at') required final DateTime createdAt,
    final Job? job,
    final Map<String, dynamic>? student,
    final List<JobRound>? rounds,
    final List<RoundSubmission>? submissions,
    final Offer? offer,
  }) = _$JobApplicationImpl;
  const _JobApplication._() : super._();

  factory _JobApplication.fromJson(Map<String, dynamic> json) =
      _$JobApplicationImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'job_id')
  String get jobId;
  @override
  @JsonKey(name: 'student_id')
  String get studentId;
  @override
  String get status;
  @override
  @JsonKey(name: 'current_round')
  int get currentRound;
  @override
  @JsonKey(name: 'resume_url')
  String? get resumeUrl;
  @override
  @JsonKey(name: 'cover_letter')
  String? get coverLetter;
  @override
  @JsonKey(name: 'profile_snapshot')
  Map<String, dynamic>? get profileSnapshot;
  @override
  @JsonKey(name: 'cover_note')
  String? get coverNote;
  @override
  @JsonKey(name: 'video_responses')
  List<Map<String, dynamic>>? get videoResponses;
  @override
  @JsonKey(name: 'overall_score')
  double? get overallScore;
  @override
  @JsonKey(name: 'applied_at')
  DateTime get createdAt; // Joined data
  @override
  Job? get job;
  @override
  Map<String, dynamic>? get student;
  @override
  List<JobRound>? get rounds;
  @override
  List<RoundSubmission>? get submissions;
  @override
  Offer? get offer;

  /// Create a copy of JobApplication
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JobApplicationImplCopyWith<_$JobApplicationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
