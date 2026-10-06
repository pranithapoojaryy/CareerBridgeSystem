import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/learning_course.dart';
import '../domain/assessment.dart';
import '../../../core/utils/logger_service.dart';

// Provider
final learningRepositoryProvider = Provider<SupabaseLearningRepository>((ref) {
  return SupabaseLearningRepository();
});

final allCoursesProvider = FutureProvider<List<LearningCourse>>((ref) async {
  return ref.read(learningRepositoryProvider).getAllCourses();
});

final myLearningProvider = FutureProvider<List<LearningCourse>>((ref) async {
  return ref.read(learningRepositoryProvider).getMyCourses();
});

final managedCoursesProvider = FutureProvider<List<LearningCourse>>((
  ref,
) async {
  return ref.read(learningRepositoryProvider).getManagedCourses();
});

class SupabaseLearningRepository {
  final _client = Supabase.instance.client;

  Future<List<LearningCourse>> getManagedCourses() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // 1. Get User's Organization
      final userProfile = await _client
          .from('profiles')
          .select('organization_id')
          .eq('id', userId)
          .maybeSingle();

      final orgId = userProfile?['organization_id'];

      // Start with user ID
      List<String> providerIds = [userId];

      if (orgId != null) {
        // Add Organization ID itself (legacy support / direct org ownership)
        providerIds.add(orgId);

        // 2. Get all colleagues in the same organization
        final colleagues = await _client
            .from('profiles')
            .select('id')
            .eq('organization_id', orgId);

        final colleagueIds = (colleagues as List)
            .map((p) => p['id'] as String)
            .toList();
        providerIds.addAll(colleagueIds);
      }

      // Remove duplicates
      providerIds = providerIds.toSet().toList();

