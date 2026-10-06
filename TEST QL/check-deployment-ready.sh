#!/bin/bash

# Check if everything is ready for Vercel deployment

echo "🔍 CareerBridge Deployment Readiness Check"
echo "========================================"

# Check Flutter installation
echo "1. Checking Flutter installation..."
if command -v flutter &> /dev/null; then
    echo "   ✅ Flutter is installed"
    flutter --version | head -1
else
    echo "   ❌ Flutter is not installed"
    echo "   📥 Install from: https://flutter.dev/docs/get-started/install"
fi

# Check Node.js installation
echo "2. Checking Node.js installation..."
if command -v node &> /dev/null; then
    echo "   ✅ Node.js is installed"
    node --version
else
    echo "   ❌ Node.js is not installed"
    echo "   📥 Install from: https://nodejs.org/"
fi

# Check Vercel CLI
echo "3. Checking Vercel CLI..."
if command -v vercel &> /dev/null; then
    echo "   ✅ Vercel CLI is installed"
    vercel --version
else
    echo "   ❌ Vercel CLI is not installed"
    echo "   📥 Install with: npm install -g vercel"
fi

# Check project structure
echo "4. Checking project structure..."
if [ -d "frontend" ]; then
    echo "   ✅ Frontend directory exists"
else
    echo "   ❌ Frontend directory not found"
fi

if [ -f "frontend/pubspec.yaml" ]; then
    echo "   ✅ Flutter pubspec.yaml found"
else
    echo "   ❌ Flutter pubspec.yaml not found"
fi

if [ -f "vercel.json" ]; then
    echo "   ✅ vercel.json configuration found"
else
    echo "   ❌ vercel.json not found"
fi

if [ -f "package.json" ]; then
    echo "   ✅ package.json found"
else
    echo "   ❌ package.json not found"
fi

# Check build scripts
echo "5. Checking build scripts..."
if [ -f "build.sh" ]; then
    echo "   ✅ build.sh script found"
    if [ -x "build.sh" ]; then
        echo "   ✅ build.sh is executable"
    else
        echo "   ⚠️  build.sh needs execute permission (run: chmod +x build.sh)"
    fi
else
    echo "   ❌ build.sh not found"
fi

if [ -f "deploy.sh" ]; then
    echo "   ✅ deploy.sh script found"
    if [ -x "deploy.sh" ]; then
        echo "   ✅ deploy.sh is executable"
    else
        echo "   ⚠️  deploy.sh needs execute permission (run: chmod +x deploy.sh)"
    fi
else
    echo "   ❌ deploy.sh not found"
fi

# Test Flutter web capability
echo "6. Testing Flutter web support..."
cd frontend 2>/dev/null
if flutter config | grep -q "enable-web: true"; then
    echo "   ✅ Flutter web is enabled"
else
    echo "   ⚠️  Flutter web may need to be enabled (run: flutter config --enable-web)"
fi
cd .. 2>/dev/null

echo ""
echo "🎯 Deployment Readiness Summary:"
echo "================================"

# Count checks
total_checks=6
passed_checks=0

if command -v flutter &> /dev/null; then ((passed_checks++)); fi
if command -v node &> /dev/null; then ((passed_checks++)); fi
if command -v vercel &> /dev/null; then ((passed_checks++)); fi
if [ -d "frontend" ] && [ -f "frontend/pubspec.yaml" ]; then ((passed_checks++)); fi
if [ -f "vercel.json" ] && [ -f "package.json" ]; then ((passed_checks++)); fi
if [ -f "build.sh" ] && [ -f "deploy.sh" ]; then ((passed_checks++)); fi

echo "Passed: $passed_checks/$total_checks checks"

if [ $passed_checks -eq $total_checks ]; then
    echo "🎉 Ready for deployment! Run: ./deploy.sh"
else
    echo "⚠️  Please fix the issues above before deploying"
fi