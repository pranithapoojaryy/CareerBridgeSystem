// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Offer _$OfferFromJson(Map<String, dynamic> json) {
  return _Offer.fromJson(json);
}

/// @nodoc
mixin _$Offer {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'application_id')
  String get applicationId => throw _privateConstructorUsedError;
  @JsonKey(name: 'offer_type')
  String? get offerType => throw _privateConstructorUsedError;
  @JsonKey(name: 'package_amount')
  double? get packageAmount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  @JsonKey(name: 'joining_date')
  DateTime? get joiningDate => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  @JsonKey(name: 'offer_letter_url')
  String? get offerLetterUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'additional_benefits')
  String? get additionalBenefits => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'extended_at')
  DateTime? get extendedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'responded_at')
  DateTime? get respondedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'expiry_date')
  DateTime? get expiryDate => throw _privateConstructorUsedError;

  /// Serializes this Offer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Offer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OfferCopyWith<Offer> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OfferCopyWith<$Res> {
  factory $OfferCopyWith(Offer value, $Res Function(Offer) then) =
      _$OfferCopyWithImpl<$Res, Offer>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'application_id') String applicationId,
    @JsonKey(name: 'offer_type') String? offerType,
    @JsonKey(name: 'package_amount') double? packageAmount,
    String currency,
    @JsonKey(name: 'joining_date') DateTime? joiningDate,
    String? location,
    @JsonKey(name: 'offer_letter_url') String? offerLetterUrl,
    @JsonKey(name: 'additional_benefits') String? additionalBenefits,
    String status,
    @JsonKey(name: 'extended_at') DateTime? extendedAt,
    @JsonKey(name: 'responded_at') DateTime? respondedAt,
    @JsonKey(name: 'expiry_date') DateTime? expiryDate,
  });
}

/// @nodoc
class _$OfferCopyWithImpl<$Res, $Val extends Offer>
    implements $OfferCopyWith<$Res> {
  _$OfferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Offer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? applicationId = null,
    Object? offerType = freezed,
    Object? packageAmount = freezed,
    Object? currency = null,
    Object? joiningDate = freezed,
    Object? location = freezed,
    Object? offerLetterUrl = freezed,
    Object? additionalBenefits = freezed,
    Object? status = null,
    Object? extendedAt = freezed,
    Object? respondedAt = freezed,
    Object? expiryDate = freezed,
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
            offerType: freezed == offerType
                ? _value.offerType
                : offerType // ignore: cast_nullable_to_non_nullable
                      as String?,
            packageAmount: freezed == packageAmount
                ? _value.packageAmount
                : packageAmount // ignore: cast_nullable_to_non_nullable
                      as double?,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            joiningDate: freezed == joiningDate
                ? _value.joiningDate
                : joiningDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            location: freezed == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String?,
            offerLetterUrl: freezed == offerLetterUrl
                ? _value.offerLetterUrl
                : offerLetterUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            additionalBenefits: freezed == additionalBenefits
                ? _value.additionalBenefits
                : additionalBenefits // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            extendedAt: freezed == extendedAt
                ? _value.extendedAt
                : extendedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            respondedAt: freezed == respondedAt
                ? _value.respondedAt
                : respondedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            expiryDate: freezed == expiryDate
                ? _value.expiryDate
                : expiryDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OfferImplCopyWith<$Res> implements $OfferCopyWith<$Res> {
  factory _$$OfferImplCopyWith(
    _$OfferImpl value,
    $Res Function(_$OfferImpl) then,
  ) = __$$OfferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'application_id') String applicationId,
    @JsonKey(name: 'offer_type') String? offerType,
    @JsonKey(name: 'package_amount') double? packageAmount,
    String currency,
    @JsonKey(name: 'joining_date') DateTime? joiningDate,
    String? location,
    @JsonKey(name: 'offer_letter_url') String? offerLetterUrl,
    @JsonKey(name: 'additional_benefits') String? additionalBenefits,
    String status,
    @JsonKey(name: 'extended_at') DateTime? extendedAt,
    @JsonKey(name: 'responded_at') DateTime? respondedAt,
    @JsonKey(name: 'expiry_date') DateTime? expiryDate,
  });
}

