// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobImpl _$$JobImplFromJson(Map<String, dynamic> json) => _$JobImpl(
  id: json['id'] as String,
  recruiterId: json['recruiter_id'] as String,
  organizationId: json['organization_id'] as String?,
  title: json['title'] as String,
  description: json['description'] as String,
  requirements: json['requirements'] as String?,
  location: json['location'] as String?,
  salaryRange: json['salary_range'] as String?,
  jobType: json['job_type'] as String?,
  isFeatured: json['is_featured'] as bool? ?? false,
  status: json['status'] as String? ?? 'open',
  createdAt: DateTime.parse(json['created_at'] as String),
  screeningQuestions: normalizeScreeningQuestions(json['screening_questions']),
  organization: json['organization'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$$JobImplToJson(_$JobImpl instance) => <String, dynamic>{
  'id': instance.id,
  'recruiter_id': instance.recruiterId,
  'organization_id': instance.organizationId,
  'title': instance.title,
  'description': instance.description,
  'requirements': instance.requirements,
  'location': instance.location,
  'salary_range': instance.salaryRange,
  'job_type': instance.jobType,
  'is_featured': instance.isFeatured,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
  'screening_questions': instance.screeningQuestions,
  'organization': instance.organization,
};
