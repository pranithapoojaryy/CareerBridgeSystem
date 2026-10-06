import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/image_service.dart';
import 'certification_repository.dart';

// Repository Provider
final certificationRepositoryProvider = Provider<CertificationRepository>((
  ref,
) {
  return CertificationRepository(Supabase.instance.client, ImageService());
});

// Current Student Provider
final currentStudentProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

// Certification Providers List
final certificationProvidersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      final repository = ref.watch(certificationRepositoryProvider);

      try {
        final providers = await repository.getCertificationProviders();

        // If no providers found, return mock data for testing
        if (providers.isEmpty) {
          return _getMockProviders();
        }

        return providers;
      } catch (e) {
        // If database tables don't exist, return mock data
        print('Error loading providers, using mock data: $e');
        return _getMockProviders();
      }
    });

// Mock providers for testing when database is not set up
List<Map<String, dynamic>> _getMockProviders() {
  return [
    {
      'id': 'mock-nptel',
      'name': 'NPTEL',
      'short_code': 'NPTEL',
      'trust_score': 95,
      'logo_url': null,
      'validation_method': 'api',
    },
    {
      'id': 'mock-coursera',
      'name': 'Coursera',
      'short_code': 'COURSERA',
      'trust_score': 90,
      'logo_url': null,
      'validation_method': 'api',
    },
    {
      'id': 'mock-udemy',
      'name': 'Udemy',
      'short_code': 'UDEMY',
      'trust_score': 85,
      'logo_url': null,
      'validation_method': 'pattern',
    },
    {
      'id': 'mock-aws',
      'name': 'AWS',
      'short_code': 'AWS',
      'trust_score': 95,
      'logo_url': null,
      'validation_method': 'api',
    },
    {
      'id': 'mock-gcp',
      'name': 'Google Cloud',
      'short_code': 'GCP',
      'trust_score': 95,
      'logo_url': null,
      'validation_method': 'api',
    },
  ];
}

// Student Certifications
final certificationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(certificationRepositoryProvider);
  final studentId = ref.watch(currentStudentProvider);

  if (studentId == null) return [];

  try {
    return await repository.getStudentCertifications(studentId);
  } catch (e) {
    // If database tables don't exist, return empty list
    print('Error loading certifications, using empty list: $e');
    return [];
  }
});

// Student Skills from Certifications
final studentSkillsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(certificationRepositoryProvider);
  final studentId = ref.watch(currentStudentProvider);

  if (studentId == null) return [];

  try {
    return await repository.getStudentSkills(studentId);
  } catch (e) {
    // If database tables don't exist, return empty list
    print('Error loading skills, using empty list: $e');
    return [];
  }
});

// Certification Statistics
final certificationStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repository = ref.watch(certificationRepositoryProvider);
  final studentId = ref.watch(currentStudentProvider);

  if (studentId == null) return {};

  return await repository.getCertificationStats(studentId);
});

// Skills Database for Search/Autocomplete
final skillsDatabaseProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, String?>>((
      ref,
      params,
    ) async {
      final repository = ref.watch(certificationRepositoryProvider);
      return await repository.getSkillsDatabase(
        category: params['category'],
        search: params['search'],
      );
    });

// Validation History
final validationHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(certificationRepositoryProvider);
  final studentId = ref.watch(currentStudentProvider);

  if (studentId == null) return [];

  return await repository.getValidationHistory(studentId);
});

// Search Certifications
final searchCertificationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      query,
    ) async {
      final repository = ref.watch(certificationRepositoryProvider);
      final studentId = ref.watch(currentStudentProvider);

      if (studentId == null || query.isEmpty) return [];

      return await repository.searchCertifications(studentId, query);
    });

