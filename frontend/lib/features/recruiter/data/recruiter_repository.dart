import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger_service.dart';

final recruiterRepositoryProvider = Provider(
  (ref) => RecruiterRepository(Supabase.instance.client),
);

final recruiterDashboardStatsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(recruiterRepositoryProvider).getDashboardStats();
});

class RecruiterRepository {
  final SupabaseClient _supabase;

  RecruiterRepository(this._supabase);

  Future<String?> _discoverCompanyId(String userId) async {
    LoggerService.debug('Starting _discoverCompanyId for user: $userId');
    try {
      // 1. Check profiles table (organization_id) - Prefer this as it's the official link for jobs/branding
      final profileResponse = await _supabase
          .from('profiles')
          .select('organization_id')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse != null &&
          profileResponse['organization_id'] != null) {
        LoggerService.debug(
          'Found organization_id in profiles table: ${profileResponse['organization_id']}',
        );
        return profileResponse['organization_id'];
      }

      // 2. Check recruiters table (fallback)
      final recruiterResponse = await _supabase
          .from('recruiters')
          .select('company_id')
          .eq('id', userId)
          .maybeSingle();

      if (recruiterResponse != null &&
          recruiterResponse['company_id'] != null) {
        LoggerService.debug(
          'Found company_id in recruiters table: ${recruiterResponse['company_id']}',
        );
        return recruiterResponse['company_id'];
      }

      // 3. Infer from jobs posted by this user
      final jobResponse = await _supabase
          .from('jobs')
          .select('organization_id')
          .eq('posted_by', userId)
          .limit(1)
          .maybeSingle();

      if (jobResponse != null && jobResponse['organization_id'] != null) {
        LoggerService.debug(
          'Infereed company_id from jobs table: ${jobResponse['organization_id']}',
        );
        return jobResponse['organization_id'];
      }

      LoggerService.debug('No company_id found for user: $userId');
    } catch (e) {
      LoggerService.error('Error in _discoverCompanyId', e);
    }
    return null;
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final companyId = await _discoverCompanyId(user.id);
      String companyName = 'Your Company';
      String? companyLogo;

      LoggerService.debug('Final determined companyId: $companyId');

      if (companyId != null) {
        // Try organizations table first as that usually matches the organization_id from profiles
        final orgResponse = await _supabase
            .from('organizations')
            .select('name, logo_url')
            .eq('id', companyId)
            .maybeSingle();

        if (orgResponse != null) {
          companyName = orgResponse['name'] ?? 'Your Company';
          companyLogo = orgResponse['logo_url'];
          LoggerService.debug('Fetched branding from organizations: $companyName');
        } else {
          // Try companies table
          final compResponse = await _supabase
              .from('companies')
              .select('name, logo_url')
              .eq('id', companyId)
              .maybeSingle();

          if (compResponse != null) {
            companyName = compResponse['name'] ?? 'Your Company';
            companyLogo = compResponse['logo_url'];
            LoggerService.debug('Fetched branding from companies: $companyName');
          }
        }
      }

      // Final fallback if name is still generic
      if (companyName == 'Your Company' || companyName.isEmpty) {
        final profileResponse = await _supabase
            .from('profiles')
            .select('full_name, organization_id')
            .eq('id', user.id)
            .maybeSingle();

        if (profileResponse != null) {
          final profileOrgId = profileResponse['organization_id'];
          if (profileOrgId != null && profileOrgId != companyId) {
            final secondTry = await _supabase
                .from('organizations')
                .select('name, logo_url')
                .eq('id', profileOrgId)
                .maybeSingle();
            if (secondTry != null) {
              companyName = secondTry['name'] ?? companyName;
              companyLogo = secondTry['logo_url'] ?? companyLogo;
            }
          }
        }
      }

      // 2. Fetch Stats
      int totalJobs = 0;
      int activeJobs = 0;
      int totalApplications = 0;
      int placed = 0;

      const dbTimeout = Duration(seconds: 10);

