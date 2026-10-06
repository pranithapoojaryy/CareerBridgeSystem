import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/logger_service.dart';

final landingStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase.rpc('get_public_stats');

    if (response is List && response.isNotEmpty) {
      final data = response.first as Map<String, dynamic>;
      LoggerService.debug('landingStatsProvider - Fetched stats successfully');
      return {
        'total_students': data['total_students'] as int? ?? 0,
        'total_colleges': data['total_colleges'] as int? ?? 0,
        'total_recruiters': data['total_recruiters'] as int? ?? 0,
        'total_placements': data['total_placements'] as int? ?? 0,
      };
    }
  } catch (e) {
    LoggerService.error('Error fetching public stats', e);
    // Return zeros if failed, so users know something is wrong
    return {
      'total_students': 0,
      'total_colleges': 0,
      'total_recruiters': 0,
      'total_placements': 0,
    };
  }

  return {
    'total_students': 0,
    'total_colleges': 0,
    'total_recruiters': 0,
    'total_placements': 0,
  };
});

final landingFeedProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final supabase = Supabase.instance.client;

      try {
        final response = await supabase.rpc('get_public_feed');
        if (response is List) {
          LoggerService.debug('landingFeedProvider - Fetched ${response.length} items');
          return List<Map<String, dynamic>>.from(response);
        }
      } catch (e) {
        LoggerService.error('Error fetching public feed', e);
        // Return empty list on error
        return [];
      }

      return [];
    });

final growthStatsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final supabase = Supabase.instance.client;

      try {
        final response = await supabase.rpc('get_platform_growth_stats');
        if (response is List) {
          return List<Map<String, dynamic>>.from(response);
        }
      } catch (e) {
        LoggerService.error('Error fetching growth stats', e);
        return [];
      }

      return [];
    });
