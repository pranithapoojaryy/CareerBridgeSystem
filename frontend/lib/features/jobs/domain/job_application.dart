import 'package:freezed_annotation/freezed_annotation.dart';
import 'job_model.dart';
import 'job_round.dart';
import 'round_submission.dart';
import 'offer.dart';

part 'job_application.freezed.dart';
part 'job_application.g.dart';

@freezed
class JobApplication with _$JobApplication {
  const JobApplication._();

  const factory JobApplication({
    required String id,
    @JsonKey(name: 'job_id') required String jobId,
    @JsonKey(name: 'student_id') required String studentId,
    @Default('applied') String status,
    @JsonKey(name: 'current_round') @Default(0) int currentRound,
    @JsonKey(name: 'resume_url') String? resumeUrl,
    @JsonKey(name: 'cover_letter') String? coverLetter,
    @JsonKey(name: 'profile_snapshot') Map<String, dynamic>? profileSnapshot,
    @JsonKey(name: 'cover_note') String? coverNote,
    @JsonKey(name: 'video_responses')
    List<Map<String, dynamic>>? videoResponses,
    @JsonKey(name: 'overall_score') double? overallScore,
    @JsonKey(name: 'applied_at') required DateTime createdAt,
    // Joined data
    Job? job,
    Map<String, dynamic>? student,
    List<JobRound>? rounds,
    List<RoundSubmission>? submissions,
    Offer? offer,
  }) = _JobApplication;

  factory JobApplication.fromJson(Map<String, dynamic> json) =>
      _$JobApplicationFromJson(json);
}

/// Status display helpers
extension JobApplicationStatusX on JobApplication {
  String get displayStatus {
    switch (status) {
      case 'applied':
        return 'Applied';
      case 'shortlisted':
        return 'Shortlisted';
      case 'in_progress':
        return 'In Progress';
      case 'selected':
        return 'Selected';
      case 'rejected':
        return 'Rejected';
      case 'on_hold':
        return 'On Hold';
      case 'withdrawn':
        return 'Withdrawn';
      default:
        return status;
    }
  }

  bool get isActive =>
      status == 'applied' || status == 'shortlisted' || status == 'in_progress';

  bool get isFinal => status == 'selected' || status == 'rejected';
}
