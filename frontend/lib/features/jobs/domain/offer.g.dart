// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OfferImpl _$$OfferImplFromJson(Map<String, dynamic> json) => _$OfferImpl(
  id: json['id'] as String,
  applicationId: json['application_id'] as String,
  offerType: json['offer_type'] as String?,
  packageAmount: (json['package_amount'] as num?)?.toDouble(),
  currency: json['currency'] as String? ?? 'INR',
  joiningDate: json['joining_date'] == null
      ? null
      : DateTime.parse(json['joining_date'] as String),
  location: json['location'] as String?,
  offerLetterUrl: json['offer_letter_url'] as String?,
  additionalBenefits: json['additional_benefits'] as String?,
  status: json['status'] as String? ?? 'pending',
  extendedAt: json['extended_at'] == null
      ? null
      : DateTime.parse(json['extended_at'] as String),
  respondedAt: json['responded_at'] == null
      ? null
      : DateTime.parse(json['responded_at'] as String),
  expiryDate: json['expiry_date'] == null
      ? null
      : DateTime.parse(json['expiry_date'] as String),
);

Map<String, dynamic> _$$OfferImplToJson(_$OfferImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'application_id': instance.applicationId,
      'offer_type': instance.offerType,
      'package_amount': instance.packageAmount,
      'currency': instance.currency,
      'joining_date': instance.joiningDate?.toIso8601String(),
      'location': instance.location,
      'offer_letter_url': instance.offerLetterUrl,
      'additional_benefits': instance.additionalBenefits,
      'status': instance.status,
      'extended_at': instance.extendedAt?.toIso8601String(),
      'responded_at': instance.respondedAt?.toIso8601String(),
      'expiry_date': instance.expiryDate?.toIso8601String(),
    };
