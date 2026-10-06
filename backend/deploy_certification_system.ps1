# Deploy Certification System to Supabase
# This script deploys the database migration and Edge Function

Write-Host "🚀 Deploying Certification System..." -ForegroundColor Green

# Check if Supabase CLI is installed
if (!(Get-Command "supabase" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Supabase CLI not found. Please install it first:" -ForegroundColor Red
    Write-Host "npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

# Check if we're in the right directory
if (!(Test-Path "supabase")) {
    Write-Host "❌ supabase directory not found. Please run this from the backend directory." -ForegroundColor Red
    exit 1
}

Write-Host "📊 Step 1: Deploying database migration..." -ForegroundColor Blue
try {
    # Apply the certification system migration
    supabase db push
    Write-Host "✅ Database migration deployed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Database migration failed: $_" -ForegroundColor Red
    Write-Host "💡 Try running the migration manually in Supabase SQL Editor" -ForegroundColor Yellow
}

Write-Host "🔧 Step 2: Deploying Edge Function..." -ForegroundColor Blue
try {
    # Deploy the validate-certificate function
    supabase functions deploy validate-certificate
    Write-Host "✅ Edge Function deployed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Edge Function deployment failed: $_" -ForegroundColor Red
    Write-Host "💡 Make sure you're logged in: supabase login" -ForegroundColor Yellow
}

Write-Host "🔐 Step 3: Setting up function permissions..." -ForegroundColor Blue
Write-Host "Please run this SQL in your Supabase SQL Editor:" -ForegroundColor Yellow
Write-Host @"
-- Grant permissions for the Edge Function
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON public.certification_providers TO anon, authenticated;
GRANT SELECT ON public.skills_database TO anon, authenticated;
GRANT ALL ON public.student_certifications TO authenticated;
GRANT ALL ON public.student_skills TO authenticated;
"@ -ForegroundColor Cyan

Write-Host "✅ Certification system deployment complete!" -ForegroundColor Green
Write-Host "🔗 Your Edge Function URL: https://[your-project-id].supabase.co/functions/v1/validate-certificate" -ForegroundColor Blue
Write-Host "📝 Don't forget to update your environment variables if needed." -ForegroundColor Yellow