      try {
        final List<String> allPotentialOrgIds = [];
        if (companyId != null) allPotentialOrgIds.add(companyId);

        final profilesResp = await _supabase
            .from('profiles')
            .select('organization_id')
            .eq('id', user.id)
            .maybeSingle();
        if (profilesResp != null && profilesResp['organization_id'] != null) {
          final pId = profilesResp['organization_id'] as String;
          if (!allPotentialOrgIds.contains(pId)) allPotentialOrgIds.add(pId);
        }

        if (allPotentialOrgIds.isNotEmpty) {
            LoggerService.debug('Fetching stats for IDs: $allPotentialOrgIds');

          final results = await Future.wait([
            _supabase
                .from('jobs')
                .select('id')
                .inFilter('organization_id', allPotentialOrgIds)
                .timeout(dbTimeout),
            _supabase
                .from('jobs')
                .select('id')
                .inFilter('organization_id', allPotentialOrgIds)
                .eq('status', 'open')
                .timeout(dbTimeout),
          ]);

          final allJobsList = results[0] as List<dynamic>;
          final activeJobsList = results[1] as List<dynamic>;

          totalJobs = allJobsList.length;
          activeJobs = activeJobsList.length;
            LoggerService.debug(
              'Company Stats - Total: $totalJobs, Active: $activeJobs',
            );

          if (allJobsList.isNotEmpty) {
            final jobIds = allJobsList.map((j) => j['id']).toList();

            final appResults = await Future.wait([
              _supabase
                  .from('job_applications')
                  .select('id')
                  .inFilter('job_id', jobIds)
                  .timeout(dbTimeout),
              _supabase
                  .from('job_applications')
                  .select('id')
                  .inFilter('job_id', jobIds)
                  .eq('status', 'shortlisted')
                  .timeout(dbTimeout),
            ]);

            totalApplications = (appResults[0] as List).length;
            placed = (appResults[1] as List).length;
            LoggerService.debug(
              'Company Stats - Apps: $totalApplications, Placed: $placed',
            );
          }
        } else {
          LoggerService.debug('Fetching stats for user: ${user.id}');
          final jobsResponse = await _supabase
              .from('jobs')
              .select('id, status')
              .eq('posted_by', user.id)
              .timeout(dbTimeout);

          totalJobs = jobsResponse.length;
          activeJobs = jobsResponse.where((j) => j['status'] == 'open').length;

          if (jobsResponse.isNotEmpty) {
            final jobIds = jobsResponse.map((j) => j['id']).toList();
            final appResults = await Future.wait([
              _supabase
                  .from('job_applications')
                  .select('id')
                  .inFilter('job_id', jobIds)
                  .timeout(dbTimeout),
              _supabase
                  .from('job_applications')
                  .select('id')
                  .inFilter('job_id', jobIds)
                  .eq('status', 'shortlisted')
                  .timeout(dbTimeout),
            ]);
            totalApplications = (appResults[0] as List).length;
            placed = (appResults[1] as List).length;
          }
        }
      } catch (e) {
        LoggerService.error('Stats fetching error', e);
      }

      // Fetch Partner Colleges Count
      int partnerColleges = 0;
      try {
        // Use the same RPC call as NetworkRepository for consistency
        final List<dynamic> connections = await _supabase.rpc(
          'get_my_connections',
        );

        // Filter for colleges
        partnerColleges = connections.where((c) {
          final role = (c['role'] as String?)?.toLowerCase() ?? '';
          return role == 'college' || role == 'college_admin';
        }).length;

        LoggerService.debug('Partner colleges count: $partnerColleges');
      } catch (e) {
        LoggerService.error('Partner colleges fetching error', e);
      }