      final response = await _client
          .from('learning_courses')
          .select(
            '*, sections:learning_course_sections(*, lectures:learning_course_lectures(*))',
          )
          .filter('provider_id', 'in', providerIds)
          .order('order_index', referencedTable: 'learning_course_sections')
          .order(
            'order_index',
            referencedTable:
                'learning_course_sections.learning_course_lectures',
          )
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) return [];

      // Fetch enrollment counts for these courses
      final courseIds = data.map((c) => c['id']).toList();
      final enrollmentResponse = await _client
          .from('student_course_enrollments')
          .select('course_id')
          .filter('course_id', 'in', courseIds);

      // Count enrollments
      final enrollmentCounts = <String, int>{};
      for (final enrollment in enrollmentResponse as List) {
        final courseId = enrollment['course_id'] as String;
        enrollmentCounts[courseId] = (enrollmentCounts[courseId] ?? 0) + 1;
      }

      return data
          .map((json) {
            final courseId = json['id'] as String;
            json['enrollment_count'] = enrollmentCounts[courseId] ?? 0;
            return LearningCourse.fromJson(json);
          })
          .toList()
          .cast<LearningCourse>();
    } catch (e) {
      LoggerService.error('Error fetching managed courses', e);
      return [];
    }
  }

  Future<List<LearningCourse>> getAllCourses() async {
    try {
      final response = await _client
          .from('learning_courses')
          .select(
            '*, sections:learning_course_sections(*, lectures:learning_course_lectures(*))',
          )
          .eq('is_published', true)
          .order('order_index', referencedTable: 'learning_course_sections')
          .order(
            'order_index',
            referencedTable:
                'learning_course_sections.learning_course_lectures',
          )
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) return [];

      // Fetch enrollment counts for all courses
      final courseIds = data.map((c) => c['id']).toList();
      final enrollmentResponse = await _client
          .from('student_course_enrollments')
          .select('course_id')
          .filter('course_id', 'in', courseIds);

      // Count enrollments per course
      final enrollmentCounts = <String, int>{};
      for (final enrollment in enrollmentResponse as List) {
        final courseId = enrollment['course_id'] as String;
        enrollmentCounts[courseId] = (enrollmentCounts[courseId] ?? 0) + 1;
      }

      // Map to LearningCourse objects with enrollment counts
      return data
          .map((json) {
            final courseId = json['id'] as String;
            json['enrollment_count'] = enrollmentCounts[courseId] ?? 0;
            return LearningCourse.fromJson(json);
          })
          .toList()
          .cast<LearningCourse>();
    } catch (e) {
      LoggerService.error('Error fetching courses', e);
      return [];
    }
  }

  Future<List<LearningCourse>> getMyCourses() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // 1. Get enrolled course IDs
      final enrollments = await _client
          .from('student_course_enrollments')
          .select('course_id, progress_percent')
          .eq('student_id', userId);

      if ((enrollments as List).isEmpty) return [];

      final courseIds = enrollments.map((e) => e['course_id']).toList();

      // 2. Fetch course details
      final response = await _client
          .from('learning_courses')
          .select(
            '*, sections:learning_course_sections(*, lectures:learning_course_lectures(*))',
          )
          .filter('id', 'in', courseIds)
          .order('order_index', referencedTable: 'learning_course_sections')
          .order(
            'order_index',
            referencedTable:
                'learning_course_sections.learning_course_lectures',
          );

      final courses = (response as List)
          .map((json) {
            final course = LearningCourse.fromJson(json);
            // Attach progress if needed
            return course.copyWith(isEnrolled: true);
          })
          .toList()
          .cast<LearningCourse>();

      return courses;
    } catch (e) {
      LoggerService.error('Error fetching my courses', e);
      return [];
    }
  }

  // ============================================
  // COLLEGE: ENROLLMENT MANAGEMENT
  // ============================================

  /// Fetch all enrolled students for a specific course (College view)
  Future<List<Map<String, dynamic>>> getCourseEnrollments(
    String courseId,
  ) async {
    try {
      final response = await _client
          .from('college_enrollment_view')
          .select('*')
          .eq('course_id', courseId)
          .order('enrolled_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      LoggerService.error('Error fetching course enrollments', e);
      return [];
    }
  }

  /// Fetch all enrollments across all courses (College view)
  Future<List<Map<String, dynamic>>> getAllEnrollments() async {
    try {
      final response = await _client
          .from('college_enrollment_view')
          .select('*')
          .order('enrolled_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      LoggerService.error('Error fetching all enrollments', e);
      return [];
    }
  }

  /// Get enrollment count for a course
  Future<int> getCourseEnrollmentCount(String courseId) async {
    try {
      final response = await _client
          .from('student_course_enrollments')
          .select('id')
          .eq('course_id', courseId);

      return (response as List).length;
    } catch (e) {
      LoggerService.error('Error fetching enrollment count', e);
      return 0;
    }
  }

  Future<LearningCourse> getCourseById(String id) async {
    final response = await _client
        .from('learning_courses')
        .select(
          '*, sections:learning_course_sections(*, lectures:learning_course_lectures(*))',
        )
        .eq('id', id)
        .order('order_index', referencedTable: 'learning_course_sections')
        .order(
          'order_index',
          referencedTable: 'learning_course_sections.learning_course_lectures',
        )
        .single();
    return LearningCourse.fromJson(response);
  }

  Future<String> addCourse(LearningCourse course) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // 1. Insert Course
    final courseData = course.toJson();
    courseData['provider_id'] = userId;
    courseData['is_published'] = true;

    final courseRes = await _client
        .from('learning_courses')
        .insert(courseData)
        .select('id')
        .single();

    final courseId = courseRes['id'] as String;

    // 2. Insert Sections & Lectures
    for (var i = 0; i < course.sections.length; i++) {
      final section = course.sections[i];
      final sectionRes = await _client
          .from('learning_course_sections')
          .insert({
            'course_id': courseId,
            'title': section.title,
            'order_index': i,
          })
          .select('id')
          .single();

      final sectionId = sectionRes['id'];

      for (var j = 0; j < section.lectures.length; j++) {
        final lecture = section.lectures[j];
        await _client.from('learning_course_lectures').insert({
          'section_id': sectionId,
          'title': lecture.title,
          'description': lecture.description,
          'content_type': lecture.type,
          'source_type': lecture.sourceType,
          'duration_minutes': lecture.durationMinutes,
          'content_url': lecture.contentUrl,
          'is_mandatory': lecture.isMandatory,
          'order_index': j,
        });
      }
    }
    return courseId;
  }

  Future<void> updateCourse(LearningCourse course) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // 1. Update Course Details
    final courseData = course.toJson();
    courseData.remove('id');
    courseData.remove('created_at');
    courseData.remove('provider_id');

    await _client
        .from('learning_courses')
        .update(courseData)
        .eq('id', course.id);

    // 2. Cleanup orphaned sections and lectures
    // Fetch current state in DB
    final existingSections = await _client
        .from('learning_course_sections')
        .select(
          'id, lectures:learning_course_lectures(id, content_type, content_url)',
        )
        .eq('course_id', course.id);

    final List<dynamic> dbSections = existingSections as List<dynamic>;

    // Track valid IDs from the incoming course object
    final incomingSectionIds = course.sections
        .where((s) => s.id.length > 20)
        .map((s) => s.id)
        .toSet();

    final incomingLectureIds = course.sections
        .expand((s) => s.lectures)
        .where((l) => l.id.length > 20)
        .map((l) => l.id)
        .toSet();

    // Delete orphaned sections (CASCADE handles lectures and assessments linked to section_id)
    for (final dbSection in dbSections) {
      if (!incomingSectionIds.contains(dbSection['id'])) {
        await _client
            .from('learning_course_sections')
            .delete()
            .eq('id', dbSection['id']);
      } else {
        // Section is kept, check for orphaned lectures within it
        final dbLectures = dbSection['lectures'] as List<dynamic>;
        for (final dbLecture in dbLectures) {
          if (!incomingLectureIds.contains(dbLecture['id'])) {
            // If it's an assessment, we might need to delete from learning_course_assessments
            if ((dbLecture['content_type'] == 'quiz' ||
                    dbLecture['content_type'] == 'assignment') &&
                dbLecture['content_url'] != null) {
              // Validate that content_url is a valid UUID before deleting
              final uuidPattern = RegExp(
                r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
                caseSensitive: false,
              );
              if (uuidPattern.hasMatch(dbLecture['content_url'])) {
                await _client
                    .from('learning_course_assessments')
                    .delete()
                    .eq('id', dbLecture['content_url']);
              }
            }

            // Delete the lecture
            await _client
                .from('learning_course_lectures')
                .delete()
                .eq('id', dbLecture['id']);
          }
        }
      }
    }

    // 3. Simple Add/Update strategy for remaining/new items
    for (var i = 0; i < course.sections.length; i++) {
      final section = course.sections[i];
      final sectionData = {
        'course_id': course.id,
        'title': section.title,
        'order_index': i,
      };

      bool isNewSection = section.id.length < 20;
      dynamic sectionId = section.id;

      if (isNewSection) {
        final res = await _client
            .from('learning_course_sections')
            .insert(sectionData)
            .select('id')
            .single();
        sectionId = res['id'];

        // Insert all lectures for this new section
        for (var j = 0; j < section.lectures.length; j++) {
          final lecture = section.lectures[j];
          await _client.from('learning_course_lectures').insert({
            'section_id': sectionId,
            'title': lecture.title,
            'description': lecture.description,
            'content_type': lecture.type,
            'source_type': lecture.sourceType,
            'duration_minutes': lecture.durationMinutes,
            'content_url': lecture.contentUrl,
            'is_mandatory': lecture.isMandatory,
            'order_index': j,
          });
        }
      } else {
        // Existing section - Update title/order
        await _client
            .from('learning_course_sections')
            .update(sectionData)
            .eq('id', sectionId);

        // Handle Lectures in existing section
        for (var j = 0; j < section.lectures.length; j++) {
          final lecture = section.lectures[j];
          bool isNewLecture = lecture.id.length < 20;

          if (isNewLecture) {
            await _client.from('learning_course_lectures').insert({
              'section_id': sectionId,
              'title': lecture.title,
              'description': lecture.description,
              'content_type': lecture.type,
              'source_type': lecture.sourceType,
              'duration_minutes': lecture.durationMinutes,
              'content_url': lecture.contentUrl,
              'is_mandatory': lecture.isMandatory,
              'order_index': j,
            });
          } else {
            // Update existing
            await _client
                .from('learning_course_lectures')
                .update({
                  'title': lecture.title,
                  'description': lecture.description,
                  'duration_minutes': lecture.durationMinutes,
                  'content_url': lecture.contentUrl,
                  'source_type': lecture.sourceType,
                  'is_mandatory': lecture.isMandatory,
                  'order_index': j,
                })
                .eq('id', lecture.id);
          }
        }
      }
    }
  }

  Future<void> enrollInCourse(String courseId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      await _client.from('student_course_enrollments').insert({
        'student_id': userId,
        'course_id': courseId,
        'progress_percent': 0,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // User already enrolled, treat as success
        return;
      }
      rethrow;
    }
  }

  Future<void> deleteCourse(String courseId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      // Delete course (cascading deletes will handle sections, lectures, etc.)
      await _client
          .from('learning_courses')
          .delete()
          .eq('id', courseId)
          .eq('provider_id', userId); // Ensure user owns the course
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }

  // ============================================
  // CURRICULUM METADATA OPERATIONS
  // ============================================

  Future<LearningCourse> getCourseWithFullMetadata(String id) async {
    final response = await _client
        .from('learning_courses')
        .select('''
          *, 
          sections:learning_course_sections(*, lectures:learning_course_lectures(*)),
          it_metadata:learning_course_it_metadata(*),
          mgmt_metadata:learning_course_mgmt_metadata(*)
        ''')
        .eq('id', id)
        .single();

    final course = LearningCourse.fromJson(response);

    // Attach IT metadata if exists
    if (response['it_metadata'] != null) {
      return course.copyWith(
        itMetadata: ITCourseMetadata.fromJson(response['it_metadata']),
      );
    }

    // Attach Management metadata if exists
    if (response['mgmt_metadata'] != null) {
      return course.copyWith(
        managementMetadata: ManagementCourseMetadata.fromJson(
          response['mgmt_metadata'],
        ),
      );
    }

    return course;
  }

  Future<void> updateITMetadata(
    String courseId,
    ITCourseMetadata metadata,
  ) async {
    await _client.from('learning_course_it_metadata').upsert({
      'course_id': courseId,
      ...metadata.toJson(),
    });
  }

  Future<void> updateManagementMetadata(
    String courseId,
    ManagementCourseMetadata metadata,
  ) async {
    await _client.from('learning_course_mgmt_metadata').upsert({
      'course_id': courseId,
      ...metadata.toJson(),
    });
  }

  // ============================================
  // ASSESSMENT OPERATIONS
  // ============================================

  Future<String> createAssessment(Assessment assessment) async {
    final response = await _client
        .from('learning_course_assessments')
        .insert(assessment.toJson())
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<List<Assessment>> getAssessmentsBySectionId(String sectionId) async {
    final response = await _client
        .from('learning_course_assessments')
        .select('*')
        .eq('section_id', sectionId)
        .order('created_at');

    return (response as List).map((json) => Assessment.fromJson(json)).toList();
  }

  Future<Assessment> getAssessmentById(String assessmentId) async {
    final response = await _client
        .from('learning_course_assessments')
        .select('*')
        .eq('id', assessmentId)
        .single();

    return Assessment.fromJson(response);
  }

  Future<String> submitAssessment(AssessmentSubmission submission) async {
    final response = await _client
        .from('student_assessment_submissions')
        .insert(submission.toJson())
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<void> evaluateSubmission(
    String submissionId,
    double score,
    bool isPassed,
    String? feedback,
  ) async {
    final userId = _client.auth.currentUser?.id;

    await _client
        .from('student_assessment_submissions')
        .update({
          'score': score,
          'is_passed': isPassed,
          'faculty_feedback': feedback,
          'evaluated_at': DateTime.now().toIso8601String(),
          'evaluated_by': userId,
        })
        .eq('id', submissionId);
  }

  Future<List<AssessmentSubmission>> getStudentSubmissions(
    String studentId,
    String assessmentId,
  ) async {
    final response = await _client
        .from('student_assessment_submissions')
        .select('*')
        .eq('student_id', studentId)
        .eq('assessment_id', assessmentId)
        .order('submitted_at', ascending: false);

    return (response as List)
        .map((json) => AssessmentSubmission.fromJson(json))
        .toList();
  }

  Future<AssessmentSubmission?> getLatestSubmission(
    String studentId,
    String assessmentId,
  ) async {
    try {
      final response = await _client
          .from('student_assessment_submissions')
          .select('*')
          .eq('student_id', studentId)
          .eq('assessment_id', assessmentId)
          .order('attempt_number', ascending: false)
          .limit(1);

      final data = response as List<dynamic>;
      if (data.isEmpty) return null;
      return AssessmentSubmission.fromJson(data.first);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingAssessmentsForStudent() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // 1. Get enrolled course IDs
      final enrollments = await _client
          .from('student_course_enrollments')
          .select('course_id')
          .eq('student_id', userId);

      if ((enrollments as List).isEmpty) return [];

      final courseIds = enrollments.map((e) => e['course_id']).toList();

      // 2. Get Section IDs for these courses
      // We also fetch course title for display
      final sectionsResponse = await _client
          .from('learning_course_sections')
          .select('id, course_id, course:learning_courses(title)')
          .inFilter('course_id', courseIds);

      final sections = sectionsResponse as List<dynamic>;
      if (sections.isEmpty) return [];

      final sectionIds = sections.map((s) => s['id']).toList();
      final sectionMap = {for (var s in sections) s['id']: s};

      // 3. Get all assessment lectures for these sections
      final response = await _client
          .from('learning_course_lectures')
          .select('*')
          .inFilter('section_id', sectionIds)
          .inFilter('content_type', ['assignment', 'quiz']);

      final assessments = response as List<dynamic>;
      if (assessments.isEmpty) return [];

      // 4. Filter out completed ones
      final lectureIds = assessments.map((a) => a['id']).toList();

      final progress = await _client
          .from('student_lecture_progress')
          .select('lecture_id')
          .eq('student_id', userId)
          .eq('is_completed', true)
          .inFilter('lecture_id', lectureIds);

      final completedLectureIds = (progress as List)
          .map((p) => p['lecture_id'])
          .toSet();

      final pendingAssessments = assessments
          .where((a) {
            return !completedLectureIds.contains(a['id']);
          })
          .map((a) {
            final section = sectionMap[a['section_id']];
            return {
              'id': a['content_url'], // The actual assessment ID
              'lecture_id': a['id'],
              'title': a['title'],
              'course_title': section != null
                  ? section['course']['title']
                  : 'Unknown Course',
              'course_id': section != null
                  ? section['course_id']
                  : '', // Added course_id
              'duration_minutes': a['duration_minutes'],
              'type': 'system_2', // Marker to distinguish from System 1
            };
          })
          .toList();

      return pendingAssessments;
    } catch (e) {
      LoggerService.error('Error fetching pending assessments', e);
      return [];
    }
  }

  // ============================================
  // PROGRESS TRACKING
  // ============================================

  Future<void> markLectureComplete(String lectureId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Use a SECURITY DEFINER RPC to bypass RLS complexity on insert
      final result = await _client.rpc(
        'mark_lecture_complete',
        params: {'p_lecture_id': lectureId},
      );

      final data = result as Map<String, dynamic>;
      if (data['success'] != true) {
        LoggerService.error(
          'mark_lecture_complete RPC failed',
          data['error'],
        );
      }
    } catch (e) {
      LoggerService.error('Error marking lecture complete', e);
    }
  }

  Future<void> updateLectureProgress(
    String lectureId,
    int watchDurationSeconds,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('student_lecture_progress').upsert({
      'student_id': userId,
      'lecture_id': lectureId,
      'watch_duration_seconds': watchDurationSeconds,
    });
  }

  Future<List<LectureProgress>> getLectureProgress(String courseId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // 1. Get enrollment_id for this course
      final enrollmentRes = await _client
          .from('student_course_enrollments')
          .select('id')
          .eq('student_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (enrollmentRes == null) return [];
      final enrollmentId = enrollmentRes['id'] as String;

      // 2. Get Progress via enrollment_id (matches the unique constraint)
      final response = await _client
          .from('student_lecture_progress')
          .select('*')
          .eq('enrollment_id', enrollmentId);

      return (response as List)
          .map((json) => LectureProgress.fromJson(json))
          .toList();
    } catch (e) {
      // Return empty list on error instead of throwing, to prevent UI crash
      return [];
    }
  }

  Future<void> updateModuleProgress(
    String sectionId,
    ModuleStatus status,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final data = {
      'student_id': userId,
      'section_id': sectionId,
      'status': status.toString(),
    };

    if (status == ModuleStatus.inProgress && data['started_at'] == null) {
      data['started_at'] = DateTime.now().toIso8601String();
    }

    if (status == ModuleStatus.completed) {
      data['completed_at'] = DateTime.now().toIso8601String();
    }

    await _client.from('student_module_progress').upsert(data);
  }

  Future<List<ModuleProgress>> getModuleProgress(String courseId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Get all section IDs for this course
    final sections = await _client
        .from('learning_course_sections')
        .select('id')
        .eq('course_id', courseId);

    final sectionIds = (sections as List).map((s) => s['id']).toList();

    final response = await _client
        .from('student_module_progress')
        .select('*')
        .eq('student_id', userId)
        .inFilter('section_id', sectionIds);

    return (response as List)
        .map((json) => ModuleProgress.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> getCourseProgress(String courseId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return {
        'progress_percent': 0.0,
        'completed_lectures': 0,
        'total_lectures': 0,
      };
    }

    // Get total lectures
    final totalLecturesResponse = await _client.rpc(
      'get_course_lecture_count',
      params: {'course_uuid': courseId},
    );

    final totalLectures = totalLecturesResponse as int? ?? 0;

    // Get completed lectures
    final completedLectures = await getLectureProgress(courseId);
    final completedCount = completedLectures.where((l) => l.completed).length;

    final progressPercent = totalLectures > 0
        ? (completedCount / totalLectures)
        : 0.0;

    return {
      'progress_percent': progressPercent,
      'completed_lectures': completedCount,
      'total_lectures': totalLectures,
    };
  }

  // ============================================
  // FACULTY MANAGEMENT
  // ============================================

  Future<void> assignFacultyGuide(String courseId, String facultyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('student_course_enrollments')
        .update({'assigned_guide_id': facultyId})
        .eq('student_id', userId)
        .eq('course_id', courseId);
  }

  Future<void> addFacultyRemark(String courseId, String remark) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('student_course_enrollments')
        .update({'faculty_remarks': remark})
        .eq('student_id', userId)
        .eq('course_id', courseId);
  }

  Future<String?> getFacultyRemarks(String courseId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('student_course_enrollments')
          .select('faculty_remarks')
          .eq('student_id', userId)
          .eq('course_id', courseId)
          .single();

      return response['faculty_remarks'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Generates (or retrieves existing) certificate for a course.
  /// Returns the stable certificate ID (e.g. "EH-A3F72C1B") or null on failure.
  Future<String?> generateCertificate(String courseId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      // Call the RPC to generate/ensure the cert exists
      await _client.rpc(
        'generate_certificate_for_student',
        params: {'p_student_id': userId, 'p_course_id': courseId},
      );

      // Always re-fetch from DB to get the exact stored value
      // This guarantees the QR code always matches what's in the database
      final enrollment = await _client
          .from('student_course_enrollments')
          .select('certificate_url')
          .eq('student_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();

      final certId = enrollment?['certificate_url'] as String?;
      LoggerService.info('Certificate ID for course $courseId: $certId');
      return certId;
    } catch (e) {
      LoggerService.error('Error generating certificate', e);
      return null;
    }
  }

  Future<bool> checkAllModulesCompleted(String courseId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Get all sections for the course
      final sections = await _client
          .from('learning_course_sections')
          .select('id, lectures:learning_course_lectures(id)')
          .eq('course_id', courseId);

      final allLectureIds = <String>[];
      for (final section in sections) {
        final lectures = section['lectures'] as List;
        for (final lecture in lectures) {
          allLectureIds.add(lecture['id'] as String);
        }
      }

      if (allLectureIds.isEmpty)
        return true; // No content, technically completed

      // Get enrollment_id for this student + course
      final enrollmentRes = await _client
          .from('student_course_enrollments')
          .select('id')
          .eq('student_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (enrollmentRes == null) return false;
      final enrollmentId = enrollmentRes['id'] as String;

      final completedLectures = await _client
          .from('student_lecture_progress')
          .select('lecture_id')
          .eq('enrollment_id', enrollmentId)
          .eq('is_completed', true)
          .inFilter('lecture_id', allLectureIds);

      return (completedLectures as List).length == allLectureIds.length;
    } catch (e) {
      return false;
    }
  }
}

// Provider for course progress
final courseProgressProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, courseId) async {
      try {
        final result = await ref
            .read(learningRepositoryProvider)
            .getCourseProgress(courseId);
        return result;
      } catch (e) {
        return {
          'progress_percent': 0.0,
          'completed_lectures': 0,
          'total_lectures': 0,
        }; // Default structure on error
      }
    });
