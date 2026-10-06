import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../domain/job_application.dart';
import '../domain/job_round.dart';
import '../domain/round_submission.dart';
import '../domain/offer.dart';
import '../../../core/utils/logger_service.dart';

final hiringPipelineProvider = Provider(
  (ref) => HiringPipelineRepository(Supabase.instance.client),
);

/// Provider for recruiter's applications by job
final jobApplicationsProvider =
    FutureProvider.family<List<JobApplication>, String>((ref, jobId) async {
      return ref.read(hiringPipelineProvider).getJobApplications(jobId);
    });

/// Provider for student's own applications
final myApplicationsProvider = FutureProvider<List<JobApplication>>((
  ref,
) async {
  return ref.read(hiringPipelineProvider).getMyApplications();
});

/// Provider for job rounds
final jobRoundsProvider = FutureProvider.family<List<JobRound>, String>((
  ref,
  jobId,
) async {
  return ref.read(hiringPipelineProvider).getJobRounds(jobId);
});

class HiringPipelineRepository {
  final SupabaseClient _supabase;

  HiringPipelineRepository(this._supabase);

  // ============================================
  // JOB ROUNDS
  // ============================================

  /// Get all rounds for a job
  Future<List<JobRound>> getJobRounds(String jobId) async {
    final response = await _supabase
        .from('job_rounds')
        .select()
        .eq('job_id', jobId)
        .order('round_number');

    return (response as List).map((e) => JobRound.fromJson(e)).toList();
  }

  /// Add a custom round to a job
  Future<JobRound> addJobRound({
    required String jobId,
    required int roundNumber,
    required String roundType,
    required String title,
    String? instructions,
    String? submissionType,
    int deadlineDays = 7,
    Map<String, dynamic>? evaluationCriteria,
  }) async {
    final response = await _supabase
        .from('job_rounds')
        .insert({
          'job_id': jobId,
          'round_number': roundNumber,
          'round_type': roundType,
          'title': title,
          'instructions': instructions,
          'submission_type': submissionType,
          'deadline_days': deadlineDays,
          'evaluation_criteria': evaluationCriteria,
        })
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('Failed to add job round');
    }

    return JobRound.fromJson(response);
  }

  /// Activate a round (make it visible to candidates)
  Future<void> activateRound(String roundId) async {
    await _supabase
        .from('job_rounds')
        .update({'is_active': true})
        .eq('id', roundId);
  }

  // ============================================
  // APPLICATIONS
  // ============================================

  /// Get all applications for a job (Recruiter view)
  Future<List<JobApplication>> getJobApplications(String jobId) async {
    final response = await _supabase
        .from('job_applications')
        .select('''
          *,
          student:profiles!job_applications_student_id_fkey(
            id, full_name, email, avatar_url, headline, resume_url,
            projects:student_projects(*),
            posts:posts!posts_author_id_fkey(*)
          ),
          job:jobs(title, organization:organizations(name, logo_url))
        ''')
        .eq('job_id', jobId)
        .order('applied_at', ascending: false);

    return (response as List).map((e) => JobApplication.fromJson(e)).toList();
  }

  /// Get student's own applications
  Future<List<JobApplication>> getMyApplications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('job_applications')
        .select('''
          *,
          job:jobs(*, organization:organizations(name, logo_url)),
          offer:offers(*)
        ''')
        .eq('student_id', userId)
        .order('applied_at', ascending: false);

    return (response as List).map((e) => JobApplication.fromJson(e)).toList();
  }

  /// Get single application with all details
  Future<JobApplication> getApplicationDetail(String applicationId) async {
    final response = await _supabase
        .from('job_applications')
        .select('''
          *,
          student:profiles!job_applications_student_id_fkey(*),
          job:jobs(*, organization:organizations(name, logo_url)),
          offer:offers(*)
        ''')
        .eq('id', applicationId)
        .maybeSingle();

    if (response == null) {
      throw Exception('Application not found');
    }

    return JobApplication.fromJson(response);
  }

  /// Shortlist an application
  Future<void> shortlistApplication(String applicationId) async {
    await _supabase
        .from('job_applications')
        .update({'status': 'shortlisted'})
        .eq('id', applicationId);

    // TODO: Send notification to student
  }

  /// Reject an application
  Future<void> rejectApplication(String applicationId, {String? reason}) async {
    await _supabase
        .from('job_applications')
        .update({'status': 'rejected'})
        .eq('id', applicationId);

    // TODO: Send notification to student
  }

  /// Progress application to next round
  Future<void> progressToNextRound(String applicationId) async {
    // Get current round
    final app = await _supabase
        .from('job_applications')
        .select('current_round, job_id')
        .eq('id', applicationId)
        .maybeSingle();

    if (app == null) {
      LoggerService.error('Application $applicationId not found for progression');
      return;
    }

    final currentRound = app['current_round'] as int;
    final jobId = app['job_id'] as String;

    // Check if there's a next round
    final nextRound = await _supabase
        .from('job_rounds')
        .select()
        .eq('job_id', jobId)
        .eq('round_number', currentRound + 1)
        .maybeSingle();

    if (nextRound != null) {
      await _supabase
          .from('job_applications')
          .update({'current_round': currentRound + 1, 'status': 'in_progress'})
          .eq('id', applicationId);
    }
  }

  // ============================================
  // SUBMISSIONS
  // ============================================

  /// Get submissions for an application
  Future<List<RoundSubmission>> getApplicationSubmissions(
    String applicationId,
  ) async {
    final response = await _supabase
        .from('application_round_submissions')
        .select('*')
        .eq('application_id', applicationId)
        .order('submitted_at');

    // Fetch evaluations separately to avoid List vs Map type issues
    final submissions = (response as List).map((submissionData) {
      return RoundSubmission.fromJson(submissionData);
    }).toList();

    return submissions;
  }

  /// Submit a round response (Student)
  Future<RoundSubmission> submitRoundResponse({
    required String applicationId,
    required String roundId,
    required String submissionType,
    String? textResponse,
    String? videoUrl,
    List<String>? fileUrls,
    Map<String, dynamic>? codingResponse,
  }) async {
    final response = await _supabase
        .from('application_round_submissions')
        .insert({
          'application_id': applicationId,
          'round_id': roundId,
          'submission_type': submissionType,
          'text_response': textResponse,
          'video_url': videoUrl,
          'file_urls': fileUrls,
          'code_submission': codingResponse,
        })
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('Failed to submit response');
    }

    // Update application last activity checks removed as column doesn't exist

    return RoundSubmission.fromJson(response);
  }

  /// Upload round video submission
  Future<String> uploadRoundVideo({
    required List<int> fileBytes,
    required String applicationId,
    required String roundId,
  }) async {
    final fileName =
        '${applicationId}_${roundId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    await _supabase.storage
        .from('round_submissions')
        .uploadBinary(
          fileName,
          Uint8List.fromList(fileBytes),
          fileOptions: const FileOptions(cacheControl: 'public, max-age=3600'),
        );
    return _supabase.storage.from('round_submissions').getPublicUrl(fileName);
  }

  /// Upload generic round file
  Future<String> uploadRoundFile({
    required List<int> fileBytes,
    required String applicationId,
    required String roundId,
    required String extension,
  }) async {
    final fileName =
        '${applicationId}_${roundId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _supabase.storage
        .from('round_submissions')
        .uploadBinary(
          fileName,
          Uint8List.fromList(fileBytes),
          fileOptions: const FileOptions(cacheControl: 'public, max-age=3600'),
        );
    return _supabase.storage.from('round_submissions').getPublicUrl(fileName);
  }

  // ============================================
  // EVALUATIONS
  // ============================================

  /// Evaluate a submission (Recruiter)
  Future<void> evaluateSubmission({
    required String submissionId,
    required String decision,
    double? score,
    String? feedback,
    Map<String, dynamic>? remarks,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Insert evaluation
    await _supabase.from('round_evaluations').upsert({
      'submission_id': submissionId,
      'evaluator_id': userId,
      'score': score,
      'feedback': feedback,
      'remarks': remarks,
      'decision': decision,
    }, onConflict: 'submission_id, evaluator_id');

    // Update submission status
    final newStatus = decision == 'pass'
        ? 'passed'
        : decision == 'fail'
        ? 'failed'
        : 'reviewed';

    LoggerService.debug('Updating submission $submissionId to status: $newStatus');

    final updateResponse = await _supabase
        .from('application_round_submissions')
        .update({'status': newStatus})
        .eq('id', submissionId)
        .select()
        .maybeSingle();

    if (updateResponse == null) {
      LoggerService.error('Failed to update submission $submissionId status. Record may not exist or permission denied.');
    } else {
      LoggerService.debug('Update response: $updateResponse');
    }

    // AUTO-PROGRESSION LOGIC
    if (decision == 'pass') {
      // Get submission details (application_id and round_id)
      final submission = await _supabase
          .from('application_round_submissions')
          .select('application_id, round_id')
          .eq('id', submissionId)
          .maybeSingle();

      if (submission == null) {
        LoggerService.error('Submission $submissionId not found for passing logic');
        return;
      }

      final applicationId = submission['application_id'] as String;
      final currentRoundId = submission['round_id'] as String;

      // Get current round details (round_number and job_id)
      final currentRound = await _supabase
          .from('job_rounds')
          .select('round_number, job_id')
          .eq('id', currentRoundId)
          .maybeSingle();

      if (currentRound == null) {
        LoggerService.error('Round $currentRoundId not found for progression');
        return;
      }

      final roundNumber = currentRound['round_number'] as int;
      final jobId = currentRound['job_id'] as String;

      // Check if next round exists
      final nextRound = await _supabase
          .from('job_rounds')
          .select()
          .eq('job_id', jobId)
          .eq('round_number', roundNumber + 1)
          .maybeSingle();

      if (nextRound != null) {
        // Progress to next round
        await _supabase
            .from('job_applications')
            .update({'current_round': roundNumber + 1, 'status': 'in_progress'})
            .eq('id', applicationId);
      } else {
        // Last round passed - mark as selected
        await _supabase
            .from('job_applications')
            .update({'status': 'selected'})
            .eq('id', applicationId);
      }
    } else if (decision == 'fail') {
      // Failed evaluation - reject application
      final submission = await _supabase
          .from('application_round_submissions')
          .select('application_id')
          .eq('id', submissionId)
          .maybeSingle();

      if (submission == null) {
        LoggerService.error('Submission $submissionId not found for failing logic');
        return;
      }

      await _supabase
          .from('job_applications')
          .update({'status': 'rejected'})
          .eq('id', submission['application_id']);
    }
  }

  // ============================================
  // OFFERS & FINAL SELECTION
  // ============================================

  /// Select a candidate and create offer
  Future<Offer> selectCandidate({
    required String applicationId,
    required String offerType,
    double? packageAmount,
    DateTime? joiningDate,
    String? location,
    String? additionalBenefits,
    DateTime? expiryDate,
  }) async {
    // Update application status
    await _supabase
        .from('job_applications')
        .update({'status': 'selected'})
        .eq('id', applicationId);

    // Create offer
    final response = await _supabase
        .from('offers')
        .insert({
          'application_id': applicationId,
          'offer_type': offerType,
          'package_amount': packageAmount,
          'joining_date': joiningDate?.toIso8601String(),
          'location': location,
          // 'additional_benefits': additionalBenefits, // Column missing in DB
          'expiry_date': expiryDate?.toIso8601String(),
        })
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('Failed to create offer');
    }

    // TODO: Send notification to student
    return Offer.fromJson(response);
  }

  /// Student responds to offer
  Future<void> respondToOffer(String offerId, bool accept) async {
    await _supabase
        .from('offers')
        .update({
          'status': accept ? 'accepted' : 'rejected',
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', offerId);
  }

  // ============================================
  // ANALYTICS
  // ============================================

  /// Get hiring funnel stats for a job
  Future<Map<String, int>> getHiringFunnelStats(String jobId) async {
    final response = await _supabase
        .from('job_applications')
        .select('status')
        .eq('job_id', jobId);

    final stats = <String, int>{
      'total': 0,
      'applied': 0,
      'shortlisted': 0,
      'in_progress': 0,
      'selected': 0,
      'rejected': 0,
    };

    for (final app in response) {
      final status = app['status'] as String;
      stats['total'] = (stats['total'] ?? 0) + 1;
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }
}
