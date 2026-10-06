# 🚀 Deploy CareerBridge Flutter App to Vercel - SIMPLIFIED

## 🎯 Quick Deploy (One Command)

### For Linux/Mac:
```bash
chmod +x deploy.sh && ./deploy.sh
```

### For Windows:
```powershell
.\deploy.ps1
```

## 📋 Prerequisites

1. **Flutter SDK** - [Install Flutter](https://flutter.dev/docs/get-started/install)
2. **Node.js** - [Install Node.js](https://nodejs.org/) (for Vercel CLI)
3. **Vercel Account** - [Sign up at vercel.com](https://vercel.com)

## 🔧 Manual Deployment Steps

### Step 1: Build Flutter Web App
```bash
# Linux/Mac
chmod +x build.sh && ./build.sh

# Windows
.\build.ps1
```

### Step 2: Install Vercel CLI
```bash
npm install -g vercel
```

### Step 3: Login to Vercel
```bash
vercel login
```

### Step 4: Deploy
```bash
vercel --prod
```

## ⚙️ Project Configuration

### Files Created:
- ✅ `vercel.json` - Vercel configuration
- ✅ `package.json` - Build scripts
- ✅ `build.sh` / `build.ps1` - Flutter build scripts
- ✅ `deploy.sh` / `deploy.ps1` - Complete deployment scripts

### Build Output:
- Flutter builds to: `frontend/build/web/`
- Vercel serves from: `frontend/build/web/`

## 🌐 Vercel Dashboard Configuration

### Build Settings (if using GitHub integration):
- **Framework Preset**: Other
- **Build Command**: `npm run build`
- **Output Directory**: `frontend/build/web`
- **Install Command**: `npm install`

### Environment Variables:
```
FLUTTER_WEB=true
NODE_VERSION=18
```

## 🐛 Common Issues & Solutions

### Issue 1: Flutter Not Found
```bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor
```

### Issue 2: Build Fails
```bash
cd frontend
flutter clean
flutter pub get
flutter doctor
flutter build web --release
```

### Issue 3: Vercel CLI Issues
```bash
# Reinstall Vercel CLI
npm uninstall -g vercel
npm install -g vercel@latest
vercel login
```

### Issue 4: Routing Problems
- Flutter web uses hash routing by default
- Current `vercel.json` handles both hash and clean URLs
- All routes redirect to `index.html` for SPA behavior

### Issue 5: Assets Not Loading
```bash
# Check build output
ls -la frontend/build/web/
ls -la frontend/build/web/assets/

# Rebuild if assets missing
cd frontend
flutter clean
flutter pub get
flutter build web --release --base-href /
```

## 🔐 Supabase Configuration

### Update CORS Settings:
1. Go to Supabase Dashboard → Settings → API
2. Add your Vercel URL to "Site URL"
3. Add to "Additional URLs": `https://your-app.vercel.app`

### Environment Variables (if needed):
- Supabase URL and keys are hardcoded in `main.dart`
- For production, consider using environment variables

## 📱 Testing Your Deployment

### 1. Basic Functionality
- ✅ App loads without errors
- ✅ Login screen appears
- ✅ Authentication works
- ✅ Dashboard loads after login

### 2. Feature Testing
- ✅ Student dashboard and features
- ✅ College dashboard and features
- ✅ Certification system
- ✅ Profile management
- ✅ Responsive design

### 3. Performance Testing
- ✅ Fast initial load
- ✅ Smooth navigation
- ✅ No console errors

## 🚀 Deployment Commands Reference

### Build Only:
```bash
# Linux/Mac
./build.sh

# Windows
.\build.ps1
```

### Deploy Only (after build):
```bash
vercel --prod
```

### Complete Deployment:
```bash
# Linux/Mac
./deploy.sh

# Windows
.\deploy.ps1
```

### Update Deployment:
```bash
# Make changes, then:
./deploy.sh
```

## 📊 Expected Results

After successful deployment:
- ✅ Live URL from Vercel (e.g., `https://your-app.vercel.app`)
- ✅ Flutter web app loads correctly
- ✅ Supabase authentication works
- ✅ All routes accessible
- ✅ Responsive design on mobile/desktop
- ✅ Fast loading times

## 🔗 Useful Commands

```bash
# Check Flutter installation
flutter doctor

# Check build output
ls -la frontend/build/web/

# Test locally
cd frontend/build/web && python -m http.server 8000

# Vercel logs
vercel logs

# Redeploy
vercel --prod --force
```

## 📞 Troubleshooting Checklist

If deployment fails:
- [ ] Flutter is installed and working (`flutter doctor`)
- [ ] Build completes successfully (`./build.sh`)
- [ ] Vercel CLI is installed (`vercel --version`)
- [ ] Logged into Vercel (`vercel login`)
- [ ] Build output exists (`ls frontend/build/web/`)
- [ ] No errors in Vercel logs (`vercel logs`)

## 🎉 Success!

Your CareerBridge Flutter app should now be live on Vercel! 

**Next Steps:**
1. Share your Vercel URL
2. Test all features thoroughly
3. Monitor performance and errors
4. Set up custom domain (optional)