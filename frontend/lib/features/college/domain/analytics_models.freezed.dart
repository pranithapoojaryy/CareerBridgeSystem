// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CollegeAnalytics _$CollegeAnalyticsFromJson(Map<String, dynamic> json) {
  return _CollegeAnalytics.fromJson(json);
}

/// @nodoc
mixin _$CollegeAnalytics {
  int get totalStudents => throw _privateConstructorUsedError;
  int get activeStudents => throw _privateConstructorUsedError;
  int get connectedCompanies => throw _privateConstructorUsedError;
  int get pendingCompanyRequests => throw _privateConstructorUsedError;
  int get studentsInMock => throw _privateConstructorUsedError;
  int get mockInterviewsTaken => throw _privateConstructorUsedError;
  int get studentsSelected => throw _privateConstructorUsedError;
  List<EnrollmentTrend> get enrollmentTrends =>
      throw _privateConstructorUsedError;
  List<DeptPlacementStats> get departmentStats =>
      throw _privateConstructorUsedError;
  List<CompanyPlacementInfo> get topCompanies =>
      throw _privateConstructorUsedError;
  List<StudentPlacementInfo> get recentPlacements =>
      throw _privateConstructorUsedError;
  ApplicationFunnel get applicationFunnel => throw _privateConstructorUsedError;
  int get activeAssignments => throw _privateConstructorUsedError;
  int get totalCollegeCourses => throw _privateConstructorUsedError;
  List<EngagementMetric> get engagementMetrics =>
      throw _privateConstructorUsedError;

  /// Serializes this CollegeAnalytics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CollegeAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CollegeAnalyticsCopyWith<CollegeAnalytics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CollegeAnalyticsCopyWith<$Res> {
  factory $CollegeAnalyticsCopyWith(
    CollegeAnalytics value,
    $Res Function(CollegeAnalytics) then,
  ) = _$CollegeAnalyticsCopyWithImpl<$Res, CollegeAnalytics>;
  @useResult
  $Res call({
    int totalStudents,
    int activeStudents,
    int connectedCompanies,
    int pendingCompanyRequests,
    int studentsInMock,
    int mockInterviewsTaken,
    int studentsSelected,
    List<EnrollmentTrend> enrollmentTrends,
    List<DeptPlacementStats> departmentStats,
    List<CompanyPlacementInfo> topCompanies,
    List<StudentPlacementInfo> recentPlacements,
    ApplicationFunnel applicationFunnel,
    int activeAssignments,
    int totalCollegeCourses,
    List<EngagementMetric> engagementMetrics,
  });

  $ApplicationFunnelCopyWith<$Res> get applicationFunnel;
}

