import 'package:freezed_annotation/freezed_annotation.dart';

part 'offer.freezed.dart';
part 'offer.g.dart';

@freezed
class Offer with _$Offer {
  const Offer._();

  const factory Offer({
    required String id,
    @JsonKey(name: 'application_id') required String applicationId,
    @JsonKey(name: 'offer_type') String? offerType,
    @JsonKey(name: 'package_amount') double? packageAmount,
    @Default('INR') String currency,
    @JsonKey(name: 'joining_date') DateTime? joiningDate,
    String? location,
    @JsonKey(name: 'offer_letter_url') String? offerLetterUrl,
    @JsonKey(name: 'additional_benefits') String? additionalBenefits,
    @Default('pending') String status,
    @JsonKey(name: 'extended_at') DateTime? extendedAt,
    @JsonKey(name: 'responded_at') DateTime? respondedAt,
    @JsonKey(name: 'expiry_date') DateTime? expiryDate,
  }) = _Offer;

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);
}

/// Status display helpers
extension OfferStatusX on Offer {
  String get displayStatus {
    switch (status) {
      case 'pending':
        return 'Pending Response';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Declined';
      case 'expired':
        return 'Expired';
      case 'revoked':
        return 'Revoked';
      default:
        return status;
    }
  }

  bool get canRespond => status == 'pending';
}
