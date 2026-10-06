#!/bin/bash

# Complete deployment script for Vercel

echo "🚀 CareerBridge Flutter Web Deployment to Vercel"
echo "================================================"

# Step 1: Build the Flutter app
echo "Step 1: Building Flutter web app..."
chmod +x build.sh
./build.sh

if [ $? -ne 0 ]; then
    echo "❌ Build failed. Please check the errors above."
    exit 1
fi

# Step 2: Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "📦 Installing Vercel CLI..."
    npm install -g vercel
fi

# Step 3: Deploy to Vercel
echo "Step 2: Deploying to Vercel..."
echo "🌐 Starting deployment..."

# Deploy with production flag
vercel --prod --yes

if [ $? -eq 0 ]; then
    echo "✅ Deployment successful!"
    echo "🎉 Your Flutter app is now live on Vercel!"
    echo ""
    echo "Next steps:"
    echo "1. Check your Vercel dashboard for the deployment URL"
    echo "2. Test all features of your app"
    echo "3. Verify Supabase connection works"
    echo "4. Test authentication flow"
else
    echo "❌ Deployment failed. Please check the errors above."
    echo "💡 Try running 'vercel login' first if you haven't authenticated."
fi