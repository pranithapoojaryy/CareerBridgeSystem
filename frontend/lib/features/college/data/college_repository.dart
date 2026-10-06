import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger_service.dart';

class CollegeRepository {
  final SupabaseClient _supabase;

  CollegeRepository(this._supabase);

  // =====================================================
  // EVENTS MANAGEMENT
  // =====================================================

  Future<List<Map<String, dynamic>>> getEvents({
    String? collegeId,
    String? eventType,
    String? status,
  }) async {
    var query = _supabase.from('events').select('''
      *,
      event_registrations(count)
    ''');

    if (collegeId != null) {
      query = query.eq('college_id', collegeId);
    }
    if (eventType != null && eventType != 'all') {
      query = query.eq('event_type', eventType);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    return await query.order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> createEvent(
    Map<String, dynamic> eventData,
  ) async {
    final response = await _supabase
        .from('events')
        .insert(eventData)
        .select()
        .single();
    return response;
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    await _supabase.from('events').update(updates).eq('id', eventId);
  }

  Future<void> deleteEvent(String eventId) async {
    await _supabase.from('events').delete().eq('id', eventId);
  }

  Future<Map<String, dynamic>> getEventStats(String collegeId) async {
    final events = await _supabase
        .from('events')
        .select('status')
        .eq('college_id', collegeId);

    final registrations = await _supabase
        .from('event_registrations')
        .select('event_id')
        .eq('status', 'registered');

    return {
      'total_events': events.length,
      'active_events': events.where((e) => e['status'] == 'ongoing').length,
      'total_participants': registrations.length,
      'completion_rate': 87, // Calculate based on actual data
    };
  }

  // =====================================================
  // SKILL ASSESSMENTS
  // =====================================================

  Future<List<Map<String, dynamic>>> getAssessments({
    String? collegeId,
    String? category,
    bool? isActive,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // 1. Fetch basics just like QuestionBankScreen
      var query = _supabase
          .from('aptitude_tests')
          .select()
          .eq('created_by', userId);

      if (category != null && category != 'all') {
        // query = query.eq('test_type', category); // Optional
      }

      final response = await query.order('created_at', ascending: false);
      final dataList = response as List<dynamic>;

      // 2. Map manually (and safely)
      return dataList
          .map((test) {
            return {
              'id': test['id'],
              'test_id': test['id'],
              'title': test['title'] ?? 'Untitled',
              'description': test['description'],
              'category': test['test_type'] ?? 'aptitude',
              'skill': 'General',
              'difficulty': test['difficulty'] ?? 'intermediate',
              'duration': test['duration_minutes'] ?? 0,
              'totalQuestions': test['total_questions'] ?? 0,
              'passingScore': test['passing_score'] ?? 0,
              'isActive': test['is_active'] == true,
              'totalAttempts': 0, // Temporarily 0 to fix buffering
              'averageScore': 0.0,
              'createdBy': 'Admin', // Placeholder
              'created_at': test['created_at'],
            };
          })
          .toList()
          .cast<Map<String, dynamic>>();
    } catch (e) {
      LoggerService.error('Error fetching assessments', e);
      return [];
    }
  }

  Future<Map<String, dynamic>> createAssessment(
    Map<String, dynamic> assessmentData,
  ) async {
    // Logic to call RPC create_full_aptitude_test
    // We need to split assessmentData into testData, questions (empty), assignmentData

    // Minimal mapping from the simple dialog data:
    final testData = {
      'title': assessmentData['title'],
      'description': assessmentData['instructions'], // description
      'instructions': assessmentData['instructions'],
      'module_id':
          '00000000-0000-0000-0000-000000000000', // Placeholder or fetch
      'test_type': assessmentData['category'],
      'difficulty': assessmentData['difficulty'],
      'duration_minutes': assessmentData['duration_minutes'],
      'passing_score': assessmentData['passing_score'],
      'organization_id': (await getOrganizationByUserId(
        _supabase.auth.currentUser!.id,
      ))?['id'],
    };

    final assignmentData = {
      'assignment_type': 'all_students', // Default to all_students
      'assigned_by_role': 'college_admin',
      'assigned_to_user': _supabase.auth.currentUser!.id, // Self for draft?
      'is_mandatory': false,
      'max_attempts': (assessmentData['allow_retakes'] == true) ? 3 : 1,
      'start_date': DateTime.now().toIso8601String(),
      'deadline': DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String(),
    };

    final response = await _supabase.rpc(
      'create_full_aptitude_test',
      params: {
        'p_test_data': testData,
        'p_questions_data': [],
        'p_assignment_data': assessmentData['is_active'] == true
            ? assignmentData
            : null,
      },
    );

    return response as Map<String, dynamic>;
  }

  Future<void> updateAssessment(
    String assessmentId,
    Map<String, dynamic> updates,
  ) async {
    await _supabase
        .from('aptitude_tests')
        .update(updates)
        .eq('id', assessmentId);
  }

  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _supabase.rpc(
        'delete_aptitude_test',
        params: {'p_test_id': assessmentId},
      );
    } catch (e) {
      throw Exception('Failed to delete assessment: $e');
    }
  }