      return {
        'companyName': companyName,
        'companyLogo': companyLogo,
        'totalJobs': totalJobs,
        'activeJobs': activeJobs,
        'totalApplications': totalApplications,
        'placed':
            placed, // Keeping for backward compatibility if needed, but UI will ignore
        'partnerColleges': partnerColleges,
        'companyId': companyId,
      };
    } catch (e, stack) {
      LoggerService.error('Error in getDashboardStats', e, stack);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveJobs() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final companyId = await _discoverCompanyId(user.id);

      final List<String> allPotentialOrgIds = [];
      if (companyId != null) allPotentialOrgIds.add(companyId);
      final profileResponse = await _supabase
          .from('profiles')
          .select('organization_id')
          .eq('id', user.id)
          .maybeSingle();
      if (profileResponse != null &&
          profileResponse['organization_id'] != null) {
        final pId = profileResponse['organization_id'] as String;
        if (!allPotentialOrgIds.contains(pId)) allPotentialOrgIds.add(pId);
      }

      var query = _supabase.from('jobs').select('*').eq('status', 'open');

      if (allPotentialOrgIds.isNotEmpty) {
        query = query.or(
          'organization_id.in.(${allPotentialOrgIds.map((id) => '"$id"').join(',')}),posted_by.eq.${user.id}',
        );
      } else {
        query = query.eq('posted_by', user.id);
      }

      LoggerService.debug('Fetching active jobs with IDs: $allPotentialOrgIds');

      final response = await query
          .order('created_at', ascending: false)
          .limit(5);

      LoggerService.debug('Found ${response.length} active jobs');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      LoggerService.error('Error fetching active jobs', e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEvents({bool allEvents = false}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final companyId = await _discoverCompanyId(user.id);

      final List<String> allPotentialOrgIds = [];
      if (companyId != null) allPotentialOrgIds.add(companyId);
      final profileResponse = await _supabase
          .from('profiles')
          .select('organization_id')
          .eq('id', user.id)
          .maybeSingle();
      if (profileResponse != null &&
          profileResponse['organization_id'] != null) {
        final pId = profileResponse['organization_id'] as String;
        if (!allPotentialOrgIds.contains(pId)) allPotentialOrgIds.add(pId);
      }

      LoggerService.debug(
        'Fetching events for IDs: $allPotentialOrgIds, current user: ${user.id}',
      );

      var query = _supabase.from('events').select('*');

      if (allPotentialOrgIds.isNotEmpty) {
        final orFilter = [
          ...allPotentialOrgIds.map((id) => 'college_id.eq.$id'),
          'created_by.eq.${user.id}',
        ].join(',');
        query = query.or(orFilter);
      } else {
        query = query.eq('created_by', user.id);
      }

      if (!allEvents) {
        // Relaxed filter for debugging: Show all events in the next week or that ended today
        final now = DateTime.now().toUtc();
        final todayStart = DateTime(now.year, now.month, now.day).toUtc();
        query = query.gte('end_date', todayStart.toIso8601String());
      }

      final response = await query
          .order(
            'start_date',
            ascending: !allEvents,
          ) // Show newest first if allEvents
          .limit(allEvents ? 50 : 10);

        LoggerService.debug('getEvents - Found ${response.length} upcoming events');
        if (response.isEmpty) {
          // Check if ANY events exist at all for these filters
          final anyEvents = await _supabase
              .from('events')
              .select('id')
              .or(
                [
                  ...allPotentialOrgIds.map((id) => 'college_id.eq.$id'),
                  'created_by.eq.${user.id}',
                ].join(','),
              )
              .limit(1);
          LoggerService.debug(
            'getEvents - Any events exist for these filters (ignoring date)? ${anyEvents.isNotEmpty}',
          );
        }
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      LoggerService.error('Error fetching company events', e, stack);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRunningCourses() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final companyId = await _discoverCompanyId(user.id);

      final List<String> allPotentialOrgIds = [];
      if (companyId != null) allPotentialOrgIds.add(companyId);

      // Add individual user ID to filters to find courses created by the user directly
      allPotentialOrgIds.add(user.id);

      final profile = await _supabase
          .from('profiles')
          .select('organization_id')
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null && profile['organization_id'] != null) {
        final pId = profile['organization_id'] as String;
        if (!allPotentialOrgIds.contains(pId)) allPotentialOrgIds.add(pId);
      }

      if (allPotentialOrgIds.isEmpty) return [];

      final response = await _supabase
          .from('learning_courses')
          .select('*')
          .inFilter('provider_id', allPotentialOrgIds)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      LoggerService.error('Error fetching running courses', e);
      return [];
    }
  }
}

final activeRecruiterJobsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(recruiterRepositoryProvider).getActiveJobs();
});

final activeRecruiterEventsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(recruiterRepositoryProvider).getEvents();
});

final allRecruiterEventsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(recruiterRepositoryProvider).getEvents(allEvents: true);
});

final runningCoursesProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(recruiterRepositoryProvider).getRunningCourses();
});
