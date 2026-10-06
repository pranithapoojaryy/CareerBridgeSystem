import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger_service.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String role,
    required Map<String, dynamic> additionalData,
  }) async {
    Map<String, dynamic> metadata = {'role': role, ...additionalData};

    // Auto-Link Logic for Students & Faculty
    if (role == 'student' || role == 'faculty') {
      try {
        final emailDomain = email.split('@').last.toLowerCase();
        final orgs = await _supabase
            .from('organizations')
            .select('id')
            .eq('allowed_emails_domain', emailDomain)
            .limit(1);

        if (orgs.isNotEmpty) {
          metadata['organization_id'] = orgs.first['id'];
        }
      } catch (_) {
        // Continue without linking if check fails
      }
    }

    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );

    if (response.user == null) return response;

    // For recruiters: ensure profile + organization are created.
    // The DB trigger may fail (e.g. 'company' type violates the CHECK constraint
    // on organizations.type which only allows 'college','university','institute').
    // We handle it here as a fallback/supplement.
    if (role == 'recruiter') {
      await _ensureRecruiterProfileCreated(
        user: response.user!,
        email: email,
        additionalData: additionalData,
      );
    }

    // For students, create additional profile data after successful signup
    if (role == 'student') {
      try {
        // 1. Update the base profile
        await _supabase
            .from('profiles')
            .update({
              'full_name': additionalData['full_name'],
              'phone': additionalData['phone'],
              'organization_id': additionalData['college_id'],
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', response.user!.id);

        // 2. Update the student-specific profile (academic details)
        await _supabase.from('student_profiles').upsert({
          'id': response.user!.id,
          'usn': additionalData['usn'],
          'college_id': additionalData['college_id']?.toString(),
          'department_id': additionalData['department_id'],
          'program_id': additionalData['program_id'],
          'batch_id': additionalData['batch_id'],
          'semester': additionalData['current_semester'],
          'cgpa': additionalData['cgpa'],
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Notify college about new student registration
        if (additionalData['college_id'] != null) {
          try {
            await _supabase.functions.invoke(
              'notify-college-student-registration',
              body: {
                'studentId': response.user!.id,
                'collegeId': additionalData['college_id'],
                'studentName': additionalData['full_name'],
                'studentEmail': email,
              },
            );
          } catch (e) {
            // Don't fail registration if notification fails
          }
        }
      } catch (e) {
        // Error updating student profile - continue with registration
        LoggerService.error('Error updating student profile data', e);
      }
    }

    return response;
  }

  /// Ensures that a recruiter profile and their organization exist in the DB.
  /// Uses upsert so it is idempotent — safe even if the trigger already ran.
  Future<void> _ensureRecruiterProfileCreated({
    required User user,
    required String email,
    required Map<String, dynamic> additionalData,
  }) async {
    try {
      // Step 1: Check if profile already exists (DB trigger may have created it)
      final existingProfile = await _supabase
          .from('profiles')
          .select('id, organization_id')
          .eq('id', user.id)
          .maybeSingle();

      String? orgId = existingProfile?['organization_id'] as String?;

      // Step 2: If no organization linked, create one
      if (orgId == null) {
        final companyName =
            (additionalData['company_name'] as String?)?.trim();
        if (companyName != null && companyName.isNotEmpty) {
          final rawCode = companyName.replaceAll(' ', '').toUpperCase();
          final shortCode =
              rawCode.length > 6 ? rawCode.substring(0, 6) : rawCode;

          try {
            final orgResponse = await _supabase
                .from('organizations')
                .insert({
                  'name': companyName,
                  'short_code': shortCode.isEmpty ? 'ORG001' : shortCode,
                  // Use 'institute' — valid value satisfying the CHECK constraint
                  // (college | university | institute). 'company' is NOT valid.
                  'type': 'institute',
                  'industry': additionalData['industry'] ?? 'Technology',
                  'company_size': additionalData['company_size'] ?? '1-10',
                  'headquarters': additionalData['company_location'],
                  'website': additionalData['company_website'],
                  'description': 'Company profile for $companyName',
                  'created_by': user.id,
                })
                .select('id')
                .single();
            orgId = orgResponse['id'] as String?;
            LoggerService.debug('Created organization for recruiter: $orgId');
          } catch (orgError) {
            LoggerService.error(
              'Error creating organization for recruiter',
              orgError,
            );
            // Try to find an existing org created by this user as fallback
            try {
              final existingOrg = await _supabase
                  .from('organizations')
                  .select('id')
                  .eq('created_by', user.id)
                  .maybeSingle();
              orgId = existingOrg?['id'] as String?;
            } catch (_) {}
          }
        }
      }

      // Step 3: Upsert profile (create if missing, update if exists)
      if (existingProfile == null) {
        // Profile does not exist — insert a new one
        final profileData = <String, dynamic>{
          'id': user.id,
          'email': email,
          'role': 'recruiter',
          'full_name': additionalData['full_name'] ?? '',
          'phone': additionalData['phone'],
          'job_title': additionalData['designation'],
          'profile_completion': 30,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (orgId != null) {
          profileData['organization_id'] = orgId;
        }
        await _supabase.from('profiles').insert(profileData);
        LoggerService.debug('Created recruiter profile for user: ${user.id}');
      } else if (orgId != null &&
          existingProfile['organization_id'] == null) {
        // Profile exists but lacks org link — patch it
        await _supabase
            .from('profiles')
            .update({
              'organization_id': orgId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);
        LoggerService.debug(
          'Linked organization to existing recruiter profile: ${user.id}',
        );
      }
    } catch (e) {
      // Don't fail registration even if profile creation has issues.
      // AppWrapper._getUserProfile() has a fallback to create a profile on first login.
      LoggerService.error('Error ensuring recruiter profile creation', e);
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }
}
