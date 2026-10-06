import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../../../core/utils/logger_service.dart';

class RecruiterProfileRepository {
  final _supabase = Supabase.instance.client;

  /// Fetch recruiter profile with organization data
  Future<Map<String, dynamic>> getRecruiterProfile(String userId) async {
    try {
      // First get the basic profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse == null) {
        throw Exception('Profile not found');
      }

      Map<String, dynamic> enrichedProfile = Map<String, dynamic>.from(
        profileResponse,
      );

      // Get organization info if organization_id exists
      if (profileResponse['organization_id'] != null) {
        try {
          final orgResponse = await _supabase
              .from('organizations')
              .select('''
                id, name, type, logo_url, website, description,
                address, city, state, country, pincode,
                phone, email, established_year, tagline,
                social_links, is_verified, banner_url,
                industry, company_size, specialties, domains, headquarters
              ''')
              .eq('id', profileResponse['organization_id'])
              .maybeSingle();

          if (orgResponse == null) {
            throw Exception('Organization not found');
          }
          enrichedProfile['organization'] = orgResponse;
        } catch (e) {
          // Organization not found, continue without it
          LoggerService.error('Organization not found', e);
        }
      }

      return enrichedProfile;
    } catch (e) {
      LoggerService.error('Error fetching recruiter profile', e);
      rethrow;
    }
  }

  /// Update organization details
  Future<void> updateOrganization(
    String organizationId,
    Map<String, dynamic> orgData,
  ) async {
    try {
      await _supabase
          .from('organizations')
          .update({...orgData, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', organizationId);
    } catch (e) {
      LoggerService.error('Error updating organization', e);
      rethrow;
    }
  }

  /// Update recruiter profile
  Future<void> updateRecruiterProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            ...profileData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      LoggerService.error('Error updating recruiter profile', e);
      rethrow;
    }
  }

  /// Upload company logo
  Future<String?> uploadCompanyLogo(
    String organizationId,
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final uploadFileName =
          'logo_${organizationId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('organization_assets')
          .uploadBinary(uploadFileName, imageBytes);

      final publicUrl = _supabase.storage
          .from('organization_assets')
          .getPublicUrl(uploadFileName);

      return publicUrl;
    } catch (e) {
      LoggerService.error('Error uploading company logo', e);
      rethrow;
    }
  }

  /// Upload company banner
  Future<String?> uploadCompanyBanner(
    String organizationId,
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final uploadFileName =
          'banner_${organizationId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('organization_assets')
          .uploadBinary(uploadFileName, imageBytes);

      final publicUrl = _supabase.storage
          .from('organization_assets')
          .getPublicUrl(uploadFileName);

      return publicUrl;
    } catch (e) {
      LoggerService.error('Error uploading company banner', e);
      rethrow;
    }
  }

  /// Calculate profile completion percentage
  int calculateProfileCompletion(Map<String, dynamic> profile) {
    int completedFields = 0;
    int totalFields = 15;

    final org = profile['organization'];
    if (org == null) return 20; // Base 20% for having a profile

    // Company basics (5 fields)
    if (org['name'] != null && org['name'].isNotEmpty) completedFields++;
    if (org['logo_url'] != null) completedFields++;
    if (org['banner_url'] != null) completedFields++;
    if (org['tagline'] != null && org['tagline'].isNotEmpty) completedFields++;
    if (org['description'] != null && org['description'].isNotEmpty)
      completedFields++;

    // Company details (5 fields)
    if (org['industry'] != null && org['industry'].isNotEmpty)
      completedFields++;
    if (org['company_size'] != null && org['company_size'].isNotEmpty)
      completedFields++;
    if (org['headquarters'] != null && org['headquarters'].isNotEmpty)
      completedFields++;
    if (org['established_year'] != null) completedFields++;
    if (org['website'] != null && org['website'].isNotEmpty) completedFields++;

    // Specialties and domains (2 fields)
    if (org['specialties'] != null && (org['specialties'] as List).isNotEmpty)
      completedFields++;
    if (org['domains'] != null && (org['domains'] as List).isNotEmpty)
      completedFields++;

    // Contact info (3 fields)
    if (org['phone'] != null && org['phone'].isNotEmpty) completedFields++;
    if (org['email'] != null && org['email'].isNotEmpty) completedFields++;
    if (org['social_links'] != null) completedFields++;

    return ((completedFields / totalFields) * 100).round();
  }
}
