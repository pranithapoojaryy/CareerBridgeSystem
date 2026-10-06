import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/mock_interview_models.dart';

// 1. Fetch Active Mocks (Available for Student)
final availableMocksProvider = FutureProvider.autoDispose<List<MockDefinition>>(
  (ref) async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('mock_definitions')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List).map((e) => MockDefinition.fromJson(e)).toList();
  },
);

// 2. Fetch Student's Past Attempts
final studentMockAttemptsProvider =
    FutureProvider.autoDispose<List<MockAttempt>>((ref) async {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // Join with mock_definitions to get the title
      final response = await supabase
          .from('mock_attempts')
          .select('*, mock_definitions(*)')
          .eq('student_id', userId)
          .order('started_at', ascending: false);

      return (response as List).map((e) => MockAttempt.fromJson(e)).toList();
    });

class StudentMockRepository {
  final SupabaseClient _client;
  StudentMockRepository(this._client);

  // Start a new attempt
  Future<String> startAttempt(String mockId) async {
    final userId = _client.auth.currentUser!.id;

    // Check if already in progress? (Optional, maybe allow retakes)

    final res = await _client
        .from('mock_attempts')
        .insert({
          'student_id': userId,
          'mock_id': mockId,
          'status': 'in_progress',
          'started_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return res['id'];
  }
}

final studentMockRepositoryProvider = Provider(
  (ref) => StudentMockRepository(Supabase.instance.client),
);
