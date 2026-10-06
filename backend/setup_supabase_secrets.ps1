# Setup Supabase Secrets for Email System
# Make sure you have Supabase CLI installed and are logged in

Write-Host "🔧 Setting up Supabase secrets for email system..." -ForegroundColor Cyan

# Set Resend API Key
Write-Host "📧 Setting Resend API key..." -ForegroundColor Yellow
supabase secrets set RESEND_API_KEY=re_YOUR_RESEND_API_KEY

# Set email configuration
Write-Host "⚙️ Setting email configuration..." -ForegroundColor Yellow
supabase secrets set EMAIL_FROM_DOMAIN=CareerBridge.app
supabase secrets set EMAIL_FROM_NAME=CareerBridge
supabase secrets set APP_URL=https://CareerBridge.app

# Set additional configuration
Write-Host "🌐 Setting app configuration..." -ForegroundColor Yellow
supabase secrets set INVITE_BASE_URL=https://CareerBridge.app/invite
supabase secrets set APP_ENV=production

Write-Host ""
Write-Host "✅ All secrets have been set!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Verify your secrets with:" -ForegroundColor Cyan
Write-Host "supabase secrets list" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Deploy your Edge Functions with:" -ForegroundColor Cyan
Write-Host "supabase functions deploy send-student-invites" -ForegroundColor White
Write-Host "supabase functions deploy send-bulk-message" -ForegroundColor White
Write-Host "supabase functions deploy send-assessment-notification" -ForegroundColor White
Write-Host "supabase functions deploy send-event-invitation" -ForegroundColor White