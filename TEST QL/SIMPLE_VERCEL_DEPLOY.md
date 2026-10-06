# 🚀 Simple Vercel Deployment Guide

## Step 1: Build Flutter Web App

```bash
# Navigate to frontend directory
cd frontend

# Get dependencies
flutter pub get

# Enable web support
flutter config --enable-web

# Build for web
flutter build web --release --web-renderer html
```

This creates the `build/web` folder with all the web files.

## Step 2: Deploy to Vercel

### Option A: Vercel CLI (Recommended)

```bash
# Install Vercel CLI
npm install -g vercel

# Login to Vercel
vercel login

# Go back to project root
cd ..

# Deploy the build folder
vercel --prod
```

### Option B: Drag & Drop (Easiest)

1. Go to [vercel.com](https://vercel.com)
2. Click "Add New" → "Project"
3. Drag and drop the `frontend/build/web` folder
4. Click "Deploy"

## Step 3: Configure Vercel (if needed)

If using CLI, Vercel will ask:
- **Set up and deploy?** → Yes
- **Which scope?** → Your account
- **Link to existing project?** → No
- **Project name?** → CareerBridge-app (or any name)
- **Directory?** → `./frontend/build/web`

## That's it! 🎉

Your Flutter app will be live at the URL Vercel provides.

## Quick Commands

```bash
# Complete build and deploy
cd frontend && flutter build web --release && cd .. && vercel --prod
```

## Troubleshooting

### Build fails?
```bash
cd frontend
flutter clean
flutter pub get
flutter doctor
flutter build web --release
```

### Vercel issues?
```bash
vercel login
vercel --prod --force
```

### App doesn't load?
- Check browser console for errors
- Verify Supabase URL in `main.dart`
- Test locally: `cd frontend/build/web && python -m http.server 8000`