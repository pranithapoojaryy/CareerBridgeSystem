import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'resume_repository.dart';
import 'resume_data_service.dart';

final resumeRepositoryProvider = Provider<ResumeRepository>((ref) {
  return ResumeRepository(Supabase.instance.client);
});

final resumeUrlProvider = FutureProvider<String?>((ref) async {
  final repository = ref.watch(resumeRepositoryProvider);
  return repository.getResumeUrl();
});

final resumeFeedbackProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(resumeRepositoryProvider);
  return repository.getResumeFeedback();
});
final resumeDataServiceProvider = Provider<ResumeDataService>((ref) {
  return ResumeDataService(Supabase.instance.client);
});
