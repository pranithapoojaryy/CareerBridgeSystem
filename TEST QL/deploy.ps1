# PowerShell Complete deployment script for Vercel

Write-Host "🚀 CareerBridge Flutter Web Deployment to Vercel" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Step 1: Build the Flutter app
Write-Host "Step 1: Building Flutter web app..." -ForegroundColor Blue
.\build.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed. Please check the errors above." -ForegroundColor Red
    exit 1
}

# Step 2: Check if Vercel CLI is installed
if (!(Get-Command "vercel" -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Installing Vercel CLI..." -ForegroundColor Yellow
    npm install -g vercel
}

# Step 3: Deploy to Vercel
Write-Host "Step 2: Deploying to Vercel..." -ForegroundColor Blue
Write-Host "🌐 Starting deployment..." -ForegroundColor Blue

# Deploy with production flag
vercel --prod --yes

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Deployment successful!" -ForegroundColor Green
    Write-Host "🎉 Your Flutter app is now live on Vercel!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Check your Vercel dashboard for the deployment URL" -ForegroundColor White
    Write-Host "2. Test all features of your app" -ForegroundColor White
    Write-Host "3. Verify Supabase connection works" -ForegroundColor White
    Write-Host "4. Test authentication flow" -ForegroundColor White
} else {
    Write-Host "❌ Deployment failed. Please check the errors above." -ForegroundColor Red
    Write-Host "💡 Try running 'vercel login' first if you haven't authenticated." -ForegroundColor Yellow
}