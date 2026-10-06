#!/bin/bash

# Simple bash script to build Flutter web and deploy to Vercel

echo "🚀 Building Flutter Web App for Vercel..."

# Step 1: Build Flutter Web
echo "Step 1: Building Flutter web app..."
cd frontend

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    echo "Download from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "📦 Getting dependencies..."
flutter pub get

echo "🌐 Enabling web support..."
flutter config --enable-web

echo "🏗️ Building web app..."
flutter build web --release --web-renderer html

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📁 Build files are in: frontend/build/web/"
else
    echo "❌ Build failed!"
    exit 1
fi

# Go back to root
cd ..

# Step 2: Deploy to Vercel
echo "Step 2: Deploying to Vercel..."

# Check if Vercel CLI is available
if ! command -v vercel &> /dev/null; then
    echo "📦 Installing Vercel CLI..."
    npm install -g vercel
fi

echo "🚀 Deploying to Vercel..."
cd frontend/build/web
vercel --prod

if [ $? -eq 0 ]; then
    echo "🎉 Deployment successful!"
    echo "Your app is now live on Vercel!"
else
    echo "❌ Deployment failed. Try running 'vercel login' first."
fi

# Go back to root
cd ../../..