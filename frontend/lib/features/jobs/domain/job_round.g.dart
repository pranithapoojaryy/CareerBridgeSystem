// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_round.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobRoundImpl _$$JobRoundImplFromJson(Map<String, dynamic> json) =>
    _$JobRoundImpl(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      roundNumber: (json['round_number'] as num).toInt(),
      roundType: json['round_type'] as String,
      title: json['title'] as String,
      instructions: json['instructions'] as String?,
      submissionType: json['submission_type'] as String?,
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      evaluationCriteria: json['evaluation_criteria'] as Map<String, dynamic>?,
      isMandatory: json['is_mandatory'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$JobRoundImplToJson(_$JobRoundImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'job_id': instance.jobId,
      'round_number': instance.roundNumber,
      'round_type': instance.roundType,
      'title': instance.title,
      'instructions': instance.instructions,
      'submission_type': instance.submissionType,
      'deadline': instance.deadline?.toIso8601String(),
      'duration_minutes': instance.durationMinutes,
      'evaluation_criteria': instance.evaluationCriteria,
      'is_mandatory': instance.isMandatory,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
