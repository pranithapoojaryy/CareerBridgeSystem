import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_stats.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(Supabase.instance.client);
});

final dashboardStatsProvider =
    AsyncNotifierProvider<DashboardController, DashboardStats>(() {
      return DashboardController();
    });

class DashboardController extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return DashboardStats.empty();

    return ref.read(dashboardRepositoryProvider).getStudentStats(userId);
  }

  Future<void> refreshStats() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return DashboardStats.empty();
      return ref.read(dashboardRepositoryProvider).getStudentStats(userId);
    });
  }
}
