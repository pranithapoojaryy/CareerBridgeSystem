import 'package:freezed_annotation/freezed_annotation.dart';

part 'round_submission.freezed.dart';
part 'round_submission.g.dart';

@freezed
class RoundSubmission with _$RoundSubmission {
  const factory RoundSubmission({
    required String id,
    @JsonKey(name: 'application_id') required String applicationId,
    @JsonKey(name: 'round_id') required String roundId,
    @JsonKey(name: 'submission_type') required String submissionType,
    @JsonKey(name: 'text_response') String? textResponse,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'file_urls') List<String>? fileUrls,
    @JsonKey(name: 'coding_response') Map<String, dynamic>? codingResponse,
    @JsonKey(name: 'submitted_at') required DateTime submittedAt,
    @Default('pending') String status,
    // Joined data
    RoundEvaluation? evaluation,
  }) = _RoundSubmission;

  factory RoundSubmission.fromJson(Map<String, dynamic> json) =>
      _$RoundSubmissionFromJson(json);
}

@freezed
class RoundEvaluation with _$RoundEvaluation {
  const factory RoundEvaluation({
    required String id,
    @JsonKey(name: 'submission_id') required String submissionId,
    @JsonKey(name: 'evaluator_id') String? evaluatorId,
    double? score,
    String? feedback,
    Map<String, dynamic>? remarks,
    String? decision,
    @JsonKey(name: 'evaluated_at') DateTime? evaluatedAt,
  }) = _RoundEvaluation;

  factory RoundEvaluation.fromJson(Map<String, dynamic> json) =>
      _$RoundEvaluationFromJson(json);
}
