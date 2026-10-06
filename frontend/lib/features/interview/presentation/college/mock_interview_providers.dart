import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/mock_interview_models.dart';
import '../../domain/interview_models.dart'; // For InterviewQuestion

// 1. Fetch all Mock Definitions (College View)
final mockDefinitionsProvider = FutureProvider.autoDispose<List<MockDefinition>>(
  (ref) async {
    final supabase = Supabase.instance.client;

    // TODO: Filter by current college_id if using strict multi-tenancy.
    // For now, assuming user is auth'd as college and RLS filters or we see all
    final response = await supabase
        .from('mock_definitions')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => MockDefinition.fromJson(e)).toList();
  },
);

// 2. Fetch Questions for a specific Mock
final mockQuestionsProvider =
    FutureProvider.family<List<InterviewQuestion>, String>((ref, mockId) async {
      final supabase = Supabase.instance.client;

      // Join mock_questions_junction with interview_questions
      final response = await supabase
          .from('mock_questions_junction')
          .select('*, interview_questions(*)')
          .eq('mock_id', mockId)
          .order('order_index');

      // Extract nested question data
      return (response as List)
          .map((e) {
            if (e['interview_questions'] == null) return null;
            return InterviewQuestion.fromJson(e['interview_questions']);
          })
          .whereType<InterviewQuestion>()
          .toList();
    });

// 2.b Fetch Single Mock Definition
final mockDetailProvider = FutureProvider.family<MockDefinition, String>((
  ref,
  mockId,
) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('mock_definitions')
      .select()
      .eq('id', mockId)
      .single();
  return MockDefinition.fromJson(response);
});

// 5. Mock Attempt Management (Grading)
final mockSubmissionsProvider =
    FutureProvider.family<List<MockAttempt>, String>((ref, mockId) async {
      final repo = ref.watch(mockRepositoryProvider);
      return repo.getSubmissionsForMock(mockId);
    });

// 6. Fetch ALL Mock Submissions (Across all mocks)
final allMockSubmissionsProvider = FutureProvider.autoDispose<List<MockAttempt>>((
  ref,
) async {
  final repo = ref.watch(mockRepositoryProvider);
  return repo.getAllSubmissions();
});

// 3. Mock Management Repository
class MockRepository {
  final SupabaseClient _client;
  MockRepository(this._client);

  Future<String> createMock({
    required String title,
    required String description,
    required int timeLimit,
    required List<String> questionIds,
  }) async {
    // 1. Create Definition
    final mockRes = await _client
        .from('mock_definitions')
        .insert({
          'title': title,
          'description': description,
          'time_limit_minutes': timeLimit,
          'college_id': _client.auth.currentUser!.id, // Owner
        })
        .select()
        .single();

    final mockId = mockRes['id'];

    // 2. Link Questions (Batch Insert)
    if (questionIds.isNotEmpty) {
      final List<Map<String, dynamic>> junctionRows = [];
      for (int i = 0; i < questionIds.length; i++) {
        junctionRows.add({
          'mock_id': mockId,
          'question_id': questionIds[i],
          'order_index': i,
        });
      }
      await _client.from('mock_questions_junction').insert(junctionRows);
    }

    return mockId;
  }

  Future<void> deleteMock(String mockId) async {
    await _client.from('mock_definitions').delete().eq('id', mockId);
  }

  // Fetch submissions for a specific mock
  Future<List<MockAttempt>> getSubmissionsForMock(String mockId) async {
    final response = await _client
        .from('mock_attempts')
        .select('*, profiles(full_name, email)') // Join profile info
        .eq('mock_id', mockId)
        .order('submitted_at', ascending: false);

    return (response as List).map((e) {
      final data = Map<String, dynamic>.from(e);
      if (e['profiles'] != null) {
        data['student_name'] = e['profiles']['full_name'];
      }
      return MockAttempt.fromJson(data);
    }).toList();
  }

  // Fetch ALL submissions across all mocks
  Future<List<MockAttempt>> getAllSubmissions() async {
    final response = await _client
        .from('mock_attempts')
        .select('*, profiles(full_name, email), mock_definitions(title)')
        .not('video_path', 'is', null) // Only show those with videos for the gallery
        .order('submitted_at', ascending: false);

    return (response as List).map((e) {
      final data = Map<String, dynamic>.from(e);
      if (e['profiles'] != null) {
        data['student_name'] = e['profiles']['full_name'];
      }
      if (e['mock_definitions'] != null) {
        data['mock_title'] = e['mock_definitions']['title'];
      }
      return MockAttempt.fromJson(data);
    }).toList();
  }

  // Update Score and Feedback
  Future<void> updateMockGrade(
    String attemptId,
    int score,
    String feedback,
  ) async {
    await _client
        .from('mock_attempts')
        .update({
          'total_score': score,
          'faculty_feedback': feedback,
          'status': 'graded',
          'graded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', attemptId);
  }

  // Fetch detailed answers (questions + code + timestamps) for a specific attempt
  Future<List<InterviewAttempt>> getMockAnswers(String mockAttemptId) async {
    final response = await _client
        .from('student_interviews')
        .select('*, interview_questions(*)')
        .eq('mock_attempt_id', mockAttemptId)
        .order('answer_start_offset', ascending: true);

    return (response as List).map((e) => InterviewAttempt.fromJson(e)).toList();
  }
}

final mockRepositoryProvider = Provider(
  (ref) => MockRepository(Supabase.instance.client),
);
