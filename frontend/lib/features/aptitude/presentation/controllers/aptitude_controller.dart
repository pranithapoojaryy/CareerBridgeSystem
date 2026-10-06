import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/aptitude_repository.dart';
import '../../domain/aptitude_module.dart';
import '../../domain/test_assignment.dart';

import '../../domain/aptitude_test.dart';
import '../../../student/data/learning_repository.dart';

final aptitudeRepositoryProvider = Provider<AptitudeRepository>((ref) {
  return AptitudeRepository(Supabase.instance.client);
});

final practiceTestsProvider = FutureProvider.family
    .autoDispose<List<AptitudeTest>, String>((ref, moduleId) {
      return ref.watch(aptitudeRepositoryProvider).getPracticeTests(moduleId);
    });

final aptitudeModulesProvider =
    FutureProvider.autoDispose<List<AptitudeModule>>((ref) {
      return ref.watch(aptitudeRepositoryProvider).getModules();
    });

final myAssignmentsProvider = FutureProvider.autoDispose<List<TestAssignment>>((
  ref,
) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return ref.watch(aptitudeRepositoryProvider).getMyAssignments(userId);
});

final aptitudeStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return {};
  return ref.watch(aptitudeRepositoryProvider).getPerformanceStats(userId);
});

final pendingCourseAssessmentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      return SupabaseLearningRepository().getPendingAssessmentsForStudent();
    });
