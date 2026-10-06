# Deploy CareerBridge to Vercel - Quick Guide

## ✅ Build Complete!
Your Flutter web app has been built successfully in `frontend/build/web`

## Deploy Now - Choose One Method:

### Method 1: Vercel Dashboard (Recommended - Easiest)

1. **Go to [vercel.com](https://vercel.com)** and sign in with GitHub

2. **Click "Add New Project"** → **Import Git Repository**

3. **Select `CareerBridge`** repository

4. **Configure:**
   - **Root Directory:** `frontend`
   - **Framework Preset:** Other
   - Leave build settings as default (vercel.json will handle it)

5. **Environment Variables** (IMPORTANT):
   ```
   SUPABASE_URL = your_supabase_project_url
   SUPABASE_ANON_KEY = your_supabase_anon_key
   ```

6. **Click Deploy** 🚀

---

### Method 2: Vercel CLI (For Advanced Users)

```bash
# Install Vercel CLI globally
npm install -g vercel

# Navigate to frontend
cd frontend

# Login to Vercel
vercel login

# Deploy
vercel --prod
```

---

## After Deployment

1. **Test your live site** at the Vercel URL
2. **Add custom domain** (optional) in Project Settings
3. **Enable automatic deployments** from GitHub (already enabled by default)

## Troubleshooting

**Build fails?**
- Push the updated `vercel.json` to GitHub first
- Check Vercel build logs for errors

**App loads but shows errors?**
- Verify environment variables are set in Vercel dashboard
- Check browser console for Supabase connection errors

**Need to redeploy?**
- Just push to GitHub - Vercel auto-deploys!
- Or run `vercel --prod` again

---

## Files Ready for Deployment
- ✅ `build/web` - Production build
- ✅ `vercel.json` - Deployment config
- ✅ `.vercelignore` - Optimized deployment

**Next:** Push updated files to GitHub, then deploy via Vercel dashboard!
