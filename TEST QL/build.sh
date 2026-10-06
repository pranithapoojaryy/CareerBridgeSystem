#!/bin/bash

# Build script for Flutter web deployment to Vercel

echo "🚀 Starting Flutter Web Build for Vercel..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Installing Flutter..."
    
    # Download and install Flutter
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    export PATH="$PATH:`pwd`/flutter/bin"
    
    # Verify installation
    flutter doctor --android-licenses || true
fi

# Navigate to frontend directory
cd frontend

echo "📦 Getting Flutter dependencies..."
flutter pub get

echo "🔧 Enabling Flutter web..."
flutter config --enable-web

echo "🏗️ Building Flutter web app..."
flutter build web --release --web-renderer html --base-href /

echo "✅ Build completed successfully!"
echo "📁 Built files are in: frontend/build/web/"

# List build contents for debugging
echo "📋 Build contents:"
ls -la build/web/

echo "🎉 Flutter web build ready for Vercel deployment!"