/// @nodoc
class _$CollegeAnalyticsCopyWithImpl<$Res, $Val extends CollegeAnalytics>
    implements $CollegeAnalyticsCopyWith<$Res> {
  _$CollegeAnalyticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CollegeAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalStudents = null,
    Object? activeStudents = null,
    Object? connectedCompanies = null,
    Object? pendingCompanyRequests = null,
    Object? studentsInMock = null,
    Object? mockInterviewsTaken = null,
    Object? studentsSelected = null,
    Object? enrollmentTrends = null,
    Object? departmentStats = null,
    Object? topCompanies = null,
    Object? recentPlacements = null,
    Object? applicationFunnel = null,
    Object? activeAssignments = null,
    Object? totalCollegeCourses = null,
    Object? engagementMetrics = null,
  }) {
    return _then(
      _value.copyWith(
            totalStudents: null == totalStudents
                ? _value.totalStudents
                : totalStudents // ignore: cast_nullable_to_non_nullable
                      as int,
            activeStudents: null == activeStudents
                ? _value.activeStudents
                : activeStudents // ignore: cast_nullable_to_non_nullable
                      as int,
            connectedCompanies: null == connectedCompanies
                ? _value.connectedCompanies
                : connectedCompanies // ignore: cast_nullable_to_non_nullable
                      as int,
            pendingCompanyRequests: null == pendingCompanyRequests
                ? _value.pendingCompanyRequests
                : pendingCompanyRequests // ignore: cast_nullable_to_non_nullable
                      as int,
            studentsInMock: null == studentsInMock
                ? _value.studentsInMock
                : studentsInMock // ignore: cast_nullable_to_non_nullable
                      as int,
            mockInterviewsTaken: null == mockInterviewsTaken
                ? _value.mockInterviewsTaken
                : mockInterviewsTaken // ignore: cast_nullable_to_non_nullable
                      as int,
            studentsSelected: null == studentsSelected
                ? _value.studentsSelected
                : studentsSelected // ignore: cast_nullable_to_non_nullable
                      as int,
            enrollmentTrends: null == enrollmentTrends
                ? _value.enrollmentTrends
                : enrollmentTrends // ignore: cast_nullable_to_non_nullable
                      as List<EnrollmentTrend>,
            departmentStats: null == departmentStats
                ? _value.departmentStats
                : departmentStats // ignore: cast_nullable_to_non_nullable
                      as List<DeptPlacementStats>,
            topCompanies: null == topCompanies
                ? _value.topCompanies
                : topCompanies // ignore: cast_nullable_to_non_nullable
                      as List<CompanyPlacementInfo>,
            recentPlacements: null == recentPlacements
                ? _value.recentPlacements
                : recentPlacements // ignore: cast_nullable_to_non_nullable
                      as List<StudentPlacementInfo>,
            applicationFunnel: null == applicationFunnel
                ? _value.applicationFunnel
                : applicationFunnel // ignore: cast_nullable_to_non_nullable
                      as ApplicationFunnel,
            activeAssignments: null == activeAssignments
                ? _value.activeAssignments
                : activeAssignments // ignore: cast_nullable_to_non_nullable
                      as int,
            totalCollegeCourses: null == totalCollegeCourses
                ? _value.totalCollegeCourses
                : totalCollegeCourses // ignore: cast_nullable_to_non_nullable
                      as int,
            engagementMetrics: null == engagementMetrics
                ? _value.engagementMetrics
                : engagementMetrics // ignore: cast_nullable_to_non_nullable
                      as List<EngagementMetric>,
          )
          as $Val,
    );
  }

  /// Create a copy of CollegeAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ApplicationFunnelCopyWith<$Res> get applicationFunnel {
    return $ApplicationFunnelCopyWith<$Res>(_value.applicationFunnel, (value) {
      return _then(_value.copyWith(applicationFunnel: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CollegeAnalyticsImplCopyWith<$Res>
    implements $CollegeAnalyticsCopyWith<$Res> {
  factory _$$CollegeAnalyticsImplCopyWith(
    _$CollegeAnalyticsImpl value,
    $Res Function(_$CollegeAnalyticsImpl) then,
  ) = __$$CollegeAnalyticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalStudents,
    int activeStudents,
    int connectedCompanies,
    int pendingCompanyRequests,
    int studentsInMock,
    int mockInterviewsTaken,
    int studentsSelected,
    List<EnrollmentTrend> enrollmentTrends,
    List<DeptPlacementStats> departmentStats,
    List<CompanyPlacementInfo> topCompanies,
    List<StudentPlacementInfo> recentPlacements,
    ApplicationFunnel applicationFunnel,
    int activeAssignments,
    int totalCollegeCourses,
    List<EngagementMetric> engagementMetrics,
  });

  @override
  $ApplicationFunnelCopyWith<$Res> get applicationFunnel;
}

/// @nodoc
class __$$CollegeAnalyticsImplCopyWithImpl<$Res>
    extends _$CollegeAnalyticsCopyWithImpl<$Res, _$CollegeAnalyticsImpl>
    implements _$$CollegeAnalyticsImplCopyWith<$Res> {
  __$$CollegeAnalyticsImplCopyWithImpl(
    _$CollegeAnalyticsImpl _value,
    $Res Function(_$CollegeAnalyticsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CollegeAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalStudents = null,
    Object? activeStudents = null,
    Object? connectedCompanies = null,
    Object? pendingCompanyRequests = null,
    Object? studentsInMock = null,
    Object? mockInterviewsTaken = null,
    Object? studentsSelected = null,
    Object? enrollmentTrends = null,
    Object? departmentStats = null,
    Object? topCompanies = null,
    Object? recentPlacements = null,
    Object? applicationFunnel = null,
    Object? activeAssignments = null,
    Object? totalCollegeCourses = null,
    Object? engagementMetrics = null,
  }) {
    return _then(
      _$CollegeAnalyticsImpl(
        totalStudents: null == totalStudents
            ? _value.totalStudents
            : totalStudents // ignore: cast_nullable_to_non_nullable
                  as int,
        activeStudents: null == activeStudents
            ? _value.activeStudents
            : activeStudents // ignore: cast_nullable_to_non_nullable
                  as int,
        connectedCompanies: null == connectedCompanies
            ? _value.connectedCompanies
            : connectedCompanies // ignore: cast_nullable_to_non_nullable
                  as int,
        pendingCompanyRequests: null == pendingCompanyRequests
            ? _value.pendingCompanyRequests
            : pendingCompanyRequests // ignore: cast_nullable_to_non_nullable
                  as int,
        studentsInMock: null == studentsInMock
            ? _value.studentsInMock
            : studentsInMock // ignore: cast_nullable_to_non_nullable
                  as int,
        mockInterviewsTaken: null == mockInterviewsTaken
            ? _value.mockInterviewsTaken
            : mockInterviewsTaken // ignore: cast_nullable_to_non_nullable
                  as int,
        studentsSelected: null == studentsSelected
            ? _value.studentsSelected
            : studentsSelected // ignore: cast_nullable_to_non_nullable
                  as int,
        enrollmentTrends: null == enrollmentTrends
            ? _value._enrollmentTrends
            : enrollmentTrends // ignore: cast_nullable_to_non_nullable
                  as List<EnrollmentTrend>,
        departmentStats: null == departmentStats
            ? _value._departmentStats
            : departmentStats // ignore: cast_nullable_to_non_nullable
                  as List<DeptPlacementStats>,
        topCompanies: null == topCompanies
            ? _value._topCompanies
            : topCompanies // ignore: cast_nullable_to_non_nullable
                  as List<CompanyPlacementInfo>,
        recentPlacements: null == recentPlacements
            ? _value._recentPlacements
            : recentPlacements // ignore: cast_nullable_to_non_nullable
                  as List<StudentPlacementInfo>,
        applicationFunnel: null == applicationFunnel
            ? _value.applicationFunnel
            : applicationFunnel // ignore: cast_nullable_to_non_nullable
                  as ApplicationFunnel,
        activeAssignments: null == activeAssignments
            ? _value.activeAssignments
            : activeAssignments // ignore: cast_nullable_to_non_nullable
                  as int,
        totalCollegeCourses: null == totalCollegeCourses
            ? _value.totalCollegeCourses
            : totalCollegeCourses // ignore: cast_nullable_to_non_nullable
                  as int,
        engagementMetrics: null == engagementMetrics
            ? _value._engagementMetrics
            : engagementMetrics // ignore: cast_nullable_to_non_nullable
                  as List<EngagementMetric>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CollegeAnalyticsImpl implements _CollegeAnalytics {
  const _$CollegeAnalyticsImpl({
    required this.totalStudents,
    required this.activeStudents,
    required this.connectedCompanies,
    required this.pendingCompanyRequests,
    required this.studentsInMock,
    required this.mockInterviewsTaken,
    required this.studentsSelected,
    required final List<EnrollmentTrend> enrollmentTrends,
    required final List<DeptPlacementStats> departmentStats,
    required final List<CompanyPlacementInfo> topCompanies,
    required final List<StudentPlacementInfo> recentPlacements,
    required this.applicationFunnel,
    required this.activeAssignments,
    required this.totalCollegeCourses,
    required final List<EngagementMetric> engagementMetrics,
  }) : _enrollmentTrends = enrollmentTrends,
       _departmentStats = departmentStats,
       _topCompanies = topCompanies,
       _recentPlacements = recentPlacements,
       _engagementMetrics = engagementMetrics;

  factory _$CollegeAnalyticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CollegeAnalyticsImplFromJson(json);

  @override
  final int totalStudents;
  @override
  final int activeStudents;
  @override
  final int connectedCompanies;
  @override
  final int pendingCompanyRequests;
  @override
  final int studentsInMock;
  @override
  final int mockInterviewsTaken;
  @override
  final int studentsSelected;
  final List<EnrollmentTrend> _enrollmentTrends;
  @override
  List<EnrollmentTrend> get enrollmentTrends {
    if (_enrollmentTrends is EqualUnmodifiableListView)
      return _enrollmentTrends;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_enrollmentTrends);
  }

  final List<DeptPlacementStats> _departmentStats;
  @override
  List<DeptPlacementStats> get departmentStats {
    if (_departmentStats is EqualUnmodifiableListView) return _departmentStats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_departmentStats);
  }

  final List<CompanyPlacementInfo> _topCompanies;
  @override
  List<CompanyPlacementInfo> get topCompanies {
    if (_topCompanies is EqualUnmodifiableListView) return _topCompanies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topCompanies);
  }

  final List<StudentPlacementInfo> _recentPlacements;
  @override
  List<StudentPlacementInfo> get recentPlacements {
    if (_recentPlacements is EqualUnmodifiableListView)
      return _recentPlacements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentPlacements);
  }

  @override
  final ApplicationFunnel applicationFunnel;
  @override
  final int activeAssignments;
  @override
  final int totalCollegeCourses;
  final List<EngagementMetric> _engagementMetrics;
  @override
  List<EngagementMetric> get engagementMetrics {
    if (_engagementMetrics is EqualUnmodifiableListView)
      return _engagementMetrics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_engagementMetrics);
  }

  @override
  String toString() {
    return 'CollegeAnalytics(totalStudents: $totalStudents, activeStudents: $activeStudents, connectedCompanies: $connectedCompanies, pendingCompanyRequests: $pendingCompanyRequests, studentsInMock: $studentsInMock, mockInterviewsTaken: $mockInterviewsTaken, studentsSelected: $studentsSelected, enrollmentTrends: $enrollmentTrends, departmentStats: $departmentStats, topCompanies: $topCompanies, recentPlacements: $recentPlacements, applicationFunnel: $applicationFunnel, activeAssignments: $activeAssignments, totalCollegeCourses: $totalCollegeCourses, engagementMetrics: $engagementMetrics)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollegeAnalyticsImpl &&
            (identical(other.totalStudents, totalStudents) ||
                other.totalStudents == totalStudents) &&
            (identical(other.activeStudents, activeStudents) ||
                other.activeStudents == activeStudents) &&
            (identical(other.connectedCompanies, connectedCompanies) ||
                other.connectedCompanies == connectedCompanies) &&
            (identical(other.pendingCompanyRequests, pendingCompanyRequests) ||
                other.pendingCompanyRequests == pendingCompanyRequests) &&
            (identical(other.studentsInMock, studentsInMock) ||
                other.studentsInMock == studentsInMock) &&
            (identical(other.mockInterviewsTaken, mockInterviewsTaken) ||
                other.mockInterviewsTaken == mockInterviewsTaken) &&
            (identical(other.studentsSelected, studentsSelected) ||
                other.studentsSelected == studentsSelected) &&
            const DeepCollectionEquality().equals(
              other._enrollmentTrends,
              _enrollmentTrends,
            ) &&
            const DeepCollectionEquality().equals(
              other._departmentStats,
              _departmentStats,
            ) &&
            const DeepCollectionEquality().equals(
              other._topCompanies,
              _topCompanies,
            ) &&
            const DeepCollectionEquality().equals(
              other._recentPlacements,
              _recentPlacements,
            ) &&
            (identical(other.applicationFunnel, applicationFunnel) ||
                other.applicationFunnel == applicationFunnel) &&
            (identical(other.activeAssignments, activeAssignments) ||
                other.activeAssignments == activeAssignments) &&
            (identical(other.totalCollegeCourses, totalCollegeCourses) ||
                other.totalCollegeCourses == totalCollegeCourses) &&
            const DeepCollectionEquality().equals(
              other._engagementMetrics,
              _engagementMetrics,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalStudents,
    activeStudents,
    connectedCompanies,
    pendingCompanyRequests,
    studentsInMock,
    mockInterviewsTaken,
    studentsSelected,
    const DeepCollectionEquality().hash(_enrollmentTrends),
    const DeepCollectionEquality().hash(_departmentStats),
    const DeepCollectionEquality().hash(_topCompanies),
    const DeepCollectionEquality().hash(_recentPlacements),
    applicationFunnel,
    activeAssignments,
    totalCollegeCourses,
    const DeepCollectionEquality().hash(_engagementMetrics),
  );

  /// Create a copy of CollegeAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CollegeAnalyticsImplCopyWith<_$CollegeAnalyticsImpl> get copyWith =>
      __$$CollegeAnalyticsImplCopyWithImpl<_$CollegeAnalyticsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CollegeAnalyticsImplToJson(this);
  }
}

abstract class _CollegeAnalytics implements CollegeAnalytics {
  const factory _CollegeAnalytics({
    required final int totalStudents,
    required final int activeStudents,
    required final int connectedCompanies,
    required final int pendingCompanyRequests,
    required final int studentsInMock,
    required final int mockInterviewsTaken,
    required final int studentsSelected,
    required final List<EnrollmentTrend> enrollmentTrends,
    required final List<DeptPlacementStats> departmentStats,
    required final List<CompanyPlacementInfo> topCompanies,
    required final List<StudentPlacementInfo> recentPlacements,
    required final ApplicationFunnel applicationFunnel,
    required final int activeAssignments,
    required final int totalCollegeCourses,
    required final List<EngagementMetric> engagementMetrics,
  }) = _$CollegeAnalyticsImpl;

  factory _CollegeAnalytics.fromJson(Map<String, dynamic> json) =
      _$CollegeAnalyticsImpl.fromJson;

  @override
  int get totalStudents;
  @override
  int get activeStudents;
  @override
  int get connectedCompanies;
  @override
  int get pendingCompanyRequests;
  @override
  int get studentsInMock;
  @override
  int get mockInterviewsTaken;
  @override
  int get studentsSelected;
  @override
  List<EnrollmentTrend> get enrollmentTrends;
  @override
  List<DeptPlacementStats> get departmentStats;
  @override
  List<CompanyPlacementInfo> get topCompanies;
  @override
  List<StudentPlacementInfo> get recentPlacements;
  @override
  ApplicationFunnel get applicationFunnel;
  @override
  int get activeAssignments;
  @override
  int get totalCollegeCourses;
  @override
  List<EngagementMetric> get engagementMetrics;

  /// Create a copy of CollegeAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CollegeAnalyticsImplCopyWith<_$CollegeAnalyticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EnrollmentTrend _$EnrollmentTrendFromJson(Map<String, dynamic> json) {
  return _EnrollmentTrend.fromJson(json);
}

/// @nodoc
mixin _$EnrollmentTrend {
  DateTime get date => throw _privateConstructorUsedError;
  int get enrollments => throw _privateConstructorUsedError;
  int get completions => throw _privateConstructorUsedError;

  /// Serializes this EnrollmentTrend to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EnrollmentTrend
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EnrollmentTrendCopyWith<EnrollmentTrend> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EnrollmentTrendCopyWith<$Res> {
  factory $EnrollmentTrendCopyWith(
    EnrollmentTrend value,
    $Res Function(EnrollmentTrend) then,
  ) = _$EnrollmentTrendCopyWithImpl<$Res, EnrollmentTrend>;
  @useResult
  $Res call({DateTime date, int enrollments, int completions});
}

/// @nodoc
class _$EnrollmentTrendCopyWithImpl<$Res, $Val extends EnrollmentTrend>
    implements $EnrollmentTrendCopyWith<$Res> {
  _$EnrollmentTrendCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EnrollmentTrend
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? enrollments = null,
    Object? completions = null,
  }) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            enrollments: null == enrollments
                ? _value.enrollments
                : enrollments // ignore: cast_nullable_to_non_nullable
                      as int,
            completions: null == completions
                ? _value.completions
                : completions // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EnrollmentTrendImplCopyWith<$Res>
    implements $EnrollmentTrendCopyWith<$Res> {
  factory _$$EnrollmentTrendImplCopyWith(
    _$EnrollmentTrendImpl value,
    $Res Function(_$EnrollmentTrendImpl) then,
  ) = __$$EnrollmentTrendImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime date, int enrollments, int completions});
}

