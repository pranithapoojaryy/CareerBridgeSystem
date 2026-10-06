import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/aptitude_module.dart';
import '../domain/aptitude_question.dart';
import '../domain/aptitude_test.dart';
import '../domain/test_assignment.dart';
import '../domain/test_attempt.dart';
import '../../../core/utils/logger_service.dart';

class AptitudeRepository {
  final SupabaseClient _supabase;

  AptitudeRepository(this._supabase);

  // ==================== MODULES ====================

  Future<List<AptitudeModule>> getModules() async {
    try {
      final response = await _supabase
          .from('aptitude_modules')
          .select()
          .eq('is_active', true)
          .order('display_order');

      return (response as List)
          .map((json) => AptitudeModule.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch aptitude modules: $e');
    }
  }

  Future<AptitudeModule> getModuleById(String moduleId) async {
    try {
      final response = await _supabase
          .from('aptitude_modules')
          .select()
          .eq('id', moduleId)
          .single();

      return AptitudeModule.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch module: $e');
    }
  }

  // ==================== TESTS ====================

  Future<List<AptitudeTest>> getPracticeTests(String moduleId) async {
    try {
      final response = await _supabase
          .from('aptitude_tests')
          .select()
          .eq('module_id', moduleId)
          .eq('test_type', 'practice')
          .eq('is_active', true);

      return (response as List)
          .map((json) => AptitudeTest.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch practice tests: $e');
    }
  }

  Future<AptitudeTest> getTestById(String testId) async {
    try {
      final response = await _supabase
          .from('aptitude_tests')
          .select()
          .eq('id', testId)
          .single();

      return AptitudeTest.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch test: $e');
    }
  }

  // ==================== ASSIGNMENTS ====================

  Future<List<TestAssignment>> getMyAssignments(String userId) async {
    try {
      // 1. Get student profile with IDs (profiles table doesn't have department)
      final studentProfile = await _supabase
          .from('student_profiles')
          .select('department_id, batch_id')
          .eq('id', userId)
          .maybeSingle();

      // Build OR conditions dynamically
      final List<String> orConditions = [
        'assigned_to_user.eq.$userId',
        'assignment_type.eq.all_students,assignment_type.eq.all',
      ];

      if (studentProfile != null) {
        // Match Department ID
        if (studentProfile['department_id'] != null) {
          orConditions.add(
            'assigned_to_department.eq.${studentProfile['department_id']}',
          );
        }

        // Match Batch ID
        if (studentProfile['batch_id'] != null) {
          orConditions.add(
            'assigned_to_batch.eq.${studentProfile['batch_id']}',
          );
        }
      }

      // Get assignments
      final response = await _supabase
          .from('test_assignments')
          .select('''
            *,
            aptitude_tests:test_id (
              title,
              description,
              duration_minutes,
              total_questions,
              is_active
            )
          ''')
          .or(orConditions.join(','));

      // 2. Fetch attempts for this student
      final myAttemptsResponse = await _supabase
          .from('aptitude_attempts')
          .select('assignment_id, score, percentage, status')
          .eq('student_id', userId);

      LoggerService.debug(
        'Fetched ${myAttemptsResponse.length} attempts for user $userId',
      );
      if (myAttemptsResponse.isNotEmpty) {
        LoggerService.debug('First attempt sample: ${myAttemptsResponse.first}');
      }

      final myAttempts = (myAttemptsResponse as List)
          .fold<Map<String, Map<String, dynamic>>>({}, (map, attempt) {
            if (attempt['assignment_id'] != null) {
              map[attempt['assignment_id'] as String] = attempt;
            }
            return map;
          });

      final assignments = (response as List).map((json) {
        final testData = json['aptitude_tests'];
        final assignmentId = json['id'] as String;
        final attempt = myAttempts[assignmentId];

        if (attempt != null) {
          LoggerService.debug('Found attempt for assignment $assignmentId: $attempt');
        }

        return TestAssignment.fromJson({
          ...json,
          'test_title': testData?['title'],
          'test_description': testData?['description'],
          'duration_minutes': testData?['duration_minutes'],
          'total_questions': testData?['total_questions'],
          'is_attempted': attempt != null,
          'my_score': attempt?['score'],
          'my_status': attempt?['status'],
        });
      }).toList();

      return assignments;
    } catch (e) {
      LoggerService.error('Error fetching assignments', e);
      throw Exception('Failed to fetch assignments: $e');
    }
  }

  Future<TestAssignment> getAssignmentById(String assignmentId) async {
    try {
      final response = await _supabase
          .from('test_assignments')
          .select('''
            *,
            aptitude_tests:test_id (
              title,
              description,
              duration_minutes,
              total_questions
            )
          ''')
          .eq('id', assignmentId)
          .single();

      final testData = response['aptitude_tests'];
      return TestAssignment.fromJson({
        ...response,
        'test_title': testData?['title'],
        'test_description': testData?['description'],
        'duration_minutes': testData?['duration_minutes'],
        'total_questions': testData?['total_questions'],
      });
    } catch (e) {
      throw Exception('Failed to fetch assignment: $e');
    }
  }

  // ==================== TEST ATTEMPTS ====================

  Future<Map<String, dynamic>> startTest({
    required String testId,
    required String testType,
    String? assignmentId,
  }) async {
    try {
      final body = {'test_id': testId, 'test_type': testType};

      if (assignmentId != null) {
        body['assignment_id'] = assignmentId;
      }

      final response = await _supabase.functions.invoke(
        'start-test',
        body: body,
      );

      if (response.status != 200) {
        final error = response.data['error'] ?? 'Failed to start test';
        final details = response.data['details'] ?? '';
        throw Exception('$error $details'.trim());
      }

      final data = response.data;
      final attemptData = data['attempt'];
      final questionsData = data['questions'] as List;

      final questions = questionsData
          .map((json) => AptitudeQuestion.fromJson(json))
          .toList();

      final attempt = TestAttempt(
        id: attemptData['id'],
        testId: attemptData['test_id'],
        studentId: _supabase.auth.currentUser!.id,
        testType: testType,
        moduleName: attemptData['test_title'],
        difficulty: attemptData['difficulty'] ?? 'medium',
        attemptNumber: attemptData['attempt_number'] ?? 1,
        startTime: DateTime.parse(attemptData['start_time']),
        durationSeconds: (attemptData['duration_minutes'] as int? ?? 30) * 60,
        questions: questions,
        totalQuestions: attemptData['total_questions'],
        status: attemptData['status'] ?? 'in_progress',
      );

      return {
        'attempt': attempt,
        'settings': data['settings'],
        'duration_minutes': attemptData['duration_minutes'],
      };
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map) {
        final error = details['error'] ?? 'Function Error';
        final description = details['details'] ?? e.reasonPhrase;
        throw Exception('$error: $description');
      }
      throw Exception('Function failed: ${e.reasonPhrase}');
    } catch (e) {
      throw Exception('Failed to start test: $e');
    }
  }

  Future<TestAttempt> getAttemptById(String attemptId) async {
    try {
      final response = await _supabase
          .from('aptitude_attempts')
          .select()
          .eq('id', attemptId)
          .single();

      final questionIds = (response['questions'] as List).cast<String>();
      final questions = await _getQuestionsById(questionIds);

      return TestAttempt.fromJson(response, questions);
    } catch (e) {
      throw Exception('Failed to fetch attempt: $e');
    }
  }

  Future<List<AptitudeQuestion>> _getQuestionsById(
    List<String> questionIds,
  ) async {
    if (questionIds.isEmpty) return [];

    final response = await _supabase
        .from('aptitude_questions')
        .select()
        .inFilter('id', questionIds);

    final questionsMap = {
      for (var json in response as List)
        json['id']: AptitudeQuestion.fromJson(json),
    };

    // Preserve order
    return questionIds
        .map((id) => questionsMap[id])
        .where((q) => q != null)
        .cast<AptitudeQuestion>()
        .toList();
  }

  Future<void> saveAnswer({
    required String attemptId,
    required String questionId,
    required int selectedOption,
  }) async {
    try {
      // Get current attempt
      final attempt = await _supabase
          .from('aptitude_attempts')
          .select('answers, attempted_questions')
          .eq('id', attemptId)
          .single();

      final answers = Map<String, dynamic>.from(attempt['answers'] ?? {});
      final wasAnswered = answers.containsKey(questionId);

      answers[questionId] = selectedOption;

      await _supabase
          .from('aptitude_attempts')
          .update({
            'answers': answers,
            'attempted_questions': wasAnswered
                ? attempt['attempted_questions']
                : (attempt['attempted_questions'] as int) + 1,
          })
          .eq('id', attemptId);
    } catch (e) {
      throw Exception('Failed to save answer: $e');
    }
  }

  Future<Map<String, dynamic>> submitTest({
    required String attemptId,
    required Map<String, int> answers,
    Map<String, int>? timePerQuestion,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'submit-test',
        body: {
          'attempt_id': attemptId,
          'answers': answers,
          'time_per_question': timePerQuestion,
        },
      );

      if (response.status != 200) {
        throw Exception(response.data['error'] ?? 'Failed to submit test');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to submit test: $e');
    }
  }

  Future<List<TestAttempt>> getMyAttempts({
    String? testType,
    int limit = 10,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = testType != null
          ? await _supabase
                .from('aptitude_attempts')
                .select()
                .eq('student_id', userId)
                .eq('test_type', testType)
                .order('created_at', ascending: false)
                .limit(limit)
          : await _supabase
                .from('aptitude_attempts')
                .select()
                .eq('student_id', userId)
                .order('created_at', ascending: false)
                .limit(limit);

      final attempts = <TestAttempt>[];
      for (final json in response as List) {
        final questionIds = (json['questions'] as List).cast<String>();
        final questions = await _getQuestionsById(questionIds);
        attempts.add(TestAttempt.fromJson(json, questions));
      }

      return attempts;
    } catch (e) {
      throw Exception('Failed to fetch attempts: $e');
    }
  }

  Future<int> getAttemptCount({
    required String testId,
    String? assignmentId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      var query = _supabase
          .from('aptitude_attempts')
          .select()
          .eq('test_id', testId)
          .eq('student_id', userId);

      if (assignmentId != null) {
        query = query.eq('assignment_id', assignmentId);
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get attempt count: $e');
    }
  }

  // ==================== ANALYTICS ====================

  Future<Map<String, dynamic>> getPerformanceStats(String userId) async {
    try {
      final response = await _supabase
          .from('aptitude_attempts')
          .select(
            'test_type, status, percentage, correct_answers, total_questions',
          )
          .eq('student_id', userId)
          .eq('status', 'completed');

      final attempts = response as List;

      if (attempts.isEmpty) {
        return {
          'total_tests': 0,
          'average_score': 0.0,
          'practice_count': 0,
          'assignment_count': 0,
          'highest_score': 0.0,
        };
      }

      final practiceAttempts = attempts
          .where((a) => a['test_type'] == 'practice')
          .toList();
      final assignmentAttempts = attempts
          .where((a) => a['test_type'] == 'assignment')
          .toList();

      final avgScore =
          attempts
              .map((a) => (a['percentage'] as num?)?.toDouble() ?? 0.0)
              .reduce((a, b) => a + b) /
          attempts.length;

      final highestScore = attempts
          .map((a) => (a['percentage'] as num?)?.toDouble() ?? 0.0)
          .reduce((a, b) => a > b ? a : b);

      return {
        'total_tests': attempts.length,
        'average_score': avgScore,
        'practice_count': practiceAttempts.length,
        'assignment_count': assignmentAttempts.length,
        'highest_score': highestScore,
      };
    } catch (e) {
      throw Exception('Failed to fetch performance stats: $e');
    }
  }
}
