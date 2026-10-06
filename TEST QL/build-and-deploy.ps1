# Simple PowerShell script to build Flutter web and deploy to Vercel

Write-Host "🚀 Building Flutter Web App for Vercel..." -ForegroundColor Green

# Step 1: Build Flutter Web
Write-Host "Step 1: Building Flutter web app..." -ForegroundColor Blue
Set-Location frontend

# Check if Flutter is available
if (!(Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter not found. Please install Flutter first." -ForegroundColor Red
    Write-Host "Download from: https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    exit 1
}

Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "🌐 Enabling web support..." -ForegroundColor Yellow
flutter config --enable-web

Write-Host "🏗️ Building web app..." -ForegroundColor Yellow
flutter build web --release --web-renderer html

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    Write-Host "📁 Build files are in: frontend/build/web/" -ForegroundColor Blue
} else {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

# Go back to root
Set-Location ..

# Step 2: Deploy to Vercel
Write-Host "Step 2: Deploying to Vercel..." -ForegroundColor Blue

# Check if Vercel CLI is available
if (!(Get-Command "vercel" -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Installing Vercel CLI..." -ForegroundColor Yellow
    npm install -g vercel
}

Write-Host "🚀 Deploying to Vercel..." -ForegroundColor Yellow
Set-Location frontend/build/web
vercel --prod

if ($LASTEXITCODE -eq 0) {
    Write-Host "🎉 Deployment successful!" -ForegroundColor Green
    Write-Host "Your app is now live on Vercel!" -ForegroundColor Green
} else {
    Write-Host "❌ Deployment failed. Try running 'vercel login' first." -ForegroundColor Red
}

# Go back to root
Set-Location ../../..