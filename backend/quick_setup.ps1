# Quick Setup Script for CareerBridge Email System
# This script handles the most common setup issues

Write-Host "🚀 CareerBridge Email System Quick Setup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Check prerequisites
Write-Host ""
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow

# Check Supabase CLI
try {
    $supabaseVersion = supabase --version
    Write-Host "✅ Supabase CLI: $supabaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Supabase CLI not found. Install with: npm install -g supabase" -ForegroundColor Red
    exit 1
}

# Check if linked to project
try {
    $status = supabase status 2>$null
    if ($status -match "Local project not linked") {
        Write-Host "⚠️ Project not linked. Please run: supabase link --project-ref YOUR_PROJECT_REF" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✅ Project linked" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not check project status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🗄️ Setting up database..." -ForegroundColor Yellow

# Run database migration
Write-Host "📊 Running email system migration..." -ForegroundColor White
try {
    supabase db push
    Write-Host "✅ Database migration completed" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Database migration failed. Trying alternative method..." -ForegroundColor Yellow
    
    # Try running the SQL file directly
    try {
        supabase db reset --linked
        Write-Host "✅ Database reset and migration completed" -ForegroundColor Green
    } catch {
        Write-Host "❌ Database setup failed. Please run migration manually in Supabase SQL Editor" -ForegroundColor Red
        Write-Host "   File: migration_005_email_system.sql" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "🔐 Setting up secrets..." -ForegroundColor Yellow

# Set up Supabase secrets
$secrets = @{
    "RESEND_API_KEY" = "re_YOUR_RESEND_API_KEY"
    "EMAIL_FROM_DOMAIN" = "CareerBridge.app"
    "EMAIL_FROM_NAME" = "CareerBridge"
    "APP_URL" = "https://CareerBridge.app"
}

foreach ($secret in $secrets.GetEnumerator()) {
    try {
        supabase secrets set "$($secret.Key)=$($secret.Value)"
        Write-Host "✅ Set $($secret.Key)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to set $($secret.Key)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📧 Deploying Edge Functions..." -ForegroundColor Yellow

# Deploy functions
$functions = @(
    "send-student-invites",
    "send-bulk-message",
    "send-assessment-notification",
    "send-event-invitation"
)

foreach ($func in $functions) {
    try {
        supabase functions deploy $func --no-verify-jwt
        Write-Host "✅ Deployed $func" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to deploy $func" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "🧪 Testing setup..." -ForegroundColor Yellow

# Get project URL for testing
try {
    $projectUrl = supabase status | Select-String "API URL" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
    
    if ($projectUrl) {
        Write-Host "🌐 Project URL: $projectUrl" -ForegroundColor Green
        
        # Test each function endpoint
        foreach ($func in $functions) {
            try {
                $response = Invoke-WebRequest -Uri "$projectUrl/functions/v1/$func" -Method OPTIONS -TimeoutSec 5 -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    Write-Host "✅ $func endpoint responding" -ForegroundColor Green
                } else {
                    Write-Host "⚠️ $func endpoint issue (Status: $($response.StatusCode))" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "❌ $func endpoint not accessible" -ForegroundColor Red
            }
        }
    }
} catch {
    Write-Host "⚠️ Could not test endpoints" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Setup Summary" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan

# List current secrets
Write-Host "🔐 Current secrets:" -ForegroundColor White
try {
    supabase secrets list
} catch {
    Write-Host "Could not list secrets" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Quick setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📚 Next steps:" -ForegroundColor Yellow
Write-Host "  1. Test email sending: .\test_email_system.ps1" -ForegroundColor White
Write-Host "  2. Update Flutter app with your Supabase credentials" -ForegroundColor White
Write-Host "  3. Run Flutter app and test email features" -ForegroundColor White
Write-Host ""
Write-Host "📧 Resend API Key: re_YOUR_RESEND_API_KEY" -ForegroundColor Cyan
Write-Host "🌐 Monitor emails at: https://resend.com/emails" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎉 Ready to send emails! 🎉" -ForegroundColor Green