# Test CareerBridge Email System
# This script tests all email functions to ensure they're working correctly

Write-Host "🧪 Testing CareerBridge Email System" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Get project details
$projectUrl = supabase status | Select-String "API URL" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
$anonKey = supabase status | Select-String "anon key" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }

if (-not $projectUrl -or -not $anonKey) {
    Write-Host "❌ Could not get project details. Make sure you're in a Supabase project directory." -ForegroundColor Red
    exit 1
}

Write-Host "🌐 Project URL: $projectUrl" -ForegroundColor Green
Write-Host "🔑 Using anon key: $($anonKey.Substring(0,20))..." -ForegroundColor Green
Write-Host ""

# Test email address
$testEmail = Read-Host "Enter test email address"

if (-not $testEmail -or $testEmail -notmatch "^[^@]+@[^@]+\.[^@]+$") {
    Write-Host "❌ Please enter a valid email address." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📧 Testing email functions with: $testEmail" -ForegroundColor Yellow
Write-Host ""

# Test 1: Student Invitations
Write-Host "🎓 Test 1: Student Invitation Email..." -ForegroundColor Cyan

$invitePayload = @{
    emails = @($testEmail)
    collegeName = "Test College"
    inviteLink = "https://CareerBridge.app/invite?code=TEST123"
    customMessage = "This is a test invitation from the CareerBridge email system!"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$projectUrl/functions/v1/send-student-invites" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $anonKey"
            "Content-Type" = "application/json"
        } `
        -Body $invitePayload `
        -TimeoutSec 30

    if ($response.success) {
        Write-Host "  ✅ Student invitation sent successfully!" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Failed: $($response.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Seconds 2

# Test 2: Bulk Message
Write-Host "💬 Test 2: Bulk Message Email..." -ForegroundColor Cyan

$bulkPayload = @{
    emails = @($testEmail)
    subject = "Test Bulk Message from CareerBridge"
    message = "This is a test bulk message to verify the email system is working correctly. If you receive this, everything is set up properly!"
    senderName = "CareerBridge Test System"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$projectUrl/functions/v1/send-bulk-message" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $anonKey"
            "Content-Type" = "application/json"
        } `
        -Body $bulkPayload `
        -TimeoutSec 30

    if ($response.success) {
        Write-Host "  ✅ Bulk message sent successfully!" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Failed: $($response.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Seconds 2

# Test 3: Assessment Notification
Write-Host "📝 Test 3: Assessment Notification Email..." -ForegroundColor Cyan

$assessmentPayload = @{
    students = @(@{
        email = $testEmail
        full_name = "Test Student"
    })
    assessmentTitle = "Sample Programming Assessment"
    assessmentLink = "https://CareerBridge.app/assessment/test123"
    deadline = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ssZ")
    collegeName = "Test College"
} | ConvertTo-Json -Depth 3

try {
    $response = Invoke-RestMethod -Uri "$projectUrl/functions/v1/send-assessment-notification" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $anonKey"
            "Content-Type" = "application/json"
        } `
        -Body $assessmentPayload `
        -TimeoutSec 30

    if ($response.success) {
        Write-Host "  ✅ Assessment notification sent successfully!" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Failed: $($response.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Seconds 2

# Test 4: Event Invitation
Write-Host "🎉 Test 4: Event Invitation Email..." -ForegroundColor Cyan

$eventPayload = @{
    students = @(@{
        email = $testEmail
        full_name = "Test Student"
    })
    eventTitle = "Tech Hackathon 2024"
    eventDetails = "Join us for an exciting 48-hour hackathon where you'll build innovative solutions and compete for amazing prizes!"
    registrationLink = "https://CareerBridge.app/events/hackathon2024/register"
    eventDate = (Get-Date).AddDays(14).ToString("yyyy-MM-ddTHH:mm:ssZ")
    collegeName = "Test College"
} | ConvertTo-Json -Depth 3

try {
    $response = Invoke-RestMethod -Uri "$projectUrl/functions/v1/send-event-invitation" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $anonKey"
            "Content-Type" = "application/json"
        } `
        -Body $eventPayload `
        -TimeoutSec 30

    if ($response.success) {
        Write-Host "  ✅ Event invitation sent successfully!" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Failed: $($response.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 Email System Testing Complete!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""
Write-Host "📧 Check your email inbox: $testEmail" -ForegroundColor Cyan
Write-Host "📊 You should receive 4 different test emails:" -ForegroundColor Yellow
Write-Host "  1. Student invitation with welcome message" -ForegroundColor White
Write-Host "  2. Bulk message with test content" -ForegroundColor White
Write-Host "  3. Assessment notification with deadline" -ForegroundColor White
Write-Host "  4. Event invitation for hackathon" -ForegroundColor White
Write-Host ""
Write-Host "📈 Monitor email delivery in:" -ForegroundColor Yellow
Write-Host "  • Resend Dashboard: https://resend.com/emails" -ForegroundColor White
Write-Host "  • Supabase Logs: supabase functions logs" -ForegroundColor White
Write-Host ""
Write-Host "✅ If you received all emails, your system is ready for production!" -ForegroundColor Green