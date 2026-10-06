import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/job_model.dart';
import '../../../core/utils/logger_service.dart';

final jobRepositoryProvider = Provider(
  (ref) => JobRepository(Supabase.instance.client),
);

final featuredJobsProvider = FutureProvider<List<Job>>((ref) async {
  final repo = ref.read(jobRepositoryProvider);
  
  // Real-time listener: invalidate provider when jobs table changes
  final channel = Supabase.instance.client
      .channel('public:featured_jobs_realtime')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'jobs',
        callback: (payload) {
          ref.invalidateSelf();
        },
      )
      .subscribe();

  ref.onDispose(() => Supabase.instance.client.removeChannel(channel));
  
  return repo.getFeaturedJobs();
});

final allJobsProvider = FutureProvider<List<Job>>((ref) async {
  final repo = ref.read(jobRepositoryProvider);

  // Real-time listener: invalidate provider when jobs table changes
  final channel = Supabase.instance.client
      .channel('public:all_jobs_realtime')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'jobs',
        callback: (payload) {
          ref.invalidateSelf();
        },
      )
      .subscribe();

  ref.onDispose(() => Supabase.instance.client.removeChannel(channel));

  return repo.getAllJobs();
});

class JobRepository {
  final SupabaseClient _supabase;

  JobRepository(this._supabase);

  Future<List<Job>> getFeaturedJobs() async {
    try {
      final response = await _supabase
          .from('jobs')
          .select('*, organization:organizations(name, logo_url)')
          .eq('status', 'open')
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(5);

      return (response as List).map((e) => Job.fromJson(e)).toList();
    } catch (e) {
      LoggerService.error('Error fetching featured jobs', e);
      throw Exception('Error fetching featured jobs: $e');
    }
  }

  Future<List<Job>> getAllJobs() async {
    try {
      final response = await _supabase
          .from('jobs')
          .select('*, organization:organizations(name, logo_url)')
          .eq('status', 'open')
          .order('created_at', ascending: false);

      return (response as List).map((e) => Job.fromJson(e)).toList();
    } catch (e) {
      LoggerService.error('Error fetching jobs', e);
      throw Exception('Error fetching jobs: $e');
    }
  }

  Future<void> applyForJob(
    String jobId,
    String studentId, {
    List<Map<String, dynamic>>? videoResponses,
  }) async {
    try {
      final data = {
        'job_id': jobId,
        'student_id': studentId,
        'status': 'applied', // Initial status
        if (videoResponses != null) 'video_responses': videoResponses,
      };

      // Try to fetch current resume URL from profile to snapshot it
      try {
        final profile = await _supabase
            .from('profiles')
            .select('resume_url')
            .eq('id', studentId)
            .maybeSingle();
        if (profile != null && profile['resume_url'] != null) {
          data['resume_url'] = profile['resume_url'];
        }
      } catch (e) {
        // Ignore error fetching resume, proceed with application
        LoggerService.error('Error fetching resume for snapshot', e);
      }

      await _supabase.from('job_applications').insert(data);
    } catch (e) {
      if (e.toString().contains('duplicate key')) {
        throw Exception('You have already applied for this job.');
      }
      LoggerService.error('Error applying for job', e);
      throw Exception('Error applying for job: $e');
    }
  }
}