/// @nodoc
class __$$OfferImplCopyWithImpl<$Res>
    extends _$OfferCopyWithImpl<$Res, _$OfferImpl>
    implements _$$OfferImplCopyWith<$Res> {
  __$$OfferImplCopyWithImpl(
    _$OfferImpl _value,
    $Res Function(_$OfferImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Offer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? applicationId = null,
    Object? offerType = freezed,
    Object? packageAmount = freezed,
    Object? currency = null,
    Object? joiningDate = freezed,
    Object? location = freezed,
    Object? offerLetterUrl = freezed,
    Object? additionalBenefits = freezed,
    Object? status = null,
    Object? extendedAt = freezed,
    Object? respondedAt = freezed,
    Object? expiryDate = freezed,
  }) {
    return _then(
      _$OfferImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        applicationId: null == applicationId
            ? _value.applicationId
            : applicationId // ignore: cast_nullable_to_non_nullable
                  as String,
        offerType: freezed == offerType
            ? _value.offerType
            : offerType // ignore: cast_nullable_to_non_nullable
                  as String?,
        packageAmount: freezed == packageAmount
            ? _value.packageAmount
            : packageAmount // ignore: cast_nullable_to_non_nullable
                  as double?,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        joiningDate: freezed == joiningDate
            ? _value.joiningDate
            : joiningDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        location: freezed == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String?,
        offerLetterUrl: freezed == offerLetterUrl
            ? _value.offerLetterUrl
            : offerLetterUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        additionalBenefits: freezed == additionalBenefits
            ? _value.additionalBenefits
            : additionalBenefits // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        extendedAt: freezed == extendedAt
            ? _value.extendedAt
            : extendedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        respondedAt: freezed == respondedAt
            ? _value.respondedAt
            : respondedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        expiryDate: freezed == expiryDate
            ? _value.expiryDate
            : expiryDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OfferImpl extends _Offer {
  const _$OfferImpl({
    required this.id,
    @JsonKey(name: 'application_id') required this.applicationId,
    @JsonKey(name: 'offer_type') this.offerType,
    @JsonKey(name: 'package_amount') this.packageAmount,
    this.currency = 'INR',
    @JsonKey(name: 'joining_date') this.joiningDate,
    this.location,
    @JsonKey(name: 'offer_letter_url') this.offerLetterUrl,
    @JsonKey(name: 'additional_benefits') this.additionalBenefits,
    this.status = 'pending',
    @JsonKey(name: 'extended_at') this.extendedAt,
    @JsonKey(name: 'responded_at') this.respondedAt,
    @JsonKey(name: 'expiry_date') this.expiryDate,
  }) : super._();

  factory _$OfferImpl.fromJson(Map<String, dynamic> json) =>
      _$$OfferImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'application_id')
  final String applicationId;
  @override
  @JsonKey(name: 'offer_type')
  final String? offerType;
  @override
  @JsonKey(name: 'package_amount')
  final double? packageAmount;
  @override
  @JsonKey()
  final String currency;
  @override
  @JsonKey(name: 'joining_date')
  final DateTime? joiningDate;
  @override
  final String? location;
  @override
  @JsonKey(name: 'offer_letter_url')
  final String? offerLetterUrl;
  @override
  @JsonKey(name: 'additional_benefits')
  final String? additionalBenefits;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'extended_at')
  final DateTime? extendedAt;
  @override
  @JsonKey(name: 'responded_at')
  final DateTime? respondedAt;
  @override
  @JsonKey(name: 'expiry_date')
  final DateTime? expiryDate;

  @override
  String toString() {
    return 'Offer(id: $id, applicationId: $applicationId, offerType: $offerType, packageAmount: $packageAmount, currency: $currency, joiningDate: $joiningDate, location: $location, offerLetterUrl: $offerLetterUrl, additionalBenefits: $additionalBenefits, status: $status, extendedAt: $extendedAt, respondedAt: $respondedAt, expiryDate: $expiryDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OfferImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.applicationId, applicationId) ||
                other.applicationId == applicationId) &&
            (identical(other.offerType, offerType) ||
                other.offerType == offerType) &&
            (identical(other.packageAmount, packageAmount) ||
                other.packageAmount == packageAmount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.joiningDate, joiningDate) ||
                other.joiningDate == joiningDate) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.offerLetterUrl, offerLetterUrl) ||
                other.offerLetterUrl == offerLetterUrl) &&
            (identical(other.additionalBenefits, additionalBenefits) ||
                other.additionalBenefits == additionalBenefits) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.extendedAt, extendedAt) ||
                other.extendedAt == extendedAt) &&
            (identical(other.respondedAt, respondedAt) ||
                other.respondedAt == respondedAt) &&
            (identical(other.expiryDate, expiryDate) ||
                other.expiryDate == expiryDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    applicationId,
    offerType,
    packageAmount,
    currency,
    joiningDate,
    location,
    offerLetterUrl,
    additionalBenefits,
    status,
    extendedAt,
    respondedAt,
    expiryDate,
  );

  /// Create a copy of Offer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OfferImplCopyWith<_$OfferImpl> get copyWith =>
      __$$OfferImplCopyWithImpl<_$OfferImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OfferImplToJson(this);
  }
}

abstract class _Offer extends Offer {
  const factory _Offer({
    required final String id,
    @JsonKey(name: 'application_id') required final String applicationId,
    @JsonKey(name: 'offer_type') final String? offerType,
    @JsonKey(name: 'package_amount') final double? packageAmount,
    final String currency,
    @JsonKey(name: 'joining_date') final DateTime? joiningDate,
    final String? location,
    @JsonKey(name: 'offer_letter_url') final String? offerLetterUrl,
    @JsonKey(name: 'additional_benefits') final String? additionalBenefits,
    final String status,
    @JsonKey(name: 'extended_at') final DateTime? extendedAt,
    @JsonKey(name: 'responded_at') final DateTime? respondedAt,
    @JsonKey(name: 'expiry_date') final DateTime? expiryDate,
  }) = _$OfferImpl;
  const _Offer._() : super._();

  factory _Offer.fromJson(Map<String, dynamic> json) = _$OfferImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'application_id')
  String get applicationId;
  @override
  @JsonKey(name: 'offer_type')
  String? get offerType;
  @override
  @JsonKey(name: 'package_amount')
  double? get packageAmount;
  @override
  String get currency;
  @override
  @JsonKey(name: 'joining_date')
  DateTime? get joiningDate;
  @override
  String? get location;
  @override
  @JsonKey(name: 'offer_letter_url')
  String? get offerLetterUrl;
  @override
  @JsonKey(name: 'additional_benefits')
  String? get additionalBenefits;
  @override
  String get status;
  @override
  @JsonKey(name: 'extended_at')
  DateTime? get extendedAt;
  @override
  @JsonKey(name: 'responded_at')
  DateTime? get respondedAt;
  @override
  @JsonKey(name: 'expiry_date')
  DateTime? get expiryDate;

  /// Create a copy of Offer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OfferImplCopyWith<_$OfferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
