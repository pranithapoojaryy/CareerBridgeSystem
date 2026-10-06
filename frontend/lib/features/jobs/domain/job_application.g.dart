// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_application.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobApplicationImpl _$$JobApplicationImplFromJson(Map<String, dynamic> json) =>
    _$JobApplicationImpl(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      studentId: json['student_id'] as String,
      status: json['status'] as String? ?? 'applied',
      currentRound: (json['current_round'] as num?)?.toInt() ?? 0,
      resumeUrl: json['resume_url'] as String?,
      coverLetter: json['cover_letter'] as String?,
      profileSnapshot: json['profile_snapshot'] as Map<String, dynamic>?,
      coverNote: json['cover_note'] as String?,
      videoResponses: (json['video_responses'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      overallScore: (json['overall_score'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['applied_at'] as String),
      job: json['job'] == null
          ? null
          : Job.fromJson(json['job'] as Map<String, dynamic>),
      student: json['student'] as Map<String, dynamic>?,
      rounds: (json['rounds'] as List<dynamic>?)
          ?.map((e) => JobRound.fromJson(e as Map<String, dynamic>))
          .toList(),
      submissions: (json['submissions'] as List<dynamic>?)
          ?.map((e) => RoundSubmission.fromJson(e as Map<String, dynamic>))
          .toList(),
      offer: json['offer'] == null
          ? null
          : Offer.fromJson(json['offer'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$JobApplicationImplToJson(
  _$JobApplicationImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'job_id': instance.jobId,
  'student_id': instance.studentId,
  'status': instance.status,
  'current_round': instance.currentRound,
  'resume_url': instance.resumeUrl,
  'cover_letter': instance.coverLetter,
  'profile_snapshot': instance.profileSnapshot,
  'cover_note': instance.coverNote,
  'video_responses': instance.videoResponses,
  'overall_score': instance.overallScore,
  'applied_at': instance.createdAt.toIso8601String(),
  'job': instance.job,
  'student': instance.student,
  'rounds': instance.rounds,
  'submissions': instance.submissions,
  'offer': instance.offer,
};
