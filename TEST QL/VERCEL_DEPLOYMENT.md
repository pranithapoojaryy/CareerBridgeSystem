# CareerBridge - Vercel Deployment Guide

## Quick Deploy (Recommended)

### Option 1: Vercel Dashboard (Easiest)

1. **Go to [vercel.com](https://vercel.com)** and sign in with GitHub

2. **Click "Add New Project"**

3. **Import your GitHub repository:**
   - Select `CareerBridge` repository
   - Click "Import"

4. **Configure Project:**
   - **Framework Preset:** Other
   - **Root Directory:** `frontend`
   - **Build Command:** `flutter build web --release --web-renderer canvaskit`
   - **Output Directory:** `build/web`
   - **Install Command:** (leave default or use the one from vercel.json)

5. **Add Environment Variables:**
   - Click "Environment Variables"
   - Add:
     - `SUPABASE_URL` = your Supabase project URL
     - `SUPABASE_ANON_KEY` = your Supabase anon key

6. **Click "Deploy"**

### Option 2: Vercel CLI

```bash
# Install Vercel CLI
npm i -g vercel

# Navigate to frontend directory
cd frontend

# Deploy
vercel

# Follow prompts:
# - Link to existing project or create new
# - Confirm settings
# - Deploy!
```

## Post-Deployment

1. **Test your deployment:**
   - Visit the Vercel URL
   - Test login/signup
   - Verify Supabase connection

2. **Custom Domain (Optional):**
   - Go to Project Settings → Domains
   - Add your custom domain

## Troubleshooting

**Build fails:**
- Check Flutter version compatibility
- Verify `pubspec.yaml` dependencies
- Check Vercel build logs

**Blank page:**
- Verify `vercel.json` rewrites are correct
- Check browser console for errors
- Ensure environment variables are set

**Supabase connection fails:**
- Verify environment variables in Vercel dashboard
- Check Supabase URL and anon key are correct
- Ensure Supabase project is active

## Files Created
- ✅ `vercel.json` - Deployment configuration
- ✅ `.vercelignore` - Exclude unnecessary files

## Next Steps
Push these files to GitHub and deploy!
