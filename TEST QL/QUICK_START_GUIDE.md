# 🚀 Quick Start Guide - CareerBridge Email System

## ✅ **What's Done:**

1. ✅ **Database**: Email tables created successfully
2. ✅ **Function**: `bright-action` exists at `https://cpjyqgsuqsihryxcwazv.supabase.co/functions/v1/bright-action`
3. ✅ **Flutter App**: Simplified and ready to run
4. ✅ **Supabase**: Connected with your credentials

## 🔧 **Fix Windows Developer Mode (Required for Flutter)**

1. Press **Windows + I** to open Settings
2. Go to **Privacy & Security** → **For developers**
3. Turn on **Developer Mode**
4. Restart your computer if prompted

**OR** run this command:
```powershell
start ms-settings:developers
```

## 📧 **Test Your Email Function (Do This First!)**

### **Step 1: Set Environment Variable**
1. Go to **Supabase Dashboard** → **Settings** → **Edge Functions** → **Environment Variables**
2. Add:
   - **Name**: `RESEND_API_KEY`
   - **Value**: `re_YOUR_RESEND_API_KEY`

### **Step 2: Update `bright-action` Function Code**
1. Go to **Edge Functions** → `bright-action`
2. **Replace ALL code** with the email sending code from `EDGE_FUNCTIONS_CODE.md` (Function 1)
3. **Click "Deploy function"**

### **Step 3: Test the Function**
1. In `bright-action` function page, click **"Invoke function"**
2. **Paste this test data:**

```json
{
  "emails": ["your-email@example.com"],
  "collegeName": "Test College",
  "inviteLink": "https://CareerBridge.app/invite?code=TEST123",
  "customMessage": "Welcome to CareerBridge! This is a test email."
}
```

3. **Click "Invoke"**
4. **Check your email inbox!** 📧

## 🎯 **Expected Result:**

You should receive a beautiful HTML email with:
- ✅ Professional gradient header
- ✅ Welcome message from "Test College"
- ✅ Your custom message
- ✅ Feature highlights
- ✅ Call-to-action button
- ✅ Professional footer

## 📱 **Run Flutter App (After Email Test Works)**

```bash
# Enable Developer Mode first!
cd frontend
flutter clean
flutter pub get
flutter run
```

## 🎉 **What You'll See in the App:**

1. **Student Management Screen** with mock data
2. **"Invite Students" button** in the top right
3. **Click it** to open the invitation dialog
4. **Enter email addresses** (one per line)
5. **Add a custom message**
6. **Click "Send Invites"**
7. **Check your email!**

## 🔍 **Verify Email Sent:**

### **Check Database:**
```sql
SELECT * FROM email_logs ORDER BY sent_at DESC LIMIT 5;
```

### **Check Resend Dashboard:**
Go to: https://resend.com/emails

## ✅ **Success Checklist:**

- [ ] Developer Mode enabled on Windows
- [ ] Environment variable `RESEND_API_KEY` set in Supabase
- [ ] `bright-action` function updated with email code
- [ ] Test email received successfully
- [ ] Flutter app runs without errors
- [ ] Invite dialog opens and works
- [ ] Emails are being sent from the app

## 🚨 **Troubleshooting:**

### **Issue: "Developer Mode required"**
**Solution**: Enable Developer Mode in Windows Settings

### **Issue: "RESEND_API_KEY not configured"**
**Solution**: Add the environment variable in Supabase Dashboard

### **Issue: "Email not received"**
**Solution**: 
- Check spam folder
- Verify Resend API key is correct
- Check Resend dashboard for delivery status

### **Issue: "Function not found"**
**Solution**: Make sure `bright-action` function is deployed

## 🎯 **Your Configuration:**

- **Supabase URL**: `https://cpjyqgsuqsihryxcwazv.supabase.co`
- **Function URL**: `https://cpjyqgsuqsihryxcwazv.supabase.co/functions/v1/bright-action`
- **Resend API Key**: `re_YOUR_RESEND_API_KEY`
- **Database**: Email tables ready

## 🎉 **You're Almost There!**

Just:
1. Enable Developer Mode
2. Test the email function
3. Run the Flutter app

**Your email system is ready to send beautiful invitations! 🚀**