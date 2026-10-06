import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logger_service.dart';

class IdentityHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Extracts the organizational identity (Name & Logo) from a user profile map.
  /// Falls back to individual details if no organization is linked or for student roles.
  static Map<String, String?> getOrganizationalIdentity(
    Map<String, dynamic> user,
  ) {
    final role = user['role'];
    final bool isOrgRole =
        role == 'recruiter' || role == 'college' || role == 'college_admin';

    // Check if organization data is already joined/present
    final org = user['organization'] ?? user['organizations'];

    if (isOrgRole && org != null) {
      return {
        'display_name': org['name'] ?? user['full_name'],
        'avatar_url':
            org['logo_url'] ??
            (user['profile_photo_url'] ?? user['avatar_url']),
        'role_label': role == 'recruiter' ? 'Recruiter' : 'College',
      };
    }

    return {
      'display_name': user['full_name'],
      'avatar_url': user['profile_photo_url'] ?? user['avatar_url'],
      'role_label': role != null
          ? role[0].toUpperCase() + role.substring(1)
          : 'Member',
    };
  }

  /// Enhances a list of users with organization details if they are recruiters or colleges.
  /// Useful for list views where the initial data might only have user IDs and roles.
  static Future<List<Map<String, dynamic>>> enhanceUserList(
    List<Map<String, dynamic>> users,
  ) async {
    if (users.isEmpty) return users;

    final List<Map<String, dynamic>> enhancedUsers = [];

    for (var user in users) {
      final role = user['role'];
      final userId =
          user['user_id'] ??
          user['id'] ??
          user['requester_id'] ??
          user['receiver_id'];

      final bool isOrgRole =
          role == 'recruiter' || role == 'college' || role == 'college_admin';

      if (isOrgRole && userId != null) {
        try {
          final response = await _supabase
              .from('profiles')
              .select('*, organization:organizations(name, logo_url)')
              .eq('id', userId)
              .maybeSingle();

          if (response != null) {
            // Merge response with existing user data to preserve fields like connection_id
            final mergedUser = Map<String, dynamic>.from(user);
            mergedUser.addAll(response);
            enhancedUsers.add(mergedUser);
            continue;
          }
        } catch (e) {
          LoggerService.error('Error enhancing user $userId', e);
        }
      }
      enhancedUsers.add(user);
    }

    return enhancedUsers;
  }
}
