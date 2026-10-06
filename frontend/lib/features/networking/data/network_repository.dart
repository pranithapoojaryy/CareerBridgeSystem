import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NetworkRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // --- Connections ---

  /// Sends a connection request to the target user.
  /// Returns the ID of the new connection.
  Future<String> sendConnectionRequest(String targetUserId) async {
    try {
      final response = await _client.rpc(
        'send_connection_request',
        params: {'target_user_id': targetUserId},
      );
      return response as String;
    } catch (e) {
      throw Exception('Failed to send connection request: $e');
    }
  }

  /// Fetches the user's accepted connections.
  Future<List<Map<String, dynamic>>> getMyConnections() async {
    try {
      final response = await _client.rpc('get_my_connections');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('getMyConnections error: $e');
      return []; // Return empty instead of crashing
    }
  }

  /// Fetches pending connection requests received by the user.
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final response = await _client.rpc('get_pending_requests');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('getPendingRequests error: $e');
      return [];
    }
  }

  /// Accepts a connection request.
  Future<void> acceptConnectionRequest(String connectionId) async {
    try {
      await _client
          .from('connections')
          .update({'status': 'accepted'})
          .eq('id', connectionId);
    } catch (e) {
      throw Exception('Failed to accept request: $e');
    }
  }

  /// Rejects or Ignores a connection request.
  Future<void> ignoreConnectionRequest(String connectionId) async {
    try {
      await _client
          .from('connections')
          .update({'status': 'rejected'})
          .eq('id', connectionId);
    } catch (e) {
      throw Exception('Failed to ignore request: $e');
    }
  }

  /// Checks the connection status between the current user and a target user.
  /// Returns: 'pending', 'accepted', 'rejected', 'blocked', or null (if no connection).
  Future<String?> getConnectionStatus(String targetUserId) async {
    try {
      final response = await _client.rpc(
        'get_connection_status',
        params: {'target_user_id': targetUserId},
      );
      return response as String?;
    } catch (e) {
      // It might return null if no connection exists
      return null;
    }
  }

  // --- Search ---

  /// Searches for profiles by name or email (excluding current user).
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      debugPrint('🔍 Searching for: $query');
      final response = await _client.rpc(
        'search_profiles',
        params: {'search_query': query},
      );
      debugPrint('🔍 Search response type: ${response.runtimeType}');
      debugPrint('🔍 Search response: $response');
      final results = List<Map<String, dynamic>>.from(response as List);
      debugPrint('🔍 Found ${results.length} results');
      return results;
    } catch (e) {
      debugPrint('❌ Search error: $e');
      throw Exception('Failed to search users: $e');
    }
  }

  // --- Messages ---

  /// Fetches the list of conversations (users you've messaged with).
  Future<List<Map<String, dynamic>>> getMyConversations() async {
    try {
      final response = await _client.rpc('get_my_conversations');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('getMyConversations error: $e');
      return [];
    }
  }

  /// Clears chat history with a specific user.
  Future<void> clearChatHistory(String targetUserId) async {
    try {
      await _client.rpc(
        'clear_chat_history',
        params: {'target_user_id': targetUserId},
      );
    } catch (e) {
      throw Exception('Failed to clear chat: $e');
    }
  }

  /// Fetches suggested connections (2nd-degree + discovery fallback).
  Future<List<Map<String, dynamic>>> getSuggestedConnections() async {
    try {
      final response = await _client.rpc('get_suggested_connections');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error getting suggested connections: $e');
      // Return empty list instead of throwing to prevent UI break
      return [];
    }
  }

  /// Browse profiles by role for discovery in the network screen.
  /// [roleFilter]: 'all', 'student', 'recruiter', 'college'
  /// Uses direct table query (no RPC required) so it works immediately.
  Future<List<Map<String, dynamic>>> browseProfiles({
    String roleFilter = 'all',
    int limit = 50,
    int offset = 0,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return [];

    try {
      // Build role filter list
      List<String> roles;
      if (roleFilter == 'student') {
        roles = ['student'];
      } else if (roleFilter == 'recruiter') {
        roles = ['recruiter'];
      } else if (roleFilter == 'college') {
        roles = ['college', 'college_admin'];
      } else {
        roles = ['student', 'recruiter', 'college', 'college_admin'];
      }

      // Query profiles directly — no RPC needed
      final results = await _client
          .from('profiles')
          .select('id, full_name, avatar_url, role, organization_id, headline')
          .neq('id', currentUser.id)
          .inFilter('role', roles)
          .not('full_name', 'is', null)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Normalize to match what the UI expects
      final normalized = (results as List).map((r) {
        final map = Map<String, dynamic>.from(r);
        map['user_id'] = map['id'];
        map['connection_status'] = 'none'; // will be updated when connecting
        return map;
      }).toList();

      // Try to enrich with connection status in bulk
      try {
        // Get all my connections in one query
        final myConns = await _client
            .from('connections')
            .select('requester_id, receiver_id, status')
            .or('requester_id.eq.${currentUser.id},receiver_id.eq.${currentUser.id}');

        final connMap = <String, String>{};
        for (final c in myConns as List) {
          final isRequester = c['requester_id'] == currentUser.id;
          final otherId =
              isRequester ? c['receiver_id'] : c['requester_id'] as String;
          final status = c['status'] as String;
          if (status == 'accepted') {
            connMap[otherId] = 'connected';
          } else if (status == 'pending' && isRequester) {
            connMap[otherId] = 'pending';
          } else if (status == 'pending' && !isRequester) {
            connMap[otherId] = 'request_received';
          }
        }

        for (final p in normalized) {
          final uid = p['id'] as String;
          p['connection_status'] = connMap[uid] ?? 'none';
        }
      } catch (e) {
        // If connection enrichment fails, just show 'none' for all
        debugPrint('Connection status enrichment error: $e');
      }

      return normalized;
    } catch (e) {
      debugPrint('browseProfiles error: $e');
      return [];
    }
  }
}

