#!/bin/bash

# Setup Supabase Secrets for Email System
# Make sure you have Supabase CLI installed and are logged in

echo "🔧 Setting up Supabase secrets for email system..."

# Set Resend API Key
echo "📧 Setting Resend API key..."
supabase secrets set RESEND_API_KEY=re_YOUR_RESEND_API_KEY

# Set email configuration
echo "⚙️ Setting email configuration..."
supabase secrets set EMAIL_FROM_DOMAIN=CareerBridge.app
supabase secrets set EMAIL_FROM_NAME=CareerBridge
supabase secrets set APP_URL=https://CareerBridge.app

# Set additional configuration
echo "🌐 Setting app configuration..."
supabase secrets set INVITE_BASE_URL=https://CareerBridge.app/invite
supabase secrets set APP_ENV=production

echo "✅ All secrets have been set!"
echo ""
echo "📋 Verify your secrets with:"
echo "supabase secrets list"
echo ""
echo "🚀 Deploy your Edge Functions with:"
echo "supabase functions deploy send-student-invites"
echo "supabase functions deploy send-bulk-message"
echo "supabase functions deploy send-assessment-notification"
echo "supabase functions deploy send-event-invitation"