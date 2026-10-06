import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/logger_service.dart';

final studentAnalyticsRepositoryProvider = Provider<StudentAnalyticsRepository>(
  (ref) {
    return StudentAnalyticsRepository(Supabase.instance.client);
  },
);

class StudentAnalyticsRepository {
  final SupabaseClient _client;

  StudentAnalyticsRepository(this._client);

  // 1. Fetch Skill Scores
  Future<List<Map<String, dynamic>>> getSkillScores(String studentId) async {
    try {
      final response = await _client
          .from('student_skill_scores')
          .select('*')
          .eq('student_id', studentId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      LoggerService.error('Error fetching skill scores', e);
      return [];
    }
  }

  // 2. Fetch Course Enrollments (Manual Join)
  Future<List<Map<String, dynamic>>> getCourseProgress(String studentId) async {
    try {
      // 1. Get Enrollments
      final enrollmentsResponse = await _client
          .from('student_course_enrollments')
          .select('*')
          .eq('student_id', studentId);
      final enrollments = List<Map<String, dynamic>>.from(enrollmentsResponse);

      if (enrollments.isEmpty) return [];

      // 2. Get Course Details
      final courseIds = enrollments
          .map((e) => e['course_id'])
          .where((id) => id != null)
          .toList();
      if (courseIds.isEmpty) return enrollments;

      final coursesResponse = await _client
          .from('learning_courses')
          .select('id, title, thumbnail_url')
          .filter('id', 'in', courseIds);
      final courses = List<Map<String, dynamic>>.from(coursesResponse);
      final coursesMap = {for (var c in courses) c['id']: c};

      // 3. Merge
      return enrollments.map((e) {
        // Calculate status locally if needed or trust DB?
        // Let's trust DB for now, but UI can show 'Sync Needed' if 0% and completed?
        // Actually, let's just return as is.
        return {
          ...e,
          'course': coursesMap[e['course_id']] ?? {'title': 'Unknown Course'},
        };
      }).toList();
    } catch (e) {
      LoggerService.error('Error fetching course progress', e);
      return [];
    }
  }

  // 3. Fetch Aptitude Test Attempts (Manual Join)
  Future<List<Map<String, dynamic>>> getAptitudeAttempts(
    String studentId,
  ) async {
    try {
      // 1. Get Attempts
      final attemptsResponse = await _client
          .from('aptitude_attempts')
          .select('*')
          .eq('student_id', studentId) // Corrected from user_id
          .order('created_at', ascending: false);
      final attempts = List<Map<String, dynamic>>.from(attemptsResponse);

      if (attempts.isEmpty) return [];

      // 2. Get Test Titles (Assuming test_id exists, or we use test_type as fallback)
      // Some attempts might just have 'test_type' and no 'test_id' depending on implementation
      // But let's check for test_id to be safe
      return attempts.map((a) {
        // If we have test_id, we could fetch title, but often test_type is enough or title is in attempt?
        // Checking columns: test_type, module_name are in aptitude_attempts.
        // So we might not need to join aptitude_tests if test_type/module_name is sufficient.
        // Let's rely on test_type for now to be safe and fast.
        return a;
      }).toList();
    } catch (e) {
      LoggerService.error('Error fetching aptitude attempts', e);
      return [];
    }
  }

  // 4. Fetch Mock Interview Attempts
  Future<List<Map<String, dynamic>>> getMockInterviewAttempts(
    String studentId,
  ) async {
    try {
      final response = await _client
          .from('mock_attempts')
          .select('*')
          .eq('student_id', studentId); // Corrected from user_id
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      LoggerService.error('Error fetching mock interview attempts', e);
      return [];
    }
  }
}
