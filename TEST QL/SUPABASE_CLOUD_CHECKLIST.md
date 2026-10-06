# ✅ Supabase Cloud Setup Checklist - CareerBridge Email System

## 🎯 Quick Setup for Supabase Cloud Users

**Your Resend API Key**: `re_YOUR_RESEND_API_KEY`

---

## 📋 Step-by-Step Checklist

### ☐ **Step 1: Database Setup (5 minutes)**

1. **Open Supabase Dashboard** → Your Project
2. **Go to SQL Editor** (left sidebar)
3. **Click "New Query"**
4. **Copy & Paste** the migration from `SUPABASE_CLOUD_SETUP.md`
5. **Click "Run"** to execute
6. **Verify** tables created with this query:
   ```sql
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name LIKE '%email%' OR table_name LIKE '%invite%';
   ```

### ☐ **Step 2: Environment Variables (2 minutes)**

1. **Go to Settings** → **Edge Functions**
2. **Scroll to Environment Variables**
3. **Add these variables**:
   - `RESEND_API_KEY` = `re_YOUR_RESEND_API_KEY`
   - `EMAIL_FROM_DOMAIN` = `CareerBridge.app`
   - `EMAIL_FROM_NAME` = `CareerBridge`
   - `APP_URL` = `https://CareerBridge.app`

### ☐ **Step 3: Create Edge Functions (10 minutes)**

**For each function below:**
1. **Go to Edge Functions** → **Create new function**
2. **Enter function name**
3. **Copy code from the files**
4. **Click Deploy**

#### Function 1: `send-student-invites`
- **Name**: `send-student-invites`
- **Code**: Copy from `backend/supabase/functions/send-student-invites/index.ts`

#### Function 2: `send-bulk-message`
- **Name**: `send-bulk-message`
- **Code**: Copy from `backend/supabase/functions/send-bulk-message/index.ts`

#### Function 3: `send-assessment-notification`
- **Name**: `send-assessment-notification`
- **Code**: Copy from `backend/supabase/functions/send-assessment-notification/index.ts`

#### Function 4: `send-event-invitation`
- **Name**: `send-event-invitation`
- **Code**: Copy from `backend/supabase/functions/send-event-invitation/index.ts`

### ☐ **Step 4: Test Email System (3 minutes)**

1. **Go to Edge Functions** → `send-student-invites`
2. **Click "Invoke function"**
3. **Use this test payload**:
   ```json
   {
     "emails": ["your-email@example.com"],
     "collegeName": "Test College",
     "inviteLink": "https://CareerBridge.app/invite?code=TEST123",
     "customMessage": "This is a test invitation!"
   }
   ```
4. **Click "Invoke"**
5. **Check your email** for the invitation
6. **Check Resend Dashboard**: https://resend.com/emails

### ☐ **Step 5: Flutter App Setup (5 minutes)**

1. **Get Supabase Credentials**:
   - Go to **Settings** → **API**
   - Copy **Project URL** and **Anon public key**

2. **Update Flutter App**:
   - Edit `frontend/lib/main.dart`
   - Replace `YOUR_SUPABASE_URL` with your Project URL
   - Replace `YOUR_SUPABASE_ANON_KEY` with your Anon key

3. **Install Dependencies**:
   ```bash
   cd frontend
   flutter pub get
   ```

4. **Run App**:
   ```bash
   flutter run
   ```

### ☐ **Step 6: Verify Everything Works**

1. **Flutter app runs** without errors
2. **Student Management screen** loads
3. **Invite Students dialog** opens
4. **Can enter email addresses**
5. **Bulk message dialog** works
6. **Test emails are received**
7. **Emails logged in database**

---

## 🧪 Quick Test Commands

### Test Database
```sql
-- Check if tables exist
SELECT COUNT(*) as table_count FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('email_logs', 'invite_codes', 'communication_templates');

-- Should return table_count = 3 or more
```

### Test Email Function
```json
{
  "emails": ["test@example.com"],
  "collegeName": "Demo College",
  "inviteLink": "https://CareerBridge.app/invite?code=DEMO123",
  "customMessage": "Welcome to our platform!"
}
```

### Check Email Logs
```sql
SELECT * FROM email_logs ORDER BY sent_at DESC LIMIT 5;
```

---

## 🚨 Common Issues & Quick Fixes

### ❌ **Function deployment fails**
- **Check**: Code syntax in the function editor
- **Fix**: Copy code exactly from the provided files

### ❌ **Email not sending**
- **Check**: Environment variables are set correctly
- **Fix**: Verify `RESEND_API_KEY` = `re_YOUR_RESEND_API_KEY`

### ❌ **Flutter app crashes**
- **Check**: Supabase credentials in `main.dart`
- **Fix**: Use correct Project URL and Anon key from Settings → API

### ❌ **Database error**
- **Check**: Migration ran successfully
- **Fix**: Re-run the migration SQL in SQL Editor

### ❌ **No emails received**
- **Check**: Spam folder
- **Check**: Resend dashboard for delivery status
- **Fix**: Try with a different email address

---

## ✅ Success Indicators

You'll know everything is working when:

1. ✅ **Database migration** completes without errors
2. ✅ **All 4 functions** deploy successfully
3. ✅ **Test email** is received in your inbox
4. ✅ **Flutter app** runs and shows student management
5. ✅ **Invite dialog** accepts email addresses
6. ✅ **Email appears** in Resend dashboard
7. ✅ **Database logs** show email records

---

## 🎉 You're Done!

Once all checkboxes are complete, your CareerBridge email system is fully functional!

**Features Available**:
- 📧 Student invitation emails
- 💬 Bulk messaging
- 📝 Assessment notifications  
- 🎉 Event invitations
- 📊 Email tracking & analytics

**Ready to send professional emails to students! 🚀**

---

## 📞 Need Help?

**Quick Debug Steps**:
1. Check **Logs** tab in Edge Functions for errors
2. Verify **Environment Variables** are set
3. Test **individual functions** with Invoke button
4. Check **Resend Dashboard** for email delivery
5. Review **database logs** with SQL queries

**Your Resend API Key**: `re_YOUR_RESEND_API_KEY`