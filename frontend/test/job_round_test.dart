// Quick test to verify JobRound.fromJson works
import 'package:frontend/features/jobs/domain/job_round.dart';

void main() {
  // Test data matching database structure
  final testJson = {
    "id": "c7154c2f-7f9a-4cd6-975e-f6030db32f3d",
    "job_id": "051db1bb-d800-4e04-80ba-071c4e53c5d0",
    "round_number": 1,
    "round_type": "resume_screening",
    "title": "Resume Screening",
    "instructions": "Initial resume and profile review",
    "submission_type": "none",
    "deadline": null,
    "duration_minutes": null,
    "is_mandatory": true,
    "evaluation_criteria": null,
    "created_at": "2026-02-03T12:26:10.304197+00:00",
    "updated_at": "2026-02-03T12:26:10.304197+00:00",
  };

  try {
    final round = JobRound.fromJson(testJson);
    print('✅ SUCCESS: JobRound parsed correctly');
    print('   Round: ${round.title} (Round ${round.roundNumber})');
    print('   Submission Type: ${round.submissionType}');
  } catch (e, stackTrace) {
    print('❌ ERROR: Failed to parse JobRound');
    print('   Error: $e');
    print('   Stack: $stackTrace');
  }
}
