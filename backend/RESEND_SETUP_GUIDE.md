# 📧 Resend API Setup Guide for CareerBridge

## 🎯 Overview

This guide will help you set up the Resend API for sending emails in your CareerBridge application. Your Resend API key has been configured: `re_YOUR_RESEND_API_KEY`

## 🔑 API Key Configuration

### Option 1: Supabase CLI (Recommended)

```bash
# Set the Resend API key as a Supabase secret
supabase secrets set RESEND_API_KEY=re_YOUR_RESEND_API_KEY

# Set additional email configuration
supabase secrets set EMAIL_FROM_DOMAIN=CareerBridge.app
supabase secrets set EMAIL_FROM_NAME=CareerBridge
supabase secrets set APP_URL=https://CareerBridge.app

# Verify secrets
supabase secrets list
```

### Option 2: Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to **Settings** → **Edge Functions**
3. Add the following environment variables:

```
RESEND_API_KEY=re_YOUR_RESEND_API_KEY
EMAIL_FROM_DOMAIN=CareerBridge.app
EMAIL_FROM_NAME=CareerBridge
APP_URL=https://CareerBridge.app
```

### Option 3: Use PowerShell Script (Windows)

```powershell
# Run the setup script
.\setup_supabase_secrets.ps1
```

### Option 4: Use Bash Script (Linux/Mac)

```bash
# Make script executable and run
chmod +x setup_supabase_secrets.sh
./setup_supabase_secrets.sh
```

## 🚀 Deploy Edge Functions

After setting up the secrets, deploy all email functions:

```bash
# Deploy all email functions
supabase functions deploy send-student-invites
supabase functions deploy send-bulk-message
supabase functions deploy send-assessment-notification
supabase functions deploy send-event-invitation
```

## 🧪 Test Your Setup

### 1. Test Student Invitations

```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/send-student-invites' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "emails": ["test@example.com"],
    "collegeName": "Test College",
    "inviteLink": "https://CareerBridge.app/invite?code=TEST123",
    "customMessage": "Welcome to our placement program!"
  }'
```

### 2. Test Bulk Messaging

```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/send-bulk-message' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "emails": ["student1@college.edu", "student2@college.edu"],
    "subject": "Important Update",
    "message": "Please check your profile and complete any pending tasks.",
    "senderName": "Test College"
  }'
```

## 📊 Resend Dashboard

### Access Your Resend Account

1. Go to [resend.com](https://resend.com)
2. Log in with your account
3. Navigate to the **API Keys** section
4. Your API key: `re_YOUR_RESEND_API_KEY`

### Monitor Email Delivery

- **Logs**: View all sent emails and their status
- **Analytics**: Track open rates, click rates, and bounces
- **Domains**: Verify your domain for better deliverability
- **Webhooks**: Set up real-time delivery notifications

## 🔧 Domain Verification (Recommended for Production)

### 1. Add Your Domain

1. In Resend dashboard, go to **Domains**
2. Click **Add Domain**
3. Enter `CareerBridge.app`

### 2. Add DNS Records

Add these DNS records to your domain:

```
Type: TXT
Name: @
Value: resend-verify=your_verification_code

Type: MX
Name: @
Value: feedback-smtp.resend.com
Priority: 10

Type: CNAME
Name: resend._domainkey
Value: resend._domainkey.resend.com
```

### 3. Verify Domain

After adding DNS records, click **Verify Domain** in Resend dashboard.

## 📈 Email Templates

### Current Templates Available

1. **Student Invitation** - Professional welcome email with feature highlights
2. **Bulk Message** - Clean message template for announcements
3. **Assessment Notification** - Urgent-style email for test assignments
4. **Event Invitation** - Engaging template for events and workshops

### Customize Templates

You can modify templates in the Edge Function files:
- `send-student-invites/index.ts`
- `send-bulk-message/index.ts`
- `send-assessment-notification/index.ts`
- `send-event-invitation/index.ts`

## 🔐 Security Best Practices

### 1. API Key Security

- ✅ API key is stored as Supabase secret (encrypted)
- ✅ Never expose API key in client-side code
- ✅ Use environment variables in Edge Functions
- ✅ Rotate API keys periodically

### 2. Email Security

- ✅ Validate all email addresses
- ✅ Sanitize email content
- ✅ Implement rate limiting
- ✅ Use DKIM and SPF records

### 3. Monitoring

- ✅ Log all email activities
- ✅ Monitor bounce rates
- ✅ Track delivery failures
- ✅ Set up alerts for issues

## 📊 Usage Limits

### Resend Free Tier

- **3,000 emails/month** for free
- **100 emails/day** limit
- **1 verified domain**

### Resend Pro Tier

- **50,000 emails/month** for $20
- **Unlimited daily sending**
- **Multiple domains**
- **Advanced analytics**

## 🚨 Troubleshooting

### Common Issues

1. **"RESEND_API_KEY not configured"**
   - Ensure the secret is set in Supabase
   - Redeploy Edge Functions after setting secrets

2. **"Domain not verified"**
   - Complete domain verification in Resend dashboard
   - Use `noreply@CareerBridge.app` as sender

3. **"Rate limit exceeded"**
   - Check your Resend usage limits
   - Implement exponential backoff

4. **"Email bounced"**
   - Verify recipient email addresses
   - Check spam folder
   - Review email content for spam triggers

### Debug Commands

```bash
# Check Supabase secrets
supabase secrets list

# View Edge Function logs
supabase functions logs send-student-invites

# Test API key directly
curl -X POST 'https://api.resend.com/emails' \
  -H 'Authorization: Bearer re_YOUR_RESEND_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "from": "test@CareerBridge.app",
    "to": ["test@example.com"],
    "subject": "Test Email",
    "html": "<p>Test message</p>"
  }'
```

## 📞 Support

### Resend Support

- **Documentation**: [resend.com/docs](https://resend.com/docs)
- **Support**: [resend.com/support](https://resend.com/support)
- **Status**: [status.resend.com](https://status.resend.com)

### CareerBridge Email System

- Check the `EMAIL_SYSTEM_SETUP.md` for detailed setup
- Review Edge Function logs for errors
- Monitor `email_logs` table in database

---

## ✅ Quick Setup Checklist

- [ ] Set Resend API key in Supabase secrets
- [ ] Deploy all Edge Functions
- [ ] Test email sending functionality
- [ ] Verify domain in Resend (optional)
- [ ] Set up monitoring and alerts
- [ ] Configure email templates
- [ ] Test error handling

**Your Resend API key is ready to use: `re_YOUR_RESEND_API_KEY`**

🚀 **Ready to send professional emails!**