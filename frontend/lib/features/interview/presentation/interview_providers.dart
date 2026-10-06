import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/interview_repository.dart';
import '../domain/interview_models.dart';

final interviewRepositoryProvider = Provider<InterviewRepository>((ref) {
  return InterviewRepository(Supabase.instance.client);
});

// Categories
final interviewCategoriesProvider = FutureProvider<List<InterviewCategory>>((
  ref,
) async {
  final repo = ref.watch(interviewRepositoryProvider);
  return repo.getCategories();
});

// Questions (Family provider to pass category ID)
final interviewQuestionsProvider =
    FutureProvider.family<List<InterviewQuestion>, String>((
      ref,
      categoryId,
    ) async {
      final repo = ref.watch(interviewRepositoryProvider);
      return repo.getQuestions(categoryId);
    });

// Learning Content (Family provider)
final learningContentProvider =
    FutureProvider.family<List<LearningContent>, String>((
      ref,
      categoryId,
    ) async {
      final repo = ref.watch(interviewRepositoryProvider);
      return repo.getLearningContent(categoryId);
    });

// Student History
final interviewHistoryProvider = FutureProvider<List<InterviewAttempt>>((
  ref,
) async {
  final repo = ref.watch(interviewRepositoryProvider);
  return repo.getHistory();
});
