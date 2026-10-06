import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
  final SupabaseClient _supabase;
  
  EmailService(this._supabase);

  // Send invitation emails to students using send-student-invites function
  Future<void> sendStudentInvitations({
    required List<String> emails,
    required String collegeName,
    required String inviteLink,
    String? customMessage,
  }) async {
    try {
      // Use the send-student-invites Edge Function
      final response = await _supabase.functions.invoke(
        'send-student-invites',
        body: {
          'emails': emails,
          'collegeName': collegeName,
          'inviteLink': inviteLink,
          'customMessage': customMessage,
        },
      );
      
      if (response.status != 200) {
        throw Exception('Failed to send invitations: ${response.data}');
      }
    } catch (e) {
      throw Exception('Email service error: $e');
    }
  }

  // Send bulk messages to students (you can create another function later)
  Future<void> sendBulkMessage({
    required List<String> studentIds,
    required String subject,
    required String message,
    required String senderName,
  }) async {
    try {
      // Get student emails from database first
      final students = await _supabase
          .from('profiles')
          .select('email, full_name')
          .inFilter('id', studentIds);
      
      final emails = students.map((s) => s['email'] as String).toList();
      
      // Use the send-bulk-message Edge Function
      final response = await _supabase.functions.invoke(
        'send-bulk-message',
        body: {
          'emails': emails,
          'subject': subject,
          'message': message,
          'senderName': senderName,
        },
      );
      
      if (response.status != 200) {
        throw Exception('Failed to send messages: ${response.data}');
      }
    } catch (e) {
      throw Exception('Bulk message error: $e');
    }
  }

  // Send assessment assignment notification (placeholder)
  Future<void> sendAssessmentNotification({
    required List<String> studentIds,
    required String assessmentTitle,
    required String assessmentLink,
    required DateTime deadline,
    required String collegeName,
  }) async {
    try {
      final students = await _supabase
          .from('profiles')
          .select('email, full_name')
          .inFilter('id', studentIds);
      
      final emails = students.map((s) => s['email'] as String).toList();
      
      // Use the send-assessment-notification Edge Function
      final response = await _supabase.functions.invoke(
        'send-assessment-notification',
        body: {
          'emails': emails,
          'assessmentTitle': assessmentTitle,
          'assessmentLink': assessmentLink,
          'deadline': deadline.toIso8601String(),
          'collegeName': collegeName,
        },
      );
      
      if (response.status != 200) {
        throw Exception('Failed to send notifications: ${response.data}');
      }
    } catch (e) {
      throw Exception('Assessment notification error: $e');
    }
  }

  // Send event invitation (placeholder)
  Future<void> sendEventInvitation({
    required List<String> studentIds,
    required String eventTitle,
    required String eventDetails,
    required String registrationLink,
    required DateTime eventDate,
    required String collegeName,
  }) async {
    try {
      final students = await _supabase
          .from('profiles')
          .select('email, full_name')
          .inFilter('id', studentIds);
      
      final emails = students.map((s) => s['email'] as String).toList();
      
      // Use the send-event-invitation Edge Function
      final response = await _supabase.functions.invoke(
        'send-event-invitation',
        body: {
          'emails': emails,
          'eventTitle': eventTitle,
          'eventDetails': eventDetails,
          'registrationLink': registrationLink,
          'eventDate': eventDate.toIso8601String(),
          'collegeName': collegeName,
        },
      );
      
      if (response.status != 200) {
        throw Exception('Failed to send invitations: ${response.data}');
      }
    } catch (e) {
      throw Exception('Event invitation error: $e');
    }
  }

  // Generate invitation link for students
  String generateInviteLink({
    required String collegeId,
    required String inviteCode,
  }) {
    // This would be your app's deep link or web URL
    return 'https://CareerBridge.app/invite?college=$collegeId&code=$inviteCode';
  }

  // Create invite codes for tracking
  Future<String> createInviteCode({
    required String collegeId,
    required List<String> emails,
  }) async {
    try {
      final response = await _supabase.from('invite_codes').insert({
        'college_id': collegeId,
        'emails': emails,
        'code': _generateRandomCode(),
        'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();
      
      return response['code'] as String;
    } catch (e) {
      throw Exception('Failed to create invite code: $e');
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(8, (index) => chars[random % chars.length]).join();
  }
}