  Future<Map<String, dynamic>?> getAssignment(String testId) async {
    final response = await _supabase
        .from('test_assignments')
        .select()
        .eq('test_id', testId)
        .maybeSingle(); // Assumes 1 assignment per test for now
    return response;
  }

  Future<void> updateAssignment(
    String assignmentId,
    Map<String, dynamic> updates,
  ) async {
    await _supabase
        .from('test_assignments')
        .update(updates)
        .eq('id', assignmentId);
  }

  Future<Map<String, dynamic>> getAssessmentStats(String collegeId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // 1. Get tests created by this user/college
      final testsResponse = await _supabase
          .from('aptitude_tests')
          .select('id, is_active')
          .eq('created_by', userId);

      final tests = List<Map<String, dynamic>>.from(testsResponse);
      final totalAssessments = tests.length;
      final activeAssessments = tests
          .where((t) => t['is_active'] == true)
          .length;

      if (tests.isEmpty) {
        return {
          'total_assessments': 0,
          'active_assessments': 0,
          'total_attempts': 0,
          'average_score': 0.0,
          'pass_rate': 0.0,
        };
      }

      final testIds = tests.map((t) => t['id']).toList();

      // 2. Get attempts for these tests
      // Using .inFilter for robust Id matching
      final attemptsResponse = await _supabase
          .from('aptitude_attempts')
          .select('score, status')
          .inFilter('test_id', testIds);

      final attempts = List<Map<String, dynamic>>.from(attemptsResponse);
      final totalAttempts = attempts.length;

      double averageScore = 0.0;
      double passRate = 0.0;

      if (totalAttempts > 0) {
        final totalScore = attempts.fold<double>(
          0,
          (sum, item) => sum + (item['score'] as num? ?? 0).toDouble(),
        );
        averageScore = totalScore / totalAttempts;

        final passedCount = attempts
            .where((a) => a['status'] == 'passed')
            .length;
        passRate = (passedCount / totalAttempts) * 100;
      }

      return {
        'total_assessments': totalAssessments,
        'active_assessments': activeAssessments,
        'total_attempts': totalAttempts,
        'average_score': averageScore,
        'pass_rate': passRate,
      };
    } catch (e) {
      LoggerService.error('Error calculating assessment stats', e);
      return {
        'total_assessments': 0,
        'active_assessments': 0,
        'total_attempts': 0,
        'average_score': 0.0,
        'pass_rate': 0.0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getAssessmentAttempts(
    String assessmentId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_test_attempts_admin',
        params: {'p_test_id': assessmentId},
      );

      return (response as List)
          .map((attempt) {
            return {
              ...attempt,
              'profiles': {
                'full_name': attempt['student_name'] ?? 'Unknown Student',
                'email': attempt['student_email'] ?? 'No Email',
                'avatar_url': attempt['student_avatar'],
              },
            };
          })
          .toList()
          .cast<Map<String, dynamic>>();
    } catch (e) {
      LoggerService.error('Error fetching assessment attempts', e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSkills() async {
    return await _supabase
        .from('skills')
        .select()
        .eq('is_active', true)
        .order('name');
  }

  Future<List<Map<String, dynamic>>> getQuestions(String testId) async {
    // 1. Fetch all questions (optionally filter by module if available to reduce load)
    // Since we can't easily join or reliable filter JSONB tags in all Supabase versions via standard SDK
    final response = await _supabase
        .from('aptitude_questions')
        .select()
        .order('created_at');

    final allQuestions = List<Map<String, dynamic>>.from(response);

    // 2. Filter in Dart for the tag "test_id:UUID"
    // tags is a List<dynamic> (JSONB list)
    return allQuestions.where((q) {
      final tags = q['tags'];
      if (tags is List) {
        return tags.contains('test_id:$testId');
      }
      return false;
    }).toList();
  }

  Future<void> updateQuestion(
    String questionId,
    Map<String, dynamic> updates,
  ) async {
    await _supabase
        .from('aptitude_questions')
        .update(updates)
        .eq('id', questionId);
  }

  Future<void> deleteQuestion(String questionId) async {
    await _supabase.from('aptitude_questions').delete().eq('id', questionId);
  }

  Future<Map<String, dynamic>> createQuestion(
    Map<String, dynamic> questionData,
  ) async {
    return await _supabase
        .from('aptitude_questions')
        .insert(questionData)
        .select()
        .single();
  }

  // =====================================================
  // STUDENT MANAGEMENT
  // =====================================================

  Future<List<Map<String, dynamic>>> getStudents({
    String? collegeId,
    String? department,
    String? batch,
    String? placementStatus,
    String? searchQuery,
  }) async {
    try {
      LoggerService.debug('Fetching students via RPC for college: $collegeId');

      if (collegeId == null) return [];

      final response = await _supabase.rpc(
        'get_college_students_v2',
        params: {'p_org_id': collegeId, 'p_search_query': searchQuery},
      );

      // Cast response safely
      final results = List<Map<String, dynamic>>.from(response);

      LoggerService.debug('Returning ${results.length} students with real data via RPC');
      return results;
    } catch (e) {
      LoggerService.error('Error fetching students via RPC', e);
      return [];
    }
  }

  Future<void> verifyStudent(String studentId) async {
    await _supabase.rpc(
      'verify_student_v2',
      params: {'student_uuid': studentId},
    );
  }

  Future<Map<String, dynamic>> getStudentStats(String collegeId) async {
    try {
      // 1. Get official stats from RPC for consistency with dashboard
      final dashboardStats = await getCollegeDashboardStatsV2(collegeId);
      final totalStudents = (dashboardStats['total_students'] ?? 0) as int;
      final activeStudents = (dashboardStats['active_students'] ?? 0) as int;
      final placementRate = (dashboardStats['placement_rate'] ?? 0) as int;

      LoggerService.debug(
        'Found $totalStudents students and $placementRate% placement rate via RPC',
      );

      if (totalStudents == 0) {
        return {
          'total_students': 0,
          'active_students': 0,
          'placement_rate': 0,
          'average_cgpa': 0.0,
          'average_completion': 0,
        };
      }

      // 2. Fetch CGPA and Profile Completion in a single efficient query (joining student_profiles)
      final profilesResp = await _supabase
          .from('profiles')
          .select('profile_completion, student_profiles(cgpa)')
          .eq('organization_id', collegeId)
          .neq('role', 'college_admin');

      final profiles = List<Map<String, dynamic>>.from(profilesResp);

      // Average CGPA calculation
      final validCgpas = profiles
          .where((p) {
            final sp = p['student_profiles'];
            final cgpaValue = sp is List
                ? (sp.isNotEmpty ? sp[0]['cgpa'] : null)
                : (sp != null ? sp['cgpa'] : null);
            return cgpaValue != null && (cgpaValue as num) > 0;
          })
          .map((p) {
            final sp = p['student_profiles'];
            return sp is List
                ? (sp[0]['cgpa'] as num).toDouble()
                : (sp['cgpa'] as num).toDouble();
          })
          .toList();

      final averageCgpa = validCgpas.isNotEmpty
          ? validCgpas.fold(0.0, (a, b) => a + b) / validCgpas.length
          : 0.0;

      // Average Completion calculation
      final validCompletions = profiles
          .where((p) => p['profile_completion'] != null)
          .map((p) => (p['profile_completion'] as num).toInt())
          .toList();

      final averageCompletion = validCompletions.isNotEmpty
          ? (validCompletions.fold(0, (a, b) => a + b) /
                    validCompletions.length)
                .round()
          : 50;

      final stats = {
        'total_students': totalStudents,
        'active_students': activeStudents > 0 ? activeStudents : totalStudents,
        'placement_rate': placementRate,
        'average_cgpa': averageCgpa,
        'average_completion': averageCompletion,
      };

      LoggerService.debug('Calculated stats: $stats');
      return stats;
    } catch (e) {
      LoggerService.error('Error fetching student stats', e);
      return {
        'total_students': 0,
        'active_students': 0,
        'placement_rate': 0,
        'average_cgpa': 0.0,
        'average_completion': 0,
      };
    }
  }

  Future<void> updateStudentStatus(
    String studentId,
    Map<String, dynamic> updates,
  ) async {
    await _supabase
        .from('student_profiles')
        .update(updates)
        .eq('id', studentId);
  }

  Future<void> deleteStudent(String studentId) async {
    // Delete dependent records first due to NO ACTION constraints
    await _supabase
        .from('job_applications')
        .delete()
        .eq('student_id', studentId);
    await _supabase.from('student_profiles').delete().eq('id', studentId);
    await _supabase.from('profiles').delete().eq('id', studentId);
  }

  Future<void> sendBulkMessage(List<String> studentIds, String message) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    final messages = studentIds
        .map(
          (studentId) => {
            'sender_id': currentUserId,
            'recipient_id': studentId,
            'content': message,
            'message_type': 'text',
          },
        )
        .toList();

    await _supabase.from('messages').insert(messages);
  }

  // =====================================================
  // LEARNING COURSES (FIXED TABLE NAMES)
  // =====================================================

  Future<List<Map<String, dynamic>>> getLearningPaths({
    String? collegeId,
    String? category,
    bool? isPublished,
  }) async {
    var query = _supabase.from('learning_courses').select('''
      *,
      learning_course_sections!learning_course_sections_course_id_fkey(count)
    ''');

    if (collegeId != null) {
      // Note: learning_courses doesn't have college_id, uses provider_id
      query = query.eq('provider_id', collegeId);
    }
    if (category != null) {
      query = query.eq('category', category);
    }
    if (isPublished != null) {
      query = query.eq('is_published', isPublished);
    }

    return await query.order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> createLearningPath(
    Map<String, dynamic> pathData,
  ) async {
    // 1. Separate nested data
    final sections = (pathData['sections'] as List?) ?? [];

    // Create a copy of pathData without sections to insert into learning_courses
    final courseData = Map<String, dynamic>.from(pathData);
    courseData.remove('sections');

    // Ensure provider_id is set
    if (courseData['provider_id'] == null) {
      courseData['provider_id'] = _supabase.auth.currentUser?.id;
    }

    try {
      // 2. Insert Course
      final courseResponse = await _supabase
          .from('learning_courses')
          .insert(courseData)
          .select()
          .single();

      final courseId = courseResponse['id'];

      // 3. Insert Sections & Lectures
      if (sections.isNotEmpty) {
        for (int i = 0; i < sections.length; i++) {
          final sectionData = sections[i] as Map<String, dynamic>;
          final lectures = (sectionData['lectures'] as List?) ?? [];

          // Prepare section payload
          final sectionInsert = {
            'course_id': courseId,
            'title': sectionData['title'],
            'description': sectionData['description'],
            'module_type': sectionData['module_type'], // Theory, Practice, etc.
            'estimated_hours': sectionData['estimated_hours'],
            'is_mandatory': sectionData['is_mandatory'] ?? true,
            'unlock_rule': sectionData['unlock_rule'] ?? 'Sequential',
            'skills_covered': sectionData['skills_covered'], // Array
            'assessment_required': sectionData['assessment_required'] ?? false,
            'completion_criteria': sectionData['completion_criteria'],
            'sequence_order': i, // Maintain order
          };

          // Insert Section
          final sectionResponse = await _supabase
              .from('learning_course_sections')
              .insert(sectionInsert)
              .select()
              .single();

          final sectionId = sectionResponse['id'];

          // 4. Insert Lectures for this Section
          if (lectures.isNotEmpty) {
            final lecturesInsert = lectures.asMap().entries.map((entry) {
              final idx = entry.key;
              final lecture = entry.value as Map<String, dynamic>;
              return {
                'section_id': sectionId,
                'title': lecture['title'],
                'description': lecture['description'],
                'content_type': lecture['content_type'] ?? 'video',
                'source_type': lecture['source_type'],
                'content_url': lecture['content_url'],
                'duration_minutes': lecture['duration_minutes'],
                'is_mandatory': lecture['is_mandatory'] ?? true,
                'order_index': idx, // Maintain order
              };
            }).toList();

            await _supabase
                .from('learning_course_lectures')
                .insert(lecturesInsert);
          }
        }
      }

      return courseResponse;
    } catch (e) {
      LoggerService.error('Error creating learning path', e);
      rethrow;
    }
  }

  // =====================================================
  // ANNOUNCEMENTS
  // =====================================================

  Future<List<Map<String, dynamic>>> getAnnouncements({
    String? collegeId,
    String? type,
    bool? isPublished,
  }) async {
    var query = _supabase.from('announcements').select();

    if (collegeId != null) {
      query = query.eq('college_id', collegeId);
    }
    if (type != null) {
      query = query.eq('announcement_type', type);
    }
    if (isPublished != null) {
      query = query.eq('is_published', isPublished);
    }

    return await query.order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> createAnnouncement(
    Map<String, dynamic> announcementData,
  ) async {
    final response = await _supabase
        .from('announcements')
        .insert(announcementData)
        .select()
        .single();
    return response;
  }

  // =====================================================
  // ANALYTICS
  // =====================================================

  Future<Map<String, dynamic>> getCollegeAnalytics(String collegeId) async {
    // Get various metrics for the college dashboard
    final studentStats = await getStudentStats(collegeId);
    final eventStats = await getEventStats(collegeId);
    final assessmentStats = await getAssessmentStats(collegeId);

    return {
      'students': studentStats,
      'events': eventStats,
      'assessments': assessmentStats,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> getCollegeDashboardStatsV2(
    String collegeId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_college_dashboard_stats_v2',
        params: {'p_org_id': collegeId},
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Error calling get_college_dashboard_stats_v2', e);
      return {
        'total_students': 0,
        'active_students': 0,
        'active_events': 0,
        'placement_rate': 0,
        'program_split': [],
      };
    }
  }

  // =====================================================
  // ORGANIZATION MANAGEMENT
  // =====================================================

  Future<Map<String, dynamic>?> getOrganizationByUserId(String userId) async {
    final result = await _supabase
        .from('organizations')
        .select()
        .eq('created_by', userId)
        .maybeSingle();
    return result;
  }

  Future<void> updateOrganization(
    String orgId,
    Map<String, dynamic> updates,
  ) async {
    await _supabase.from('organizations').update(updates).eq('id', orgId);
  }

  // =====================================================
  // DEPARTMENTS & PROGRAMS
  // =====================================================

  Future<List<Map<String, dynamic>>> getDepartments(String collegeId) async {
    return await _supabase
        .from('college_departments')
        .select()
        .eq('org_id', collegeId)
        .order('name');
  }

  Future<List<Map<String, dynamic>>> getPrograms(String departmentId) async {
    return await _supabase
        .from('college_programs')
        .select()
        .eq('dept_id', departmentId)
        .order('name');
  }

  Future<List<Map<String, dynamic>>> getBatches(String programId) async {
    return await _supabase
        .from('college_batches')
        .select()
        .eq('program_id', programId)
        .order('start_year', ascending: false);
  }
  // =====================================================
  // CERTIFICATION MANAGEMENT
  // =====================================================

  /// Fetch pending certifications for the college
  Future<List<Map<String, dynamic>>> getPendingCertifications({
    required String collegeId,
  }) async {
    try {
      final response = await _supabase
          .from('view_college_verification_queue')
          .select()
          .eq('college_id', collegeId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // If view doesn't exist, fallback to direct query (for safety)
      final response = await _supabase
          .from('student_certifications')
          .select(
            '*, profiles:student_id(full_name, email, enroll_no), certification_providers(name)',
          )
          .eq('validation_status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    }
  }

  /// Fetch ALL certifications for the college (all statuses)
  Future<List<Map<String, dynamic>>> getAllCertifications({
    required String collegeId,
    String? status, // optional filter by status
  }) async {
    try {
      var query = _supabase
          .from('view_college_all_certifications')
          .select()
          .eq('college_id', collegeId);

      if (status != null) {
        if (status == 'approved' || status == 'college_verified') {
          // Both mean success. Use filter to include all confirmed statuses.
          query = query.filter('validation_status', 'in', ['verified', 'approved', 'college_verified']);
        } else {
          query = query.eq('validation_status', status);
        }
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      LoggerService.error('Error fetching all certifications', e);
      return [];
    }
  }

  /// Update certification status (Approve/Reject)
  Future<void> updateCertificationStatus({
    required String certificationId,
    required String status, // 'college_verified' or 'rejected'
    String? rejectionReason,
  }) async {
    final Map<String, dynamic> updates = {
      'validation_status': status,
      'verified_at': DateTime.now().toIso8601String(),
    };

    if (status == 'college_verified') {
      updates['trust_level'] = 100;
      // Award skill points for approval (base 50 points for college verification)
      updates['skill_points_awarded'] = 50;
    } else if (status == 'rejected') {
      if (rejectionReason != null) {
        updates['rejection_reason'] = rejectionReason;
      }
      updates['trust_level'] = 0;
      updates['skill_points_awarded'] = 0;
    }

    await _supabase
        .from('student_certifications')
        .update(updates)
        .eq('id', certificationId);
  }
}
