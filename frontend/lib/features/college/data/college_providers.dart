import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'college_repository.dart';
import '../../recruiter/data/recruiter_repository.dart';
import '../../../../core/utils/logger_service.dart';

// Repository Provider
final collegeRepositoryProvider = Provider<CollegeRepository>((ref) {
  return CollegeRepository(Supabase.instance.client);
});

// Current College Provider
final currentCollegeProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final repository = ref.watch(collegeRepositoryProvider);
  final currentUser = Supabase.instance.client.auth.currentUser;

  LoggerService.debug('CurrentCollegeProvider - User: ${currentUser?.id}');

  if (currentUser == null) {
    LoggerService.debug('CurrentCollegeProvider - No user, returning null');
    return null;
  }

  final result = await repository.getOrganizationByUserId(currentUser.id);
  LoggerService.info(
    'CurrentCollegeProvider - College: ${result?['id']} (${result?['name']})',
  );

  return result;
});

// =====================================================
// EVENTS PROVIDERS
// =====================================================

class CollegeEventFilter {
  final String? eventType;
  final String? status;

  const CollegeEventFilter({this.eventType, this.status});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CollegeEventFilter &&
        other.eventType == eventType &&
        other.status == status;
  }

  @override
  int get hashCode => eventType.hashCode ^ status.hashCode;
}

final eventsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, CollegeEventFilter>((
      ref,
      filter,
    ) async {
      final repository = ref.watch(collegeRepositoryProvider);
      final college = await ref.watch(currentCollegeProvider.future);

      if (college == null) return [];

      return await repository.getEvents(
        collegeId: college['id'],
        eventType: filter.eventType,
        status: filter.status,
      );
    });

final eventStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(collegeRepositoryProvider);
  final college = await ref.watch(currentCollegeProvider.future);

  if (college == null) return {};

  return await repository.getEventStats(college['id']);
});

// =====================================================
// ASSESSMENTS PROVIDERS
// =====================================================

final assessmentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, String?>>((
      ref,
      filters,
    ) async {
      final repository = ref.watch(collegeRepositoryProvider);
      // Remove blocking dependency on currentCollegeProvider since repository fetches by user ID now
      // final college = await ref.watch(currentCollegeProvider.future);

      return await repository.getAssessments(
        collegeId: null, // Repository ignores this now or handles it internally
        category: filters['category'],
        isActive: filters['isActive'] == 'true',
      );
    });

final assessmentStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repository = ref.watch(collegeRepositoryProvider);
  // Decouple stats from college ID to prevent buffering, matching Question Bank logic
  // final college = await ref.watch(currentCollegeProvider.future);

  return await repository.getAssessmentStats(
    '',
  ); // Returns default or user-bound stats
});

final skillsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(collegeRepositoryProvider);
  return await repository.getSkills();
});

// =====================================================
// STUDENTS PROVIDERS
// =====================================================

final studentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      collegeId,
    ) async {
      LoggerService.debug('StudentsProvider called for college: $collegeId');

      final repository = ref.watch(collegeRepositoryProvider);

      final result = await repository.getStudents(collegeId: collegeId);

      LoggerService.debug('StudentsProvider - Returning ${result.length} students');
      return result;
    });

final studentStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(collegeRepositoryProvider);
  final college = await ref.watch(currentCollegeProvider.future);

  if (college == null) return {};

  return await repository.getStudentStats(college['id']);
});

// =====================================================
// LEARNING PATHS PROVIDERS
// =====================================================

final learningPathsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, String?>>((
      ref,
      filters,
    ) async {
      final repository = ref.watch(collegeRepositoryProvider);
      final college = await ref.watch(currentCollegeProvider.future);

      if (college == null) return [];

      return await repository.getLearningPaths(
        collegeId: college['id'],
        category: filters['category'],
        isPublished: filters['isPublished'] == 'true',
      );
    });

// =====================================================
// ANNOUNCEMENTS PROVIDERS
// =====================================================

final announcementsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, String?>>((
      ref,
      filters,
    ) async {
      final repository = ref.watch(collegeRepositoryProvider);
      final college = await ref.watch(currentCollegeProvider.future);

      if (college == null) return [];

      return await repository.getAnnouncements(
        collegeId: college['id'],
        type: filters['type'],
        isPublished: filters['isPublished'] == 'true',
      );
    });

// =====================================================
// ANALYTICS PROVIDERS
// =====================================================

final dashboardStatsV2Provider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repository = ref.watch(collegeRepositoryProvider);
  final college = await ref.watch(currentCollegeProvider.future);

  if (college == null) return {};

  return await repository.getCollegeDashboardStatsV2(college['id']);
});

// =====================================================
// DEPARTMENTS & PROGRAMS PROVIDERS
// =====================================================

final departmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(collegeRepositoryProvider);
  final college = await ref.watch(currentCollegeProvider.future);

  if (college == null) return [];

  return await repository.getDepartments(college['id']);
});

final programsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      departmentId,
    ) async {
      final repository = ref.watch(collegeRepositoryProvider);
      return await repository.getPrograms(departmentId);
    });

final batchesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      programId,
    ) async {
      final repository = ref.watch(collegeRepositoryProvider);
      return await repository.getBatches(programId);
    });

// =====================================================
// NOTIFIERS FOR MUTATIONS
// =====================================================

class EventsNotifier extends Notifier<AsyncValue<List<Map<String, dynamic>>>> {
  late CollegeRepository _repository;

  @override
  AsyncValue<List<Map<String, dynamic>>> build() {
    _repository = ref.watch(collegeRepositoryProvider);
    return const AsyncValue.loading();
  }

  Future<void> createEvent(Map<String, dynamic> eventData) async {
    try {
      await _repository.createEvent(eventData);
      // Refresh the events list
      ref.invalidate(eventsProvider);
      ref.invalidate(eventStatsProvider);
      // Also invalidate recruiter-specific providers
      ref.invalidate(activeRecruiterEventsProvider);
      ref.invalidate(allRecruiterEventsProvider);
      ref.invalidate(recruiterDashboardStatsProvider);
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      await _repository.updateEvent(eventId, updates);
      ref.invalidate(eventsProvider);
      ref.invalidate(eventStatsProvider);
      ref.invalidate(activeRecruiterEventsProvider);
      ref.invalidate(allRecruiterEventsProvider);
      ref.invalidate(recruiterDashboardStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _repository.deleteEvent(eventId);
      ref.invalidate(eventsProvider);
      ref.invalidate(eventStatsProvider);
      ref.invalidate(activeRecruiterEventsProvider);
      ref.invalidate(allRecruiterEventsProvider);
      ref.invalidate(recruiterDashboardStatsProvider);
    } catch (e) {
      rethrow;
    }
  }
}

final eventsNotifierProvider =
    NotifierProvider<EventsNotifier, AsyncValue<List<Map<String, dynamic>>>>(
      () {
        return EventsNotifier();
      },
    );

class AssessmentsNotifier
    extends Notifier<AsyncValue<List<Map<String, dynamic>>>> {
  late CollegeRepository _repository;

  @override
  AsyncValue<List<Map<String, dynamic>>> build() {
    _repository = ref.watch(collegeRepositoryProvider);
    return const AsyncValue.loading();
  }

  Future<void> createAssessment(Map<String, dynamic> assessmentData) async {
    try {
      await _repository.createAssessment(assessmentData);
      ref.invalidate(assessmentsProvider);
      ref.invalidate(assessmentStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAssessment(
    String assessmentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _repository.updateAssessment(assessmentId, updates);
      ref.invalidate(assessmentsProvider);
      ref.invalidate(assessmentStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _repository.deleteAssessment(assessmentId);
      ref.invalidate(assessmentsProvider);
      ref.invalidate(assessmentStatsProvider);
    } catch (e) {
      rethrow;
    }
  }
}

final assessmentsNotifierProvider =
    NotifierProvider<
      AssessmentsNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >(() {
      return AssessmentsNotifier();
    });

class StudentsNotifier
    extends Notifier<AsyncValue<List<Map<String, dynamic>>>> {
  late CollegeRepository _repository;

  @override
  AsyncValue<List<Map<String, dynamic>>> build() {
    _repository = ref.watch(collegeRepositoryProvider);
    return const AsyncValue.loading();
  }

  Future<void> updateStudentStatus(
    String studentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _repository.updateStudentStatus(studentId, updates);
      ref.invalidate(studentsProvider);
      ref.invalidate(studentStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendBulkMessage(List<String> studentIds, String message) async {
    try {
      await _repository.sendBulkMessage(studentIds, message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      await _repository.deleteStudent(studentId);

      // Explicitly invalidate for the current college to force refresh
      final college = await ref.read(currentCollegeProvider.future);
      if (college != null) {
        final collegeId = college['id'];
        ref.invalidate(studentsProvider(collegeId));
      } else {
        // Fallback to family invalidation
        ref.invalidate(studentsProvider);
      }

      ref.invalidate(studentStatsProvider);
    } catch (e) {
      rethrow;
    }
  }
}

final studentsNotifierProvider =
    NotifierProvider<StudentsNotifier, AsyncValue<List<Map<String, dynamic>>>>(
      () {
        return StudentsNotifier();
      },
    );

class AnnouncementsNotifier
    extends Notifier<AsyncValue<List<Map<String, dynamic>>>> {
  late CollegeRepository _repository;

  @override
  AsyncValue<List<Map<String, dynamic>>> build() {
    _repository = ref.watch(collegeRepositoryProvider);
    return const AsyncValue.loading();
  }

  Future<void> createAnnouncement(Map<String, dynamic> announcementData) async {
    try {
      await _repository.createAnnouncement(announcementData);
      ref.invalidate(announcementsProvider);
    } catch (e) {
      rethrow;
    }
  }
}

final announcementsNotifierProvider =
    NotifierProvider<
      AnnouncementsNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >(() {
      return AnnouncementsNotifier();
    });

// =====================================================
// DASHBOARD NAVIGATION PROVIDER
// =====================================================
class DashboardIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final collegeDashboardIndexProvider =
    NotifierProvider<DashboardIndexNotifier, int>(() {
      return DashboardIndexNotifier();
    });