/// @nodoc
class __$$EnrollmentTrendImplCopyWithImpl<$Res>
    extends _$EnrollmentTrendCopyWithImpl<$Res, _$EnrollmentTrendImpl>
    implements _$$EnrollmentTrendImplCopyWith<$Res> {
  __$$EnrollmentTrendImplCopyWithImpl(
    _$EnrollmentTrendImpl _value,
    $Res Function(_$EnrollmentTrendImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EnrollmentTrend
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? enrollments = null,
    Object? completions = null,
  }) {
    return _then(
      _$EnrollmentTrendImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        enrollments: null == enrollments
            ? _value.enrollments
            : enrollments // ignore: cast_nullable_to_non_nullable
                  as int,
        completions: null == completions
            ? _value.completions
            : completions // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EnrollmentTrendImpl implements _EnrollmentTrend {
  const _$EnrollmentTrendImpl({
    required this.date,
    required this.enrollments,
    required this.completions,
  });

  factory _$EnrollmentTrendImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnrollmentTrendImplFromJson(json);

  @override
  final DateTime date;
  @override
  final int enrollments;
  @override
  final int completions;

  @override
  String toString() {
    return 'EnrollmentTrend(date: $date, enrollments: $enrollments, completions: $completions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnrollmentTrendImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.enrollments, enrollments) ||
                other.enrollments == enrollments) &&
            (identical(other.completions, completions) ||
                other.completions == completions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, date, enrollments, completions);

  /// Create a copy of EnrollmentTrend
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EnrollmentTrendImplCopyWith<_$EnrollmentTrendImpl> get copyWith =>
      __$$EnrollmentTrendImplCopyWithImpl<_$EnrollmentTrendImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$EnrollmentTrendImplToJson(this);
  }
}

abstract class _EnrollmentTrend implements EnrollmentTrend {
  const factory _EnrollmentTrend({
    required final DateTime date,
    required final int enrollments,
    required final int completions,
  }) = _$EnrollmentTrendImpl;

  factory _EnrollmentTrend.fromJson(Map<String, dynamic> json) =
      _$EnrollmentTrendImpl.fromJson;

  @override
  DateTime get date;
  @override
  int get enrollments;
  @override
  int get completions;

  /// Create a copy of EnrollmentTrend
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EnrollmentTrendImplCopyWith<_$EnrollmentTrendImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EngagementMetric _$EngagementMetricFromJson(Map<String, dynamic> json) {
  return _EngagementMetric.fromJson(json);
}

/// @nodoc
mixin _$EngagementMetric {
  String get label => throw _privateConstructorUsedError;
  int get value => throw _privateConstructorUsedError;
  double get percentage => throw _privateConstructorUsedError;

  /// Serializes this EngagementMetric to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EngagementMetric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EngagementMetricCopyWith<EngagementMetric> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EngagementMetricCopyWith<$Res> {
  factory $EngagementMetricCopyWith(
    EngagementMetric value,
    $Res Function(EngagementMetric) then,
  ) = _$EngagementMetricCopyWithImpl<$Res, EngagementMetric>;
  @useResult
  $Res call({String label, int value, double percentage});
}

/// @nodoc
class _$EngagementMetricCopyWithImpl<$Res, $Val extends EngagementMetric>
    implements $EngagementMetricCopyWith<$Res> {
  _$EngagementMetricCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EngagementMetric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? value = null,
    Object? percentage = null,
  }) {
    return _then(
      _value.copyWith(
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as int,
            percentage: null == percentage
                ? _value.percentage
                : percentage // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EngagementMetricImplCopyWith<$Res>
    implements $EngagementMetricCopyWith<$Res> {
  factory _$$EngagementMetricImplCopyWith(
    _$EngagementMetricImpl value,
    $Res Function(_$EngagementMetricImpl) then,
  ) = __$$EngagementMetricImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String label, int value, double percentage});
}

/// @nodoc
class __$$EngagementMetricImplCopyWithImpl<$Res>
    extends _$EngagementMetricCopyWithImpl<$Res, _$EngagementMetricImpl>
    implements _$$EngagementMetricImplCopyWith<$Res> {
  __$$EngagementMetricImplCopyWithImpl(
    _$EngagementMetricImpl _value,
    $Res Function(_$EngagementMetricImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EngagementMetric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? value = null,
    Object? percentage = null,
  }) {
    return _then(
      _$EngagementMetricImpl(
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as int,
        percentage: null == percentage
            ? _value.percentage
            : percentage // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EngagementMetricImpl implements _EngagementMetric {
  const _$EngagementMetricImpl({
    required this.label,
    required this.value,
    required this.percentage,
  });

  factory _$EngagementMetricImpl.fromJson(Map<String, dynamic> json) =>
      _$$EngagementMetricImplFromJson(json);

  @override
  final String label;
  @override
  final int value;
  @override
  final double percentage;

  @override
  String toString() {
    return 'EngagementMetric(label: $label, value: $value, percentage: $percentage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EngagementMetricImpl &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, label, value, percentage);

  /// Create a copy of EngagementMetric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EngagementMetricImplCopyWith<_$EngagementMetricImpl> get copyWith =>
      __$$EngagementMetricImplCopyWithImpl<_$EngagementMetricImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$EngagementMetricImplToJson(this);
  }
}

abstract class _EngagementMetric implements EngagementMetric {
  const factory _EngagementMetric({
    required final String label,
    required final int value,
    required final double percentage,
  }) = _$EngagementMetricImpl;

  factory _EngagementMetric.fromJson(Map<String, dynamic> json) =
      _$EngagementMetricImpl.fromJson;

  @override
  String get label;
  @override
  int get value;
  @override
  double get percentage;

  /// Create a copy of EngagementMetric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EngagementMetricImplCopyWith<_$EngagementMetricImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DeptPlacementStats _$DeptPlacementStatsFromJson(Map<String, dynamic> json) {
  return _DeptPlacementStats.fromJson(json);
}

/// @nodoc
mixin _$DeptPlacementStats {
  String get department => throw _privateConstructorUsedError;
  int get totalStudents => throw _privateConstructorUsedError;
  int get placedStudents => throw _privateConstructorUsedError;
  double get placementRate => throw _privateConstructorUsedError;

  /// Serializes this DeptPlacementStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeptPlacementStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeptPlacementStatsCopyWith<DeptPlacementStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeptPlacementStatsCopyWith<$Res> {
  factory $DeptPlacementStatsCopyWith(
    DeptPlacementStats value,
    $Res Function(DeptPlacementStats) then,
  ) = _$DeptPlacementStatsCopyWithImpl<$Res, DeptPlacementStats>;
  @useResult
  $Res call({
    String department,
    int totalStudents,
    int placedStudents,
    double placementRate,
  });
}

/// @nodoc
class _$DeptPlacementStatsCopyWithImpl<$Res, $Val extends DeptPlacementStats>
    implements $DeptPlacementStatsCopyWith<$Res> {
  _$DeptPlacementStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeptPlacementStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? department = null,
    Object? totalStudents = null,
    Object? placedStudents = null,
    Object? placementRate = null,
  }) {
    return _then(
      _value.copyWith(
            department: null == department
                ? _value.department
                : department // ignore: cast_nullable_to_non_nullable
                      as String,
            totalStudents: null == totalStudents
                ? _value.totalStudents
                : totalStudents // ignore: cast_nullable_to_non_nullable
                      as int,
            placedStudents: null == placedStudents
                ? _value.placedStudents
                : placedStudents // ignore: cast_nullable_to_non_nullable
                      as int,
            placementRate: null == placementRate
                ? _value.placementRate
                : placementRate // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeptPlacementStatsImplCopyWith<$Res>
    implements $DeptPlacementStatsCopyWith<$Res> {
  factory _$$DeptPlacementStatsImplCopyWith(
    _$DeptPlacementStatsImpl value,
    $Res Function(_$DeptPlacementStatsImpl) then,
  ) = __$$DeptPlacementStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String department,
    int totalStudents,
    int placedStudents,
    double placementRate,
  });
}

/// @nodoc
class __$$DeptPlacementStatsImplCopyWithImpl<$Res>
    extends _$DeptPlacementStatsCopyWithImpl<$Res, _$DeptPlacementStatsImpl>
    implements _$$DeptPlacementStatsImplCopyWith<$Res> {
  __$$DeptPlacementStatsImplCopyWithImpl(
    _$DeptPlacementStatsImpl _value,
    $Res Function(_$DeptPlacementStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeptPlacementStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? department = null,
    Object? totalStudents = null,
    Object? placedStudents = null,
    Object? placementRate = null,
  }) {
    return _then(
      _$DeptPlacementStatsImpl(
        department: null == department
            ? _value.department
            : department // ignore: cast_nullable_to_non_nullable
                  as String,
        totalStudents: null == totalStudents
            ? _value.totalStudents
            : totalStudents // ignore: cast_nullable_to_non_nullable
                  as int,
        placedStudents: null == placedStudents
            ? _value.placedStudents
            : placedStudents // ignore: cast_nullable_to_non_nullable
                  as int,
        placementRate: null == placementRate
            ? _value.placementRate
            : placementRate // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DeptPlacementStatsImpl implements _DeptPlacementStats {
  const _$DeptPlacementStatsImpl({
    required this.department,
    required this.totalStudents,
    required this.placedStudents,
    required this.placementRate,
  });

  factory _$DeptPlacementStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeptPlacementStatsImplFromJson(json);

  @override
  final String department;
  @override
  final int totalStudents;
  @override
  final int placedStudents;
  @override
  final double placementRate;

  @override
  String toString() {
    return 'DeptPlacementStats(department: $department, totalStudents: $totalStudents, placedStudents: $placedStudents, placementRate: $placementRate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeptPlacementStatsImpl &&
            (identical(other.department, department) ||
                other.department == department) &&
            (identical(other.totalStudents, totalStudents) ||
                other.totalStudents == totalStudents) &&
            (identical(other.placedStudents, placedStudents) ||
                other.placedStudents == placedStudents) &&
            (identical(other.placementRate, placementRate) ||
                other.placementRate == placementRate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    department,
    totalStudents,
    placedStudents,
    placementRate,
  );

  /// Create a copy of DeptPlacementStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeptPlacementStatsImplCopyWith<_$DeptPlacementStatsImpl> get copyWith =>
      __$$DeptPlacementStatsImplCopyWithImpl<_$DeptPlacementStatsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DeptPlacementStatsImplToJson(this);
  }
}

abstract class _DeptPlacementStats implements DeptPlacementStats {
  const factory _DeptPlacementStats({
    required final String department,
    required final int totalStudents,
    required final int placedStudents,
    required final double placementRate,
  }) = _$DeptPlacementStatsImpl;

  factory _DeptPlacementStats.fromJson(Map<String, dynamic> json) =
      _$DeptPlacementStatsImpl.fromJson;

  @override
  String get department;
  @override
  int get totalStudents;
  @override
  int get placedStudents;
  @override
  double get placementRate;

  /// Create a copy of DeptPlacementStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeptPlacementStatsImplCopyWith<_$DeptPlacementStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CompanyPlacementInfo _$CompanyPlacementInfoFromJson(Map<String, dynamic> json) {
  return _CompanyPlacementInfo.fromJson(json);
}

/// @nodoc
mixin _$CompanyPlacementInfo {
  String get companyName => throw _privateConstructorUsedError;
  String? get logoUrl => throw _privateConstructorUsedError;
  int get applications => throw _privateConstructorUsedError;
  int get selections => throw _privateConstructorUsedError;
  double get selectionRate => throw _privateConstructorUsedError;
  double? get averagePackage => throw _privateConstructorUsedError;

  /// Serializes this CompanyPlacementInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompanyPlacementInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompanyPlacementInfoCopyWith<CompanyPlacementInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompanyPlacementInfoCopyWith<$Res> {
  factory $CompanyPlacementInfoCopyWith(
    CompanyPlacementInfo value,
    $Res Function(CompanyPlacementInfo) then,
  ) = _$CompanyPlacementInfoCopyWithImpl<$Res, CompanyPlacementInfo>;
  @useResult
  $Res call({
    String companyName,
    String? logoUrl,
    int applications,
    int selections,
    double selectionRate,
    double? averagePackage,
  });
}

/// @nodoc
class _$CompanyPlacementInfoCopyWithImpl<
  $Res,
  $Val extends CompanyPlacementInfo
>
    implements $CompanyPlacementInfoCopyWith<$Res> {
  _$CompanyPlacementInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompanyPlacementInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? companyName = null,
    Object? logoUrl = freezed,
    Object? applications = null,
    Object? selections = null,
    Object? selectionRate = null,
    Object? averagePackage = freezed,
  }) {
    return _then(
      _value.copyWith(
            companyName: null == companyName
                ? _value.companyName
                : companyName // ignore: cast_nullable_to_non_nullable
                      as String,
            logoUrl: freezed == logoUrl
                ? _value.logoUrl
                : logoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            applications: null == applications
                ? _value.applications
                : applications // ignore: cast_nullable_to_non_nullable
                      as int,
            selections: null == selections
                ? _value.selections
                : selections // ignore: cast_nullable_to_non_nullable
                      as int,
            selectionRate: null == selectionRate
                ? _value.selectionRate
                : selectionRate // ignore: cast_nullable_to_non_nullable
                      as double,
            averagePackage: freezed == averagePackage
                ? _value.averagePackage
                : averagePackage // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CompanyPlacementInfoImplCopyWith<$Res>
    implements $CompanyPlacementInfoCopyWith<$Res> {
  factory _$$CompanyPlacementInfoImplCopyWith(
    _$CompanyPlacementInfoImpl value,
    $Res Function(_$CompanyPlacementInfoImpl) then,
  ) = __$$CompanyPlacementInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String companyName,
    String? logoUrl,
    int applications,
    int selections,
    double selectionRate,
    double? averagePackage,
  });
}

/// @nodoc
class __$$CompanyPlacementInfoImplCopyWithImpl<$Res>
    extends _$CompanyPlacementInfoCopyWithImpl<$Res, _$CompanyPlacementInfoImpl>
    implements _$$CompanyPlacementInfoImplCopyWith<$Res> {
  __$$CompanyPlacementInfoImplCopyWithImpl(
    _$CompanyPlacementInfoImpl _value,
    $Res Function(_$CompanyPlacementInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompanyPlacementInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? companyName = null,
    Object? logoUrl = freezed,
    Object? applications = null,
    Object? selections = null,
    Object? selectionRate = null,
    Object? averagePackage = freezed,
  }) {
    return _then(
      _$CompanyPlacementInfoImpl(
        companyName: null == companyName
            ? _value.companyName
            : companyName // ignore: cast_nullable_to_non_nullable
                  as String,
        logoUrl: freezed == logoUrl
            ? _value.logoUrl
            : logoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        applications: null == applications
            ? _value.applications
            : applications // ignore: cast_nullable_to_non_nullable
                  as int,
        selections: null == selections
            ? _value.selections
            : selections // ignore: cast_nullable_to_non_nullable
                  as int,
        selectionRate: null == selectionRate
            ? _value.selectionRate
            : selectionRate // ignore: cast_nullable_to_non_nullable
                  as double,
        averagePackage: freezed == averagePackage
            ? _value.averagePackage
            : averagePackage // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CompanyPlacementInfoImpl implements _CompanyPlacementInfo {
  const _$CompanyPlacementInfoImpl({
    required this.companyName,
    this.logoUrl,
    required this.applications,
    required this.selections,
    required this.selectionRate,
    this.averagePackage,
  });

  factory _$CompanyPlacementInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompanyPlacementInfoImplFromJson(json);

  @override
  final String companyName;
  @override
  final String? logoUrl;
  @override
  final int applications;
  @override
  final int selections;
  @override
  final double selectionRate;
  @override
  final double? averagePackage;

  @override
  String toString() {
    return 'CompanyPlacementInfo(companyName: $companyName, logoUrl: $logoUrl, applications: $applications, selections: $selections, selectionRate: $selectionRate, averagePackage: $averagePackage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompanyPlacementInfoImpl &&
            (identical(other.companyName, companyName) ||
                other.companyName == companyName) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.applications, applications) ||
                other.applications == applications) &&
            (identical(other.selections, selections) ||
                other.selections == selections) &&
            (identical(other.selectionRate, selectionRate) ||
                other.selectionRate == selectionRate) &&
            (identical(other.averagePackage, averagePackage) ||
                other.averagePackage == averagePackage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    companyName,
    logoUrl,
    applications,
    selections,
    selectionRate,
    averagePackage,
  );

  /// Create a copy of CompanyPlacementInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompanyPlacementInfoImplCopyWith<_$CompanyPlacementInfoImpl>
  get copyWith =>
      __$$CompanyPlacementInfoImplCopyWithImpl<_$CompanyPlacementInfoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CompanyPlacementInfoImplToJson(this);
  }
}

abstract class _CompanyPlacementInfo implements CompanyPlacementInfo {
  const factory _CompanyPlacementInfo({
    required final String companyName,
    final String? logoUrl,
    required final int applications,
    required final int selections,
    required final double selectionRate,
    final double? averagePackage,
  }) = _$CompanyPlacementInfoImpl;

  factory _CompanyPlacementInfo.fromJson(Map<String, dynamic> json) =
      _$CompanyPlacementInfoImpl.fromJson;

  @override
  String get companyName;
  @override
  String? get logoUrl;
  @override
  int get applications;
  @override
  int get selections;
  @override
  double get selectionRate;
  @override
  double? get averagePackage;

  /// Create a copy of CompanyPlacementInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompanyPlacementInfoImplCopyWith<_$CompanyPlacementInfoImpl>
  get copyWith => throw _privateConstructorUsedError;
}

StudentPlacementInfo _$StudentPlacementInfoFromJson(Map<String, dynamic> json) {
  return _StudentPlacementInfo.fromJson(json);
}

/// @nodoc
mixin _$StudentPlacementInfo {
  String get studentId => throw _privateConstructorUsedError;
  String get studentName => throw _privateConstructorUsedError;
  String? get department => throw _privateConstructorUsedError;
  String? get batch => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int get mockAttempts => throw _privateConstructorUsedError;
  String get placedCompany => throw _privateConstructorUsedError;
  double? get packageAmount => throw _privateConstructorUsedError;

  /// Serializes this StudentPlacementInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StudentPlacementInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StudentPlacementInfoCopyWith<StudentPlacementInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudentPlacementInfoCopyWith<$Res> {
  factory $StudentPlacementInfoCopyWith(
    StudentPlacementInfo value,
    $Res Function(StudentPlacementInfo) then,
  ) = _$StudentPlacementInfoCopyWithImpl<$Res, StudentPlacementInfo>;
  @useResult
  $Res call({
    String studentId,
    String studentName,
    String? department,
    String? batch,
    String status,
    int mockAttempts,
    String placedCompany,
    double? packageAmount,
  });
}

/// @nodoc
class _$StudentPlacementInfoCopyWithImpl<
  $Res,
  $Val extends StudentPlacementInfo
>
    implements $StudentPlacementInfoCopyWith<$Res> {
  _$StudentPlacementInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StudentPlacementInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? studentName = null,
    Object? department = freezed,
    Object? batch = freezed,
    Object? status = null,
    Object? mockAttempts = null,
    Object? placedCompany = null,
    Object? packageAmount = freezed,
  }) {
    return _then(
      _value.copyWith(
            studentId: null == studentId
                ? _value.studentId
                : studentId // ignore: cast_nullable_to_non_nullable
                      as String,
            studentName: null == studentName
                ? _value.studentName
                : studentName // ignore: cast_nullable_to_non_nullable
                      as String,
            department: freezed == department
                ? _value.department
                : department // ignore: cast_nullable_to_non_nullable
                      as String?,
            batch: freezed == batch
                ? _value.batch
                : batch // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            mockAttempts: null == mockAttempts
                ? _value.mockAttempts
                : mockAttempts // ignore: cast_nullable_to_non_nullable
                      as int,
            placedCompany: null == placedCompany
                ? _value.placedCompany
                : placedCompany // ignore: cast_nullable_to_non_nullable
                      as String,
            packageAmount: freezed == packageAmount
                ? _value.packageAmount
                : packageAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StudentPlacementInfoImplCopyWith<$Res>
    implements $StudentPlacementInfoCopyWith<$Res> {
  factory _$$StudentPlacementInfoImplCopyWith(
    _$StudentPlacementInfoImpl value,
    $Res Function(_$StudentPlacementInfoImpl) then,
  ) = __$$StudentPlacementInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String studentId,
    String studentName,
    String? department,
    String? batch,
    String status,
    int mockAttempts,
    String placedCompany,
    double? packageAmount,
  });
}

/// @nodoc
class __$$StudentPlacementInfoImplCopyWithImpl<$Res>
    extends _$StudentPlacementInfoCopyWithImpl<$Res, _$StudentPlacementInfoImpl>
    implements _$$StudentPlacementInfoImplCopyWith<$Res> {
  __$$StudentPlacementInfoImplCopyWithImpl(
    _$StudentPlacementInfoImpl _value,
    $Res Function(_$StudentPlacementInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StudentPlacementInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? studentName = null,
    Object? department = freezed,
    Object? batch = freezed,
    Object? status = null,
    Object? mockAttempts = null,
    Object? placedCompany = null,
    Object? packageAmount = freezed,
  }) {
    return _then(
      _$StudentPlacementInfoImpl(
        studentId: null == studentId
            ? _value.studentId
            : studentId // ignore: cast_nullable_to_non_nullable
                  as String,
        studentName: null == studentName
            ? _value.studentName
            : studentName // ignore: cast_nullable_to_non_nullable
                  as String,
        department: freezed == department
            ? _value.department
            : department // ignore: cast_nullable_to_non_nullable
                  as String?,
        batch: freezed == batch
            ? _value.batch
            : batch // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        mockAttempts: null == mockAttempts
            ? _value.mockAttempts
            : mockAttempts // ignore: cast_nullable_to_non_nullable
                  as int,
        placedCompany: null == placedCompany
            ? _value.placedCompany
            : placedCompany // ignore: cast_nullable_to_non_nullable
                  as String,
        packageAmount: freezed == packageAmount
            ? _value.packageAmount
            : packageAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentPlacementInfoImpl implements _StudentPlacementInfo {
  const _$StudentPlacementInfoImpl({
    required this.studentId,
    required this.studentName,
    this.department,
    this.batch,
    required this.status,
    required this.mockAttempts,
    required this.placedCompany,
    this.packageAmount,
  });

  factory _$StudentPlacementInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentPlacementInfoImplFromJson(json);

  @override
  final String studentId;
  @override
  final String studentName;
  @override
  final String? department;
  @override
  final String? batch;
  @override
  final String status;
  @override
  final int mockAttempts;
  @override
  final String placedCompany;
  @override
  final double? packageAmount;

  @override
  String toString() {
    return 'StudentPlacementInfo(studentId: $studentId, studentName: $studentName, department: $department, batch: $batch, status: $status, mockAttempts: $mockAttempts, placedCompany: $placedCompany, packageAmount: $packageAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentPlacementInfoImpl &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.studentName, studentName) ||
                other.studentName == studentName) &&
            (identical(other.department, department) ||
                other.department == department) &&
            (identical(other.batch, batch) || other.batch == batch) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.mockAttempts, mockAttempts) ||
                other.mockAttempts == mockAttempts) &&
            (identical(other.placedCompany, placedCompany) ||
                other.placedCompany == placedCompany) &&
            (identical(other.packageAmount, packageAmount) ||
                other.packageAmount == packageAmount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    studentId,
    studentName,
    department,
    batch,
    status,
    mockAttempts,
    placedCompany,
    packageAmount,
  );

  /// Create a copy of StudentPlacementInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StudentPlacementInfoImplCopyWith<_$StudentPlacementInfoImpl>
  get copyWith =>
      __$$StudentPlacementInfoImplCopyWithImpl<_$StudentPlacementInfoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StudentPlacementInfoImplToJson(this);
  }
}

abstract class _StudentPlacementInfo implements StudentPlacementInfo {
  const factory _StudentPlacementInfo({
    required final String studentId,
    required final String studentName,
    final String? department,
    final String? batch,
    required final String status,
    required final int mockAttempts,
    required final String placedCompany,
    final double? packageAmount,
  }) = _$StudentPlacementInfoImpl;

  factory _StudentPlacementInfo.fromJson(Map<String, dynamic> json) =
      _$StudentPlacementInfoImpl.fromJson;

  @override
  String get studentId;
  @override
  String get studentName;
  @override
  String? get department;
  @override
  String? get batch;
  @override
  String get status;
  @override
  int get mockAttempts;
  @override
  String get placedCompany;
  @override
  double? get packageAmount;

  /// Create a copy of StudentPlacementInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StudentPlacementInfoImplCopyWith<_$StudentPlacementInfoImpl>
  get copyWith => throw _privateConstructorUsedError;
}

ApplicationFunnel _$ApplicationFunnelFromJson(Map<String, dynamic> json) {
  return _ApplicationFunnel.fromJson(json);
}

/// @nodoc
mixin _$ApplicationFunnel {
  int get totalApplied => throw _privateConstructorUsedError;
  int get shortlisted => throw _privateConstructorUsedError;
  int get interviewed => throw _privateConstructorUsedError;
  int get selected => throw _privateConstructorUsedError;

  /// Serializes this ApplicationFunnel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApplicationFunnel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApplicationFunnelCopyWith<ApplicationFunnel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApplicationFunnelCopyWith<$Res> {
  factory $ApplicationFunnelCopyWith(
    ApplicationFunnel value,
    $Res Function(ApplicationFunnel) then,
  ) = _$ApplicationFunnelCopyWithImpl<$Res, ApplicationFunnel>;
  @useResult
  $Res call({int totalApplied, int shortlisted, int interviewed, int selected});
}

/// @nodoc
class _$ApplicationFunnelCopyWithImpl<$Res, $Val extends ApplicationFunnel>
    implements $ApplicationFunnelCopyWith<$Res> {
  _$ApplicationFunnelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApplicationFunnel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalApplied = null,
    Object? shortlisted = null,
    Object? interviewed = null,
    Object? selected = null,
  }) {
    return _then(
      _value.copyWith(
            totalApplied: null == totalApplied
                ? _value.totalApplied
                : totalApplied // ignore: cast_nullable_to_non_nullable
                      as int,
            shortlisted: null == shortlisted
                ? _value.shortlisted
                : shortlisted // ignore: cast_nullable_to_non_nullable
                      as int,
            interviewed: null == interviewed
                ? _value.interviewed
                : interviewed // ignore: cast_nullable_to_non_nullable
                      as int,
            selected: null == selected
                ? _value.selected
                : selected // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ApplicationFunnelImplCopyWith<$Res>
    implements $ApplicationFunnelCopyWith<$Res> {
  factory _$$ApplicationFunnelImplCopyWith(
    _$ApplicationFunnelImpl value,
    $Res Function(_$ApplicationFunnelImpl) then,
  ) = __$$ApplicationFunnelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int totalApplied, int shortlisted, int interviewed, int selected});
}

/// @nodoc
class __$$ApplicationFunnelImplCopyWithImpl<$Res>
    extends _$ApplicationFunnelCopyWithImpl<$Res, _$ApplicationFunnelImpl>
    implements _$$ApplicationFunnelImplCopyWith<$Res> {
  __$$ApplicationFunnelImplCopyWithImpl(
    _$ApplicationFunnelImpl _value,
    $Res Function(_$ApplicationFunnelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApplicationFunnel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalApplied = null,
    Object? shortlisted = null,
    Object? interviewed = null,
    Object? selected = null,
  }) {
    return _then(
      _$ApplicationFunnelImpl(
        totalApplied: null == totalApplied
            ? _value.totalApplied
            : totalApplied // ignore: cast_nullable_to_non_nullable
                  as int,
        shortlisted: null == shortlisted
            ? _value.shortlisted
            : shortlisted // ignore: cast_nullable_to_non_nullable
                  as int,
        interviewed: null == interviewed
            ? _value.interviewed
            : interviewed // ignore: cast_nullable_to_non_nullable
                  as int,
        selected: null == selected
            ? _value.selected
            : selected // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ApplicationFunnelImpl implements _ApplicationFunnel {
  const _$ApplicationFunnelImpl({
    required this.totalApplied,
    required this.shortlisted,
    required this.interviewed,
    required this.selected,
  });

  factory _$ApplicationFunnelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApplicationFunnelImplFromJson(json);

  @override
  final int totalApplied;
  @override
  final int shortlisted;
  @override
  final int interviewed;
  @override
  final int selected;

  @override
  String toString() {
    return 'ApplicationFunnel(totalApplied: $totalApplied, shortlisted: $shortlisted, interviewed: $interviewed, selected: $selected)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApplicationFunnelImpl &&
            (identical(other.totalApplied, totalApplied) ||
                other.totalApplied == totalApplied) &&
            (identical(other.shortlisted, shortlisted) ||
                other.shortlisted == shortlisted) &&
            (identical(other.interviewed, interviewed) ||
                other.interviewed == interviewed) &&
            (identical(other.selected, selected) ||
                other.selected == selected));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalApplied,
    shortlisted,
    interviewed,
    selected,
  );

  /// Create a copy of ApplicationFunnel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApplicationFunnelImplCopyWith<_$ApplicationFunnelImpl> get copyWith =>
      __$$ApplicationFunnelImplCopyWithImpl<_$ApplicationFunnelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ApplicationFunnelImplToJson(this);
  }
}

abstract class _ApplicationFunnel implements ApplicationFunnel {
  const factory _ApplicationFunnel({
    required final int totalApplied,
    required final int shortlisted,
    required final int interviewed,
    required final int selected,
  }) = _$ApplicationFunnelImpl;

  factory _ApplicationFunnel.fromJson(Map<String, dynamic> json) =
      _$ApplicationFunnelImpl.fromJson;

  @override
  int get totalApplied;
  @override
  int get shortlisted;
  @override
  int get interviewed;
  @override
  int get selected;

  /// Create a copy of ApplicationFunnel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApplicationFunnelImplCopyWith<_$ApplicationFunnelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StudentCoursePerformance _$StudentCoursePerformanceFromJson(
  Map<String, dynamic> json,
) {
  return _StudentCoursePerformance.fromJson(json);
}

/// @nodoc
mixin _$StudentCoursePerformance {
  String get studentId => throw _privateConstructorUsedError;
  String get studentName => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError;
  double get quizScore => throw _privateConstructorUsedError;
  String get lastAccessed => throw _privateConstructorUsedError;

  /// Serializes this StudentCoursePerformance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StudentCoursePerformance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StudentCoursePerformanceCopyWith<StudentCoursePerformance> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudentCoursePerformanceCopyWith<$Res> {
  factory $StudentCoursePerformanceCopyWith(
    StudentCoursePerformance value,
    $Res Function(StudentCoursePerformance) then,
  ) = _$StudentCoursePerformanceCopyWithImpl<$Res, StudentCoursePerformance>;
  @useResult
  $Res call({
    String studentId,
    String studentName,
    double progress,
    double quizScore,
    String lastAccessed,
  });
}

/// @nodoc
class _$StudentCoursePerformanceCopyWithImpl<
  $Res,
  $Val extends StudentCoursePerformance
>
    implements $StudentCoursePerformanceCopyWith<$Res> {
  _$StudentCoursePerformanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StudentCoursePerformance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? studentName = null,
    Object? progress = null,
    Object? quizScore = null,
    Object? lastAccessed = null,
  }) {
    return _then(
      _value.copyWith(
            studentId: null == studentId
                ? _value.studentId
                : studentId // ignore: cast_nullable_to_non_nullable
                      as String,
            studentName: null == studentName
                ? _value.studentName
                : studentName // ignore: cast_nullable_to_non_nullable
                      as String,
            progress: null == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as double,
            quizScore: null == quizScore
                ? _value.quizScore
                : quizScore // ignore: cast_nullable_to_non_nullable
                      as double,
            lastAccessed: null == lastAccessed
                ? _value.lastAccessed
                : lastAccessed // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StudentCoursePerformanceImplCopyWith<$Res>
    implements $StudentCoursePerformanceCopyWith<$Res> {
  factory _$$StudentCoursePerformanceImplCopyWith(
    _$StudentCoursePerformanceImpl value,
    $Res Function(_$StudentCoursePerformanceImpl) then,
  ) = __$$StudentCoursePerformanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String studentId,
    String studentName,
    double progress,
    double quizScore,
    String lastAccessed,
  });
}

/// @nodoc
class __$$StudentCoursePerformanceImplCopyWithImpl<$Res>
    extends
        _$StudentCoursePerformanceCopyWithImpl<
          $Res,
          _$StudentCoursePerformanceImpl
        >
    implements _$$StudentCoursePerformanceImplCopyWith<$Res> {
  __$$StudentCoursePerformanceImplCopyWithImpl(
    _$StudentCoursePerformanceImpl _value,
    $Res Function(_$StudentCoursePerformanceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StudentCoursePerformance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? studentName = null,
    Object? progress = null,
    Object? quizScore = null,
    Object? lastAccessed = null,
  }) {
    return _then(
      _$StudentCoursePerformanceImpl(
        studentId: null == studentId
            ? _value.studentId
            : studentId // ignore: cast_nullable_to_non_nullable
                  as String,
        studentName: null == studentName
            ? _value.studentName
            : studentName // ignore: cast_nullable_to_non_nullable
                  as String,
        progress: null == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double,
        quizScore: null == quizScore
            ? _value.quizScore
            : quizScore // ignore: cast_nullable_to_non_nullable
                  as double,
        lastAccessed: null == lastAccessed
            ? _value.lastAccessed
            : lastAccessed // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentCoursePerformanceImpl implements _StudentCoursePerformance {
  const _$StudentCoursePerformanceImpl({
    required this.studentId,
    required this.studentName,
    required this.progress,
    required this.quizScore,
    required this.lastAccessed,
  });

  factory _$StudentCoursePerformanceImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentCoursePerformanceImplFromJson(json);

  @override
  final String studentId;
  @override
  final String studentName;
  @override
  final double progress;
  @override
  final double quizScore;
  @override
  final String lastAccessed;

  @override
  String toString() {
    return 'StudentCoursePerformance(studentId: $studentId, studentName: $studentName, progress: $progress, quizScore: $quizScore, lastAccessed: $lastAccessed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentCoursePerformanceImpl &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.studentName, studentName) ||
                other.studentName == studentName) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.quizScore, quizScore) ||
                other.quizScore == quizScore) &&
            (identical(other.lastAccessed, lastAccessed) ||
                other.lastAccessed == lastAccessed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    studentId,
    studentName,
    progress,
    quizScore,
    lastAccessed,
  );

  /// Create a copy of StudentCoursePerformance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StudentCoursePerformanceImplCopyWith<_$StudentCoursePerformanceImpl>
  get copyWith =>
      __$$StudentCoursePerformanceImplCopyWithImpl<
        _$StudentCoursePerformanceImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudentCoursePerformanceImplToJson(this);
  }
}

abstract class _StudentCoursePerformance implements StudentCoursePerformance {
  const factory _StudentCoursePerformance({
    required final String studentId,
    required final String studentName,
    required final double progress,
    required final double quizScore,
    required final String lastAccessed,
  }) = _$StudentCoursePerformanceImpl;

  factory _StudentCoursePerformance.fromJson(Map<String, dynamic> json) =
      _$StudentCoursePerformanceImpl.fromJson;

  @override
  String get studentId;
  @override
  String get studentName;
  @override
  double get progress;
  @override
  double get quizScore;
  @override
  String get lastAccessed;

  /// Create a copy of StudentCoursePerformance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StudentCoursePerformanceImplCopyWith<_$StudentCoursePerformanceImpl>
  get copyWith => throw _privateConstructorUsedError;
}
