import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/email_service.dart';

// Email Service Provider
final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService(Supabase.instance.client);
});

// Provider for sending student invitations
final sendStudentInvitationsProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final emailService = ref.watch(emailServiceProvider);
  
  await emailService.sendStudentInvitations(
    emails: params['emails'] as List<String>,
    collegeName: params['collegeName'] as String,
    inviteLink: params['inviteLink'] as String,
    customMessage: params['customMessage'] as String?,
  );
});

// Provider for sending bulk messages
final sendBulkMessageProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final emailService = ref.watch(emailServiceProvider);
  
  await emailService.sendBulkMessage(
    studentIds: params['studentIds'] as List<String>,
    subject: params['subject'] as String,
    message: params['message'] as String,
    senderName: params['senderName'] as String,
  );
});

// Provider for sending assessment notifications
final sendAssessmentNotificationProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final emailService = ref.watch(emailServiceProvider);
  
  await emailService.sendAssessmentNotification(
    studentIds: params['studentIds'] as List<String>,
    assessmentTitle: params['assessmentTitle'] as String,
    assessmentLink: params['assessmentLink'] as String,
    deadline: params['deadline'] as DateTime,
    collegeName: params['collegeName'] as String,
  );
});

// Provider for sending event invitations
final sendEventInvitationProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final emailService = ref.watch(emailServiceProvider);
  
  await emailService.sendEventInvitation(
    studentIds: params['studentIds'] as List<String>,
    eventTitle: params['eventTitle'] as String,
    eventDetails: params['eventDetails'] as String,
    registrationLink: params['registrationLink'] as String,
    eventDate: params['eventDate'] as DateTime,
    collegeName: params['collegeName'] as String,
  );
});

// Provider for creating invite codes
final createInviteCodeProvider = FutureProvider.family<String, Map<String, dynamic>>((ref, params) async {
  final emailService = ref.watch(emailServiceProvider);
  
  return await emailService.createInviteCode(
    collegeId: params['collegeId'] as String,
    emails: params['emails'] as List<String>,
  );
});