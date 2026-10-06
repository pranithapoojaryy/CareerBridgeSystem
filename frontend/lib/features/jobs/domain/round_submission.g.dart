// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_submission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoundSubmissionImpl _$$RoundSubmissionImplFromJson(
  Map<String, dynamic> json,
) => _$RoundSubmissionImpl(
  id: json['id'] as String,
  applicationId: json['application_id'] as String,
  roundId: json['round_id'] as String,
  submissionType: json['submission_type'] as String,
  textResponse: json['text_response'] as String?,
  videoUrl: json['video_url'] as String?,
  fileUrls: (json['file_urls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  codingResponse: json['coding_response'] as Map<String, dynamic>?,
  submittedAt: DateTime.parse(json['submitted_at'] as String),
  status: json['status'] as String? ?? 'pending',
  evaluation: json['evaluation'] == null
      ? null
      : RoundEvaluation.fromJson(json['evaluation'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$RoundSubmissionImplToJson(
  _$RoundSubmissionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'application_id': instance.applicationId,
  'round_id': instance.roundId,
  'submission_type': instance.submissionType,
  'text_response': instance.textResponse,
  'video_url': instance.videoUrl,
  'file_urls': instance.fileUrls,
  'coding_response': instance.codingResponse,
  'submitted_at': instance.submittedAt.toIso8601String(),
  'status': instance.status,
  'evaluation': instance.evaluation,
};

_$RoundEvaluationImpl _$$RoundEvaluationImplFromJson(
  Map<String, dynamic> json,
) => _$RoundEvaluationImpl(
  id: json['id'] as String,
  submissionId: json['submission_id'] as String,
  evaluatorId: json['evaluator_id'] as String?,
  score: (json['score'] as num?)?.toDouble(),
  feedback: json['feedback'] as String?,
  remarks: json['remarks'] as Map<String, dynamic>?,
  decision: json['decision'] as String?,
  evaluatedAt: json['evaluated_at'] == null
      ? null
      : DateTime.parse(json['evaluated_at'] as String),
);

Map<String, dynamic> _$$RoundEvaluationImplToJson(
  _$RoundEvaluationImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'submission_id': instance.submissionId,
  'evaluator_id': instance.evaluatorId,
  'score': instance.score,
  'feedback': instance.feedback,
  'remarks': instance.remarks,
  'decision': instance.decision,
  'evaluated_at': instance.evaluatedAt?.toIso8601String(),
};
