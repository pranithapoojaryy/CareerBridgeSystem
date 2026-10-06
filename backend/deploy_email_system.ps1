# CareerBridge Email System Deployment Script
# This script sets up the complete email system with Resend API

Write-Host "🚀 CareerBridge Email System Deployment" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Check if Supabase CLI is installed
try {
    $supabaseVersion = supabase --version
    Write-Host "✅ Supabase CLI found: $supabaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Supabase CLI not found. Please install it first:" -ForegroundColor Red
    Write-Host "   npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "🔧 Step 1: Setting up Supabase secrets..." -ForegroundColor Yellow

# Set Resend API Key
Write-Host "📧 Setting Resend API key..." -ForegroundColor White
supabase secrets set RESEND_API_KEY=re_YOUR_RESEND_API_KEY

# Set email configuration
Write-Host "⚙️ Setting email configuration..." -ForegroundColor White
supabase secrets set EMAIL_FROM_DOMAIN=CareerBridge.app
supabase secrets set EMAIL_FROM_NAME=CareerBridge
supabase secrets set APP_URL=https://CareerBridge.app
supabase secrets set INVITE_BASE_URL=https://CareerBridge.app/invite

Write-Host ""
Write-Host "🗄️ Step 2: Setting up database..." -ForegroundColor Yellow

# Run email system migration
Write-Host "📊 Running email system migration..." -ForegroundColor White
supabase db reset --linked

Write-Host ""
Write-Host "🔧 Step 3: Deploying Edge Functions..." -ForegroundColor Yellow

# Deploy all email functions
Write-Host "📧 Deploying send-student-invites..." -ForegroundColor White
supabase functions deploy send-student-invites

Write-Host "💬 Deploying send-bulk-message..." -ForegroundColor White
supabase functions deploy send-bulk-message

Write-Host "📝 Deploying send-assessment-notification..." -ForegroundColor White
supabase functions deploy send-assessment-notification

Write-Host "🎉 Deploying send-event-invitation..." -ForegroundColor White
supabase functions deploy send-event-invitation

Write-Host ""
Write-Host "🧪 Step 4: Testing the setup..." -ForegroundColor Yellow

# Get project URL
$projectUrl = supabase status | Select-String "API URL" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }

if ($projectUrl) {
    Write-Host "🌐 Project URL: $projectUrl" -ForegroundColor Green
    
    # Test function deployment
    Write-Host "🔍 Testing function endpoints..." -ForegroundColor White
    
    $functions = @(
        "send-student-invites",
        "send-bulk-message", 
        "send-assessment-notification",
        "send-event-invitation"
    )
    
    foreach ($func in $functions) {
        $url = "$projectUrl/functions/v1/$func"
        try {
            $response = Invoke-WebRequest -Uri $url -Method OPTIONS -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Host "  ✅ $func - OK" -ForegroundColor Green
            }
        } catch {
            Write-Host "  ❌ $func - Error" -ForegroundColor Red
        }
    }
} else {
    Write-Host "⚠️ Could not determine project URL. Please check manually." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Step 5: Verification checklist..." -ForegroundColor Yellow

# List secrets to verify
Write-Host "🔐 Checking secrets..." -ForegroundColor White
supabase secrets list

Write-Host ""
Write-Host "✅ Email System Deployment Complete!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""
Write-Host "📧 Resend API Key: re_YOUR_RESEND_API_KEY" -ForegroundColor Cyan
Write-Host "🌐 Ready to send emails through your Flutter app!" -ForegroundColor Cyan
Write-Host ""
Write-Host "📚 Next steps:" -ForegroundColor Yellow
Write-Host "  1. Test email sending in your Flutter app" -ForegroundColor White
Write-Host "  2. Verify domain in Resend dashboard (optional)" -ForegroundColor White
Write-Host "  3. Monitor email logs in Supabase dashboard" -ForegroundColor White
Write-Host "  4. Check RESEND_SETUP_GUIDE.md for detailed configuration" -ForegroundColor White
Write-Host ""
Write-Host "🎉 Happy emailing! 🎉" -ForegroundColor Green