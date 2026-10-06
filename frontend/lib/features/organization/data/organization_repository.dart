import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final organizationRepositoryProvider = Provider((ref) {
  return OrganizationRepository(Supabase.instance.client);
});

class OrganizationRepository {
  final SupabaseClient _supabase;

  OrganizationRepository(this._supabase);

  Future<void> createOrganization({
    required String userId,
    required String name,
    required String shortCode,
    required String type,
    String? website,
    String? addressCity,
    String? addressState,
    String? addressCountry,
    List<String>? programs,
    String? batches,
  }) async {
    // 1. Insert Organization via RPC (Bypasses RLS)
    final response = await _supabase.rpc(
      'create_new_organization',
      params: {
        'p_name': name,
        'p_short_code': shortCode,
        'p_type': type,
        'p_website': website,
        'p_city': addressCity,
        'p_state': addressState,
        'p_country': addressCountry,
        'p_config': {'default_programs': programs, 'default_batches': batches},
        'p_user_id': userId,
      },
    );

    // Response is already a Map/JSON
    final orgId = response['id'];

    // 2. Link User to Organization
    // Note: If user is not logged in (no session), updateUser will FAIL too.
    // However, the TRIGGER on auth.users (handle_new_user) should have created the profile.
    // We can try to update the profile via the service role (not possible from client)
    // OR we rely on the admin approval process to link them fully if this fails.

    // Attempting update - might fail if no session, but we wrap in try-catch to not crash the flow
    try {
      if (_supabase.auth.currentSession != null) {
        await _supabase.auth.updateUser(
          UserAttributes(data: {'organization_id': orgId}),
        );
      }
    } catch (_) {}

    // We can't update public profile if RLS blocks it and we aren't logged in.
    // Instead, we should probably handle this linkage in a Backend Edge Function
    // or Database Trigger. For now, we assume the org creation is the critical part.
  }

  Future<bool> checkShortCodeAvailability(String shortCode) async {
    final response = await _supabase
        .from('organizations')
        .select('id')
        .eq('short_code', shortCode)
        .maybeSingle();
    return response == null;
  }

  Future<void> updateOrganizationProfile({
    required String orgId,
    String? description,
    String? bannerUrl,
    String? tagline,
    String? primaryColor,
    String? allowedDomain,
    Map<String, dynamic>? socialLinks,
  }) async {
    final updates = {
      if (description != null) 'description': description,
      if (bannerUrl != null) 'banner_url': bannerUrl,
      if (tagline != null) 'tagline': tagline,
      if (primaryColor != null) 'primary_color': primaryColor,
      if (allowedDomain != null) 'allowed_emails_domain': allowedDomain,
      if (socialLinks != null) 'social_links': socialLinks,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (updates.isNotEmpty) {
      await _supabase.from('organizations').update(updates).eq('id', orgId);
    }
  }

  // --- Academic Structure ---

  Future<String> addDepartment(String orgId, String name, String code) async {
    final res = await _supabase
        .from('college_departments')
        .insert({'org_id': orgId, 'name': name, 'code': code})
        .select()
        .single();
    return res['id'];
  }

  Future<List<Map<String, dynamic>>> getDepartments(String orgId) async {
    final res = await _supabase
        .from('college_departments')
        .select()
        .eq('org_id', orgId)
        .order('name');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<String> addProgram(String deptId, String name, String type) async {
    final res = await _supabase
        .from('college_programs')
        .insert({'dept_id': deptId, 'name': name, 'type': type})
        .select()
        .single();
    return res['id'];
  }

  Future<void> addBatch(
    String programId,
    String name,
    int startYear,
    int endYear,
  ) async {
    await _supabase.from('college_batches').insert({
      'program_id': programId,
      'name': name,
      'start_year': startYear,
      'end_year': endYear,
    });
  }

  Future<Map<String, dynamic>?> getOrganizationByUserId(String userId) async {
    // Fetch via RPC or simple select if RLS allows
    // For now, assuming org linkage in user metadata or we query orgs created by user
    final res = await _supabase
        .from('organizations')
        .select()
        .eq('created_by', userId)
        .maybeSingle();
    return res;
  }

  Future<String> uploadOrganizationAsset({
    required String orgId,
    required List<int> fileBytes,
    required String fileName,
    required String type, // 'logo' or 'banner'
  }) async {
    final path =
        '$orgId/$type/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _supabase.storage
        .from('organization_assets')
        .uploadBinary(
          path,
          fileBytes
              as dynamic, // Cast for compatibility if needed, depending on sdk version
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    // Get Public URL
    final url = _supabase.storage
        .from('organization_assets')
        .getPublicUrl(path);
    return url;
  }
}
