# 🌐 Supabase Cloud Setup Guide - CareerBridge Email System

## 📋 Overview

This guide will help you set up the CareerBridge email system using **Supabase Cloud Dashboard** (no CLI required).

**Your Resend API Key**: `re_YOUR_RESEND_API_KEY`

## 🗄️ Step 1: Database Setup

### 1.1 Access SQL Editor

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Click **New Query**

### 1.2 Run Email System Migration

Copy and paste the entire content from `backend/migration_005_email_system.sql` into the SQL Editor and click **Run**.

**Or copy this complete migration:**

```sql
-- Migration 005: Email System and Communication Features
-- This migration adds tables for email logging, invite codes, and communication tracking

-- ============================================================================
-- EMAIL LOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS email_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(50) NOT NULL, -- 'student_invitation', 'bulk_message', 'assessment_notification', 'event_invitation'
    recipients TEXT[] NOT NULL, -- Array of email addresses
    subject VARCHAR(500),
    college_name VARCHAR(255),
    sender_name VARCHAR(255),
    assessment_title VARCHAR(255),
    event_title VARCHAR(255),
    deadline TIMESTAMPTZ,
    event_date TIMESTAMPTZ,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'sent', -- 'sent', 'failed', 'bounced'
    error_message TEXT,
    metadata JSONB, -- Additional data like open rates, click rates, etc.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for email_logs
CREATE INDEX IF NOT EXISTS idx_email_logs_type ON email_logs(type);
CREATE INDEX IF NOT EXISTS idx_email_logs_sent_at ON email_logs(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_email_logs_status ON email_logs(status);
CREATE INDEX IF NOT EXISTS idx_email_logs_recipients ON email_logs USING GIN(recipients);

-- ============================================================================
-- INVITE CODES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS invite_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    college_id UUID NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    emails TEXT[] NOT NULL, -- Array of invited email addresses
    max_uses INTEGER DEFAULT 1,
    current_uses INTEGER DEFAULT 0,
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB, -- Additional tracking data
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for invite_codes
CREATE INDEX IF NOT EXISTS idx_invite_codes_college ON invite_codes(college_id);
CREATE INDEX IF NOT EXISTS idx_invite_codes_code ON invite_codes(code);
CREATE INDEX IF NOT EXISTS idx_invite_codes_expires_at ON invite_codes(expires_at);
CREATE INDEX IF NOT EXISTS idx_invite_codes_is_active ON invite_codes(is_active);

-- ============================================================================
-- INVITE CODE USAGE TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS invite_code_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invite_code_id UUID NOT NULL REFERENCES invite_codes(id) ON DELETE CASCADE,
    user_id UUID,
    email VARCHAR(255) NOT NULL,
    used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    metadata JSONB
);

-- Indexes for invite_code_usage
CREATE INDEX IF NOT EXISTS idx_invite_code_usage_code ON invite_code_usage(invite_code_id);
CREATE INDEX IF NOT EXISTS idx_invite_code_usage_user ON invite_code_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_invite_code_usage_email ON invite_code_usage(email);

-- ============================================================================
-- COMMUNICATION TEMPLATES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS communication_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    college_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'email', 'sms', 'notification'
    category VARCHAR(50) NOT NULL, -- 'invitation', 'reminder', 'announcement', 'assessment', 'event'
    subject VARCHAR(500),
    body TEXT NOT NULL,
    variables JSONB, -- Available template variables
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID
);

-- Indexes for communication_templates
CREATE INDEX IF NOT EXISTS idx_comm_templates_college ON communication_templates(college_id);
CREATE INDEX IF NOT EXISTS idx_comm_templates_type ON communication_templates(type);
CREATE INDEX IF NOT EXISTS idx_comm_templates_category ON communication_templates(category);
CREATE INDEX IF NOT EXISTS idx_comm_templates_is_active ON communication_templates(is_active);

-- ============================================================================
-- STUDENT COMMUNICATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS student_communications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL,
    college_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'email', 'sms', 'notification', 'in_app'
    category VARCHAR(50) NOT NULL,
    subject VARCHAR(500),
    message TEXT NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sent_by UUID,
    read_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'sent', -- 'sent', 'delivered', 'read', 'failed'
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for student_communications
CREATE INDEX IF NOT EXISTS idx_student_comms_student ON student_communications(student_id);
CREATE INDEX IF NOT EXISTS idx_student_comms_college ON student_communications(college_id);
CREATE INDEX IF NOT EXISTS idx_student_comms_type ON student_communications(type);
CREATE INDEX IF NOT EXISTS idx_student_comms_sent_at ON student_communications(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_student_comms_status ON student_communications(status);

-- ============================================================================
-- EMAIL PREFERENCES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS email_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE,
    receive_invitations BOOLEAN DEFAULT TRUE,
    receive_assessments BOOLEAN DEFAULT TRUE,
    receive_events BOOLEAN DEFAULT TRUE,
    receive_announcements BOOLEAN DEFAULT TRUE,
    receive_reminders BOOLEAN DEFAULT TRUE,
    receive_marketing BOOLEAN DEFAULT FALSE,
    email_frequency VARCHAR(20) DEFAULT 'immediate', -- 'immediate', 'daily', 'weekly'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for email_preferences
CREATE INDEX IF NOT EXISTS idx_email_prefs_user ON email_preferences(user_id);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

-- Trigger for email_logs
CREATE OR REPLACE FUNCTION update_email_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_email_logs_updated_at
    BEFORE UPDATE ON email_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_email_logs_updated_at();

-- Trigger for invite_codes
CREATE OR REPLACE FUNCTION update_invite_codes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invite_codes_updated_at
    BEFORE UPDATE ON invite_codes
    FOR EACH ROW
    EXECUTE FUNCTION update_invite_codes_updated_at();

-- Trigger for communication_templates
CREATE OR REPLACE FUNCTION update_communication_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_communication_templates_updated_at
    BEFORE UPDATE ON communication_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_communication_templates_updated_at();

-- Trigger for email_preferences
CREATE OR REPLACE FUNCTION update_email_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_email_preferences_updated_at
    BEFORE UPDATE ON email_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_email_preferences_updated_at();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS
ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE invite_code_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE communication_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_communications ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_preferences ENABLE ROW LEVEL SECURITY;

-- Basic RLS Policies (you can customize these based on your needs)
CREATE POLICY "Enable all operations for authenticated users" ON email_logs FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all operations for authenticated users" ON invite_codes FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all operations for authenticated users" ON invite_code_usage FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all operations for authenticated users" ON communication_templates FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all operations for authenticated users" ON student_communications FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all operations for authenticated users" ON email_preferences FOR ALL USING (auth.role() = 'authenticated');

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to check if invite code is valid
CREATE OR REPLACE FUNCTION is_invite_code_valid(code_input VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
    code_record RECORD;
BEGIN
    SELECT * INTO code_record
    FROM invite_codes
    WHERE code = code_input
    AND is_active = TRUE
    AND expires_at > NOW()
    AND current_uses < max_uses;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to use invite code
CREATE OR REPLACE FUNCTION use_invite_code(
    code_input VARCHAR,
    user_email VARCHAR,
    user_id_input UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    code_record RECORD;
BEGIN
    -- Get the invite code
    SELECT * INTO code_record
    FROM invite_codes
    WHERE code = code_input
    AND is_active = TRUE
    AND expires_at > NOW()
    AND current_uses < max_uses
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check if email is in the invited list
    IF NOT (user_email = ANY(code_record.emails)) THEN
        RETURN FALSE;
    END IF;
    
    -- Record the usage
    INSERT INTO invite_code_usage (invite_code_id, user_id, email)
    VALUES (code_record.id, user_id_input, user_email);
    
    -- Increment usage count
    UPDATE invite_codes
    SET current_uses = current_uses + 1
    WHERE id = code_record.id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
```

