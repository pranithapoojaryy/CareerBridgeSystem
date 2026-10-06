# Email System Setup Guide

This guide covers the complete setup of the email communication system for CareerBridge, including student invitations, bulk messaging, assessment notifications, and event invitations.

## 📋 Overview

The email system provides:
- **Student Invitations**: Send invitation emails to join the platform
- **Bulk Messaging**: Send messages to multiple students at once
- **Assessment Notifications**: Notify students about new assessments
- **Event Invitations**: Invite students to events and workshops
- **Email Logging**: Track all email communications
- **Invite Code Management**: Secure invitation system with tracking

## 🗄️ Database Setup

### 1. Run the Email System Migration

```sql
-- Run this migration to create all email-related tables
\i migration_005_email_system.sql
```

### 2. Verify Tables Created

```sql
-- Check if all tables are created
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'email_logs',
    'invite_codes', 
    'invite_code_usage',
    'communication_templates',
    'student_communications',
    'email_preferences'
);
```

## 🔧 Supabase Edge Functions Setup

### 1. Deploy Edge Functions

```bash
# Navigate to your Supabase project
cd backend

# Deploy all email functions
supabase functions deploy send-student-invites
supabase functions deploy send-bulk-message
supabase functions deploy send-assessment-notification
supabase functions deploy send-event-invitation
```

### 2. Set Environment Variables

In your Supabase dashboard, go to Settings > Edge Functions and add:

```env
RESEND_API_KEY=your_resend_api_key_here
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## 📧 Email Service Provider Setup (Resend)

### 1. Create Resend Account

1. Go to [Resend.com](https://resend.com)
2. Sign up for an account
3. Verify your domain (recommended for production)

### 2. Get API Key

1. Go to API Keys section
2. Create a new API key
3. Copy the key and add it to your Supabase environment variables

### 3. Domain Verification (Production)

```bash
# Add these DNS records to your domain
# Type: TXT
# Name: @
# Value: resend-verify=your_verification_code

# Type: MX
# Name: @
# Value: feedback-smtp.resend.com
# Priority: 10
```

## 🚀 Flutter App Integration

### 1. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.0.0
  http: ^1.1.0
  flutter_riverpod: ^2.4.0
```

### 2. Initialize Email Service

The email service is already integrated in:
- `lib/core/services/email_service.dart`
- `lib/core/providers/email_service_provider.dart`

### 3. Usage Examples

```dart
// Send student invitations
await ref.read(sendStudentInvitationsProvider({
  'emails': ['student1@college.edu', 'student2@college.edu'],
  'collegeName': 'ABC College',
  'inviteLink': 'https://CareerBridge.app/invite?code=ABC123',
  'customMessage': 'Welcome to our placement program!',
}).future);

// Send bulk message
await ref.read(sendBulkMessageProvider({
  'studentIds': ['uuid1', 'uuid2'],
  'subject': 'Important Update',
  'message': 'Please check your profile...',
  'senderName': 'ABC College',
}).future);
```

## 🔐 Security Configuration

### 1. Row Level Security (RLS)

All email tables have RLS enabled with appropriate policies:

```sql
-- Example: Only college admins can view email logs
CREATE POLICY "College admins can view their email logs"
    ON email_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM college_members cm
            WHERE cm.user_id = auth.uid()
            AND cm.role IN ('admin', 'placement_officer')
        )
    );
```

### 2. API Security

- All Edge Functions require authentication
- CORS is properly configured
- Input validation is implemented

## 📊 Email Templates

### 1. Default Templates

The system includes pre-built templates for:
- Student invitations
- Assessment notifications
- Event invitations
- Bulk messages

### 2. Custom Templates

Create custom templates in the `communication_templates` table:

```sql
INSERT INTO communication_templates (
    college_id,
    name,
    type,
    category,
    subject,
    body,
    variables
) VALUES (
    'your_college_id',
    'Welcome Message',
    'email',
    'invitation',
    'Welcome to {{college_name}}',
    'Hello {{student_name}}, welcome to our platform...',
    '{"college_name": "string", "student_name": "string"}'::jsonb
);
```

## 📈 Monitoring and Analytics

### 1. Email Logs

Monitor email delivery through the `email_logs` table:

```sql
-- Check recent email activity
SELECT 
    type,
    COUNT(*) as count,
    status
FROM email_logs 
WHERE sent_at >= NOW() - INTERVAL '7 days'
GROUP BY type, status;
```

### 2. Invite Code Analytics

Track invitation success rates:

```sql
-- Invite code usage statistics
SELECT 
    ic.code,
    ic.college_id,
    array_length(ic.emails, 1) as invited_count,
    ic.current_uses as used_count,
    ROUND(ic.current_uses::decimal / array_length(ic.emails, 1) * 100, 2) as usage_rate
FROM invite_codes ic
WHERE ic.created_at >= NOW() - INTERVAL '30 days';
```

## 🧪 Testing

### 1. Test Email Functions

```bash
# Test student invitation function
curl -X POST 'https://your-project.supabase.co/functions/v1/send-student-invites' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "emails": ["test@example.com"],
    "collegeName": "Test College",
    "inviteLink": "https://test.com/invite",
    "customMessage": "Test message"
  }'
```

### 2. Test Flutter Integration

```dart
// Test in your Flutter app
void testEmailService() async {
  try {
    await ref.read(sendStudentInvitationsProvider({
      'emails': ['test@example.com'],
      'collegeName': 'Test College',
      'inviteLink': 'https://test.com',
    }).future);
    print('Email sent successfully!');
  } catch (e) {
    print('Error: $e');
  }
}
```

## 🚨 Troubleshooting

### Common Issues

1. **Email not sending**
   - Check Resend API key
   - Verify domain configuration
   - Check Edge Function logs

2. **Permission denied**
   - Verify RLS policies
   - Check user authentication
   - Confirm college membership

3. **Template not found**
   - Check template exists in database
   - Verify template is active
   - Check college_id matches

### Debug Commands

```sql
-- Check email logs for errors
SELECT * FROM email_logs 
WHERE status = 'failed' 
ORDER BY sent_at DESC;

-- Check invite code validity
SELECT * FROM invite_codes 
WHERE expires_at < NOW() OR current_uses >= max_uses;

-- Check user permissions
SELECT cm.role, c.name 
FROM college_members cm
JOIN colleges c ON c.id = cm.college_id
WHERE cm.user_id = 'your_user_id';
```

## 📝 Best Practices

1. **Email Frequency**: Implement rate limiting to avoid spam
2. **Template Management**: Use variables for dynamic content
3. **Error Handling**: Always log failed emails for retry
4. **User Preferences**: Respect user email preferences
5. **Analytics**: Track open rates and engagement
6. **Security**: Validate all inputs and sanitize content

## 🔄 Maintenance

### Regular Tasks

1. **Clean up expired invite codes**:
```sql
DELETE FROM invite_codes 
WHERE expires_at < NOW() - INTERVAL '30 days';
```

2. **Archive old email logs**:
```sql
-- Move logs older than 6 months to archive table
-- (Create archive table first)
```

3. **Update email templates**:
```sql
-- Keep templates updated with latest branding
UPDATE communication_templates 
SET body = 'updated_template_content'
WHERE name = 'template_name';
```

## 📞 Support

For issues with the email system:
1. Check the troubleshooting section above
2. Review Supabase Edge Function logs
3. Check Resend dashboard for delivery status
4. Verify database permissions and RLS policies

---

**Note**: This email system is designed to be scalable and secure. Always test in a development environment before deploying to production.