// Notifier for Certification Management
class CertificationNotifier
    extends Notifier<AsyncValue<List<Map<String, dynamic>>>> {
  late CertificationRepository _repository;

  @override
  AsyncValue<List<Map<String, dynamic>>> build() {
    _repository = ref.watch(certificationRepositoryProvider);
    return const AsyncValue.loading();
  }

  Future<void> addCertification({
    required String certificateName,
    String? providerId,
    String? issuerName,
    String? certificateId,
    String? certificateUrl,
    DateTime? issueDate,
    DateTime? expiryDate,
    PlatformFile? file, // Changed from String? filePath
  }) async {
    final studentId = ref.read(currentStudentProvider);
    if (studentId == null) throw Exception('No authenticated user');

    try {
      await _repository.addCertification(
        studentId: studentId,
        certificateName: certificateName,
        providerId: providerId,
        issuerName: issuerName,
        certificateId: certificateId,
        certificateUrl: certificateUrl,
        issueDate: issueDate,
        expiryDate: expiryDate,
        file: file, // Changed from filePath
      );

      // Refresh all related providers
      ref.invalidate(certificationsProvider);
      ref.invalidate(studentSkillsProvider);
      ref.invalidate(certificationStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> validateCertification(String certificationId) async {
    try {
      await _repository.validateCertification(certificationId);

      // Refresh providers
      ref.invalidate(certificationsProvider);
      ref.invalidate(studentSkillsProvider);
      ref.invalidate(certificationStatsProvider);
      ref.invalidate(validationHistoryProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCertification(String certificationId) async {
    try {
      await _repository.deleteCertification(certificationId);

      // Refresh providers
      ref.invalidate(certificationsProvider);
      ref.invalidate(studentSkillsProvider);
      ref.invalidate(certificationStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCertification(
    String certificationId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _repository.updateCertification(certificationId, updates);

      // Refresh providers
      ref.invalidate(certificationsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> bulkValidate(List<String> certificationIds) async {
    try {
      await _repository.bulkValidateCertifications(certificationIds);

      // Refresh providers
      ref.invalidate(certificationsProvider);
      ref.invalidate(studentSkillsProvider);
      ref.invalidate(certificationStatsProvider);
      ref.invalidate(validationHistoryProvider);
    } catch (e) {
      rethrow;
    }
  }
}

final certificationNotifierProvider =
    NotifierProvider<
      CertificationNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >(() {
      return CertificationNotifier();
    });

// Skills Analytics Provider
final skillsAnalyticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final skills = await ref.watch(studentSkillsProvider.future);
  final certifications = await ref.watch(certificationsProvider.future);

  // Calculate analytics
  final skillsByCategory = <String, List<Map<String, dynamic>>>{};
  final skillsByLevel = <String, int>{};
  final monthlyProgress = <String, int>{};

  for (final skill in skills) {
    final category = skill['skill_category'] as String? ?? 'other';
    final level = skill['proficiency_level'] as String? ?? 'beginner';

    skillsByCategory.putIfAbsent(category, () => []).add(skill);
    skillsByLevel[level] = (skillsByLevel[level] ?? 0) + 1;
  }

  // Calculate monthly progress from certifications
  for (final cert in certifications) {
    if (cert['validated_at'] != null) {
      final date = DateTime.parse(cert['validated_at']);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthlyProgress[monthKey] =
          (monthlyProgress[monthKey] ?? 0) +
          (cert['skill_points_awarded'] as int? ?? 0);
    }
  }

  return {
    'skills_by_category': skillsByCategory,
    'skills_by_level': skillsByLevel,
    'monthly_progress': monthlyProgress,
    'total_skills': skills.length,
    'total_points': skills.fold<int>(
      0,
      (sum, skill) => sum + (skill['total_points'] as int? ?? 0),
    ),
    'average_skill_level': _calculateAverageSkillLevel(skills),
    'skill_diversity_score':
        skillsByCategory.length * 10, // Simple diversity metric
    'certification_success_rate': certifications.isNotEmpty
        ? (certifications
                      .where((c) => c['validation_status'] == 'verified')
                      .length /
                  certifications.length *
                  100)
              .round()
        : 0,
  };
});

double _calculateAverageSkillLevel(List<Map<String, dynamic>> skills) {
  if (skills.isEmpty) return 0.0;

  final levelValues = {
    'beginner': 1,
    'intermediate': 2,
    'advanced': 3,
    'expert': 4,
  };

  final totalValue = skills.fold<int>(0, (sum, skill) {
    final level = skill['proficiency_level'] as String? ?? 'beginner';
    return sum + (levelValues[level] ?? 1);
  });

  return totalValue / skills.length;
}

// Provider for trending skills (market demand based)
final trendingSkillsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(certificationRepositoryProvider);
  return await repository.getSkillsDatabase();
});

// Provider for skill recommendations based on current skills
final skillRecommendationsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final currentSkills = await ref.watch(studentSkillsProvider.future);
    final allSkills = await ref.watch(trendingSkillsProvider.future);

    // Get current skill categories
    final currentCategories = currentSkills
        .map((s) => s['skill_category'] as String?)
        .where((c) => c != null)
        .toSet();

    // Get current skill names
    final currentSkillNames = currentSkills
        .map((s) => s['skill_name'] as String?)
        .where((n) => n != null)
        .toSet();

    // Recommend skills from same categories or high market demand
    final recommendations = allSkills.where((skill) {
      final skillName = skill['name'] as String?;
      final category = skill['category'] as String?;
      final marketDemand = skill['market_demand'] as int? ?? 0;

      // Don't recommend skills already acquired
      if (currentSkillNames.contains(skillName)) return false;

      // Recommend if same category or high market demand
      return currentCategories.contains(category) || marketDemand >= 80;
    }).toList();

    // Sort by market demand
    recommendations.sort(
      (a, b) => (b['market_demand'] as int? ?? 0).compareTo(
        a['market_demand'] as int? ?? 0,
      ),
    );

    return recommendations.take(10).toList();
  },
);