### 1.3 Verify Tables Created

Run this query to verify all tables were created:

```sql
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

## 🔧 Step 2: Set Up Edge Functions

### 2.1 Navigate to Edge Functions

1. In your Supabase dashboard, go to **Edge Functions**
2. Click **Create a new function**

### 2.2 Create Function 1: send-student-invites

1. **Function name**: `send-student-invites`
2. **Code**: Copy the content from `backend/supabase/functions/send-student-invites/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface InviteRequest {
  emails: string[]
  collegeName: string
  inviteLink: string
  customMessage?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { emails, collegeName, inviteLink, customMessage }: InviteRequest = await req.json()

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

    // Email template
    const emailTemplate = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Welcome to CareerBridge</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #6EC9F5 0%, #4A90E2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .button { display: inline-block; background: #6EC9F5; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🎓 Welcome to CareerBridge!</h1>
            <p>Your journey to career excellence starts here</p>
          </div>
          <div class="content">
            <h2>You're Invited to Join ${collegeName}</h2>
            <p>Hello!</p>
            <p>${collegeName} has invited you to join CareerBridge - the comprehensive platform for skill development, assessments, and placement preparation.</p>
            
            ${customMessage ? `<div style="background: #e3f2fd; padding: 15px; border-radius: 5px; margin: 20px 0;"><strong>Message from ${collegeName}:</strong><br>${customMessage}</div>` : ''}
            
            <h3>🚀 What you'll get:</h3>
            <ul>
              <li>✅ <strong>Skill Assessments</strong> - Validate your technical skills</li>
              <li>✅ <strong>Learning Paths</strong> - Structured skill development</li>
              <li>✅ <strong>Mock Interviews</strong> - AI-powered interview practice</li>
              <li>✅ <strong>Resume Builder</strong> - ATS-friendly resume templates</li>
              <li>✅ <strong>Event Participation</strong> - Hackathons, workshops, and more</li>
              <li>✅ <strong>Placement Tracking</strong> - Monitor your placement journey</li>
            </ul>
            
            <div style="text-align: center;">
              <a href="${inviteLink}" class="button">🎯 Join CareerBridge Now</a>
            </div>
            
            <p><strong>Next Steps:</strong></p>
            <ol>
              <li>Click the button above to create your account</li>
              <li>Complete your profile with academic details</li>
              <li>Take skill assessments to validate your abilities</li>
              <li>Start your learning journey!</li>
            </ol>
            
            <p>Need help? Contact your college placement cell or reply to this email.</p>
          </div>
          <div class="footer">
            <p>This invitation was sent by ${collegeName} through CareerBridge</p>
            <p>© 2024 CareerBridge. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `

    // Send emails using Resend
    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') || 're_YOUR_RESEND_API_KEY'
    
    if (!RESEND_API_KEY) {
      throw new Error('RESEND_API_KEY not configured')
    }

    const emailPromises = emails.map(async (email) => {
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: `${collegeName} <noreply@CareerBridge.app>`,
          to: [email],
          subject: `🎓 Welcome to CareerBridge - Invitation from ${collegeName}`,
          html: emailTemplate,
        }),
      })

      if (!response.ok) {
        const error = await response.text()
        throw new Error(`Failed to send email to ${email}: ${error}`)
      }

      return response.json()
    })

    const results = await Promise.all(emailPromises)

    // Log the invitation in database
    await supabaseClient.from('email_logs').insert({
      type: 'student_invitation',
      recipients: emails,
      college_name: collegeName,
      sent_at: new Date().toISOString(),
      status: 'sent',
    })

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `Invitations sent to ${emails.length} students`,
        results 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.error('Error sending invitations:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})
```

3. Click **Deploy function**

### 2.3 Create Function 2: send-bulk-message

1. **Function name**: `send-bulk-message`
2. **Code**: Copy from `backend/supabase/functions/send-bulk-message/index.ts`
3. Click **Deploy function**

### 2.4 Create Function 3: send-assessment-notification

1. **Function name**: `send-assessment-notification`
2. **Code**: Copy from `backend/supabase/functions/send-assessment-notification/index.ts`
3. Click **Deploy function**

### 2.5 Create Function 4: send-event-invitation

1. **Function name**: `send-event-invitation`
2. **Code**: Copy from `backend/supabase/functions/send-event-invitation/index.ts`
3. Click **Deploy function**

## 🔐 Step 3: Set Environment Variables

### 3.1 Navigate to Project Settings

1. Go to **Settings** → **Edge Functions**
2. Scroll down to **Environment Variables**

### 3.2 Add Environment Variables

Add these environment variables:

| Name | Value |
|------|-------|
| `RESEND_API_KEY` | `re_YOUR_RESEND_API_KEY` |
| `EMAIL_FROM_DOMAIN` | `CareerBridge.app` |
| `EMAIL_FROM_NAME` | `CareerBridge` |
| `APP_URL` | `https://CareerBridge.app` |

## 🧪 Step 4: Test Your Setup

### 4.1 Test Edge Functions

1. Go to **Edge Functions** in your dashboard
2. Click on `send-student-invites`
3. Click **Invoke function**
4. Use this test payload:

```json
{
  "emails": ["your-email@example.com"],
  "collegeName": "Test College",
  "inviteLink": "https://CareerBridge.app/invite?code=TEST123",
  "customMessage": "This is a test invitation!"
}
```

### 4.2 Check Email Delivery

1. Check your email inbox for the test invitation
2. Go to [Resend Dashboard](https://resend.com/emails) to see delivery status

### 4.3 Verify Database Logs

Run this query in SQL Editor:

```sql
SELECT * FROM email_logs ORDER BY sent_at DESC LIMIT 10;
```

## 📱 Step 5: Configure Flutter App

### 5.1 Get Your Supabase Credentials

1. Go to **Settings** → **API**
2. Copy your:
   - **Project URL**
   - **Anon public key**

### 5.2 Update Flutter App

Edit `frontend/lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'YOUR_PROJECT_URL_HERE', // Replace with your actual URL
  anonKey: 'YOUR_ANON_KEY_HERE', // Replace with your actual anon key
);
```

### 5.3 Install Dependencies

```bash
cd frontend
flutter pub get
```

### 5.4 Run Flutter App

```bash
flutter run
```

## ✅ Verification Checklist

- [ ] Database migration completed successfully
- [ ] All 6 email tables created
- [ ] All 4 Edge Functions deployed
- [ ] Environment variables set
- [ ] Test email sent and received
- [ ] Email logged in database
- [ ] Flutter app runs without errors
- [ ] Student management screen loads
- [ ] Invite dialog opens and works

## 🚨 Troubleshooting

### Issue: Function deployment fails
**Solution**: Check the function code for syntax errors and ensure all imports are correct.

### Issue: Email not sending
**Solution**: Verify the RESEND_API_KEY environment variable is set correctly.

### Issue: Database error
**Solution**: Check if all tables were created properly by running the verification query.

### Issue: Flutter app crashes
**Solution**: Ensure Supabase credentials are correct in main.dart.

## 🎉 Success!

Once all steps are completed, you'll have:

- ✅ Complete email system with professional templates
- ✅ Student invitation functionality
- ✅ Bulk messaging capabilities
- ✅ Assessment and event notifications
- ✅ Full email tracking and analytics
- ✅ Working Flutter UI integration

Your CareerBridge email system is now ready to send professional emails to students! 🚀

## 📞 Need Help?

If you encounter any issues:

1. Check the **Logs** tab in Edge Functions for error messages
2. Verify environment variables are set correctly
3. Test functions individually using the Invoke button
4. Check email delivery in Resend dashboard
5. Review database logs for any errors

**Your Resend API Key**: `re_YOUR_RESEND_API_KEY`