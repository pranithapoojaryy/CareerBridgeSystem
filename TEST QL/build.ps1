# PowerShell Build script for Flutter web deployment to Vercel

Write-Host "🚀 Starting Flutter Web Build for Vercel..." -ForegroundColor Green

# Check if Flutter is installed
if (!(Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter is not installed." -ForegroundColor Red
    Write-Host "Please install Flutter first: https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    exit 1
}

# Navigate to frontend directory
Set-Location frontend

Write-Host "📦 Getting Flutter dependencies..." -ForegroundColor Blue
flutter pub get

Write-Host "🔧 Enabling Flutter web..." -ForegroundColor Blue
flutter config --enable-web

Write-Host "🏗️ Building Flutter web app..." -ForegroundColor Blue
flutter build web --release --web-renderer html --base-href /

Write-Host "✅ Build completed successfully!" -ForegroundColor Green
Write-Host "📁 Built files are in: frontend/build/web/" -ForegroundColor Blue

# List build contents for debugging
Write-Host "📋 Build contents:" -ForegroundColor Blue
Get-ChildItem build/web/ | Format-Table Name, Length, LastWriteTime

Write-Host "🎉 Flutter web build ready for Vercel deployment!" -ForegroundColor Green