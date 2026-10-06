import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_round.freezed.dart';
part 'job_round.g.dart';

@freezed
class JobRound with _$JobRound {
  const JobRound._();

  const factory JobRound({
    required String id,
    @JsonKey(name: 'job_id') required String jobId,
    @JsonKey(name: 'round_number') required int roundNumber,
    @JsonKey(name: 'round_type') required String roundType,
    required String title,
    String? instructions,
    @JsonKey(name: 'submission_type') String? submissionType,
    DateTime? deadline,
    @JsonKey(name: 'duration_minutes') int? durationMinutes,
    @JsonKey(name: 'evaluation_criteria')
    Map<String, dynamic>? evaluationCriteria,
    @JsonKey(name: 'is_mandatory') @Default(true) bool isMandatory,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _JobRound;

  factory JobRound.fromJson(Map<String, dynamic> json) =>
      _$JobRoundFromJson(json);
}

/// Extension for round type display names and icons
extension JobRoundTypeX on JobRound {
  String get displayType {
    switch (roundType) {
      case 'resume_screening':
        return 'Resume Screening';
      case 'video_intro':
        return 'Video Introduction';
      case 'technical':
        return 'Technical Round';
      case 'hr':
        return 'HR Round';
      case 'coding':
        return 'Coding Challenge';
      case 'quiz':
        return 'Quiz/MCQ';
      case 'group_discussion':
        return 'Group Discussion';
      case 'final':
      case 'final_selection':
        return 'Final Selection';
      default:
        return title;
    }
  }
}
