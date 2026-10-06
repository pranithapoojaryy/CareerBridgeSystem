# 🚀 How to Make CareerBridge Email System Functional

## 📋 Prerequisites

Before starting, ensure you have:
- ✅ Supabase project created
- ✅ Flutter development environment set up
- ✅ Supabase CLI installed
- ✅ Resend API key: `re_YOUR_RESEND_API_KEY`

## 🗄️ Step 1: Set Up Database

### 1.1 Run Database Migrations

```bash
# Navigate to backend directory
cd backend

# Connect to your Supabase project (if not already connected)
supabase login
supabase link --project-ref YOUR_PROJECT_REF

# Run the email system migration
supabase db push
```

Or manually run the migration:

```sql
-- In Supabase SQL Editor, run:
\i migration_005_email_system.sql
```

### 1.2 Verify Database Setup

```sql
-- Check if email tables were created
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'email_logs',
    'invite_codes', 
    'invite_code_usage',
    'communication_templates',
    'student_communications',
    'email_preferences'
);
```

## 🔧 Step 2: Configure Supabase Environment

### 2.1 Set Environment Variables

**Option A: Using Supabase CLI**
```bash
# Set the Resend API key
supabase secrets set RESEND_API_KEY=re_YOUR_RESEND_API_KEY

# Set email configuration
supabase secrets set EMAIL_FROM_DOMAIN=CareerBridge.app
supabase secrets set EMAIL_FROM_NAME=CareerBridge
supabase secrets set APP_URL=https://CareerBridge.app

# Verify secrets
supabase secrets list
```

**Option B: Using PowerShell Script**
```powershell
.\setup_supabase_secrets.ps1
```

**Option C: Supabase Dashboard**
1. Go to your Supabase project dashboard
2. Navigate to **Settings** → **Edge Functions**
3. Add environment variables:
   - `RESEND_API_KEY`: `re_YOUR_RESEND_API_KEY`
   - `EMAIL_FROM_DOMAIN`: `CareerBridge.app`
   - `EMAIL_FROM_NAME`: `CareerBridge`

## 📧 Step 3: Deploy Edge Functions

### 3.1 Deploy All Email Functions

```bash
# Deploy student invitation function
supabase functions deploy send-student-invites

# Deploy bulk message function
supabase functions deploy send-bulk-message

# Deploy assessment notification function
supabase functions deploy send-assessment-notification

# Deploy event invitation function
supabase functions deploy send-event-invitation
```

### 3.2 Verify Function Deployment

```bash
# List deployed functions
supabase functions list

# Test function endpoints
supabase functions serve
```

## 📱 Step 4: Configure Flutter App

### 4.1 Update Dependencies

Add to `frontend/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  flutter_riverpod: ^2.4.0
  google_fonts: ^6.1.0
  http: ^1.1.0
```

### 4.2 Initialize Supabase in Flutter

Update `frontend/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareerBridge',
      home: const CollegeDashboardScreen(),
    );
  }
}
```

### 4.3 Update College Repository

Update `frontend/lib/features/college/data/college_repository.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class CollegeRepository {
  final SupabaseClient _supabase;
  
  CollegeRepository(this._supabase);

  // Get students with filters
  Future<List<Map<String, dynamic>>> getStudents({
    required String collegeId,
    String? department,
    String? batch,
    String? placementStatus,
    String? searchQuery,
  }) async {
    var query = _supabase
        .from('profiles')
        .select('''
          *,
          college_members!inner(college_id)
        ''')
        .eq('college_members.college_id', collegeId);

    if (department != null && department != 'All') {
      query = query.eq('department', department);
    }

    if (batch != null && batch != 'All') {
      query = query.eq('batch', batch);
    }

    if (placementStatus != null && placementStatus != 'All') {
      query = query.eq('placement_status', placementStatus);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('full_name.ilike.%$searchQuery%,email.ilike.%$searchQuery%,usn.ilike.%$searchQuery%');
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  // Get current college
  Future<Map<String, dynamic>?> getCurrentCollege() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('college_members')
        .select('colleges(*)')
        .eq('user_id', user.id)
        .single();

    return response['colleges'];
  }
}
```

## 🧪 Step 5: Test the System

### 5.1 Test Database Connection

```dart
// Test in Flutter app
void testDatabaseConnection() async {
  try {
    final response = await Supabase.instance.client
        .from('email_logs')
        .select('count')
        .count();
    print('Database connected: ${response.count}');
  } catch (e) {
    print('Database error: $e');
  }
}
```

### 5.2 Test Email Functions

**Option A: Use PowerShell Test Script**
```powershell
.\test_email_system.ps1
```

**Option B: Manual Testing**
```bash
# Test student invitation
curl -X POST 'https://YOUR_PROJECT.supabase.co/functions/v1/send-student-invites' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "emails": ["test@example.com"],
    "collegeName": "Test College",
    "inviteLink": "https://CareerBridge.app/invite?code=TEST123",
    "customMessage": "Welcome to our platform!"
  }'
```

### 5.3 Test Flutter Integration

```dart
// Test email service in Flutter
void testEmailService() async {
  final ref = ProviderContainer();
  
  try {
    await ref.read(sendStudentInvitationsProvider({
      'emails': ['test@example.com'],
      'collegeName': 'Test College',
      'inviteLink': 'https://test.com',
    }).future);
    print('Email sent successfully!');
  } catch (e) {
    print('Error: $e');
  }
}
```

## 🔧 Step 6: Fix Common Issues

### 6.1 Fix Missing StudentRepository

Update `frontend/lib/features/college/presentation/students/student_management_screen.dart`:

```dart
// Remove this line if it exists:
// final studentRepositoryProvider = Provider((ref) => StudentRepository(Supabase.instance.client));

// Replace studentsProvider with:
final studentsProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, String?>>((ref, filters) async {
  final repository = ref.watch(collegeRepositoryProvider);
  final college = await ref.watch(currentCollegeProvider.future);
  
  if (college == null) return [];
  
  return await repository.getStudents(
    collegeId: college['id'],
    department: filters['department'],
    batch: filters['batch'],
    placementStatus: filters['placementStatus'],
    searchQuery: filters['searchQuery'],
  );
});
```

### 6.2 Fix Import Issues

Ensure these imports are in your Flutter files:

```dart
// In student_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../data/college_providers.dart';
import 'widgets/student_card.dart';
import 'widgets/student_stats_panel.dart';
import 'widgets/bulk_actions_panel.dart';
import 'widgets/invite_students_dialog.dart';
import 'widgets/student_filters_panel.dart';
import 'widgets/bulk_message_dialog.dart';
```

### 6.3 Fix Provider Issues

Update `frontend/lib/features/college/data/college_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'college_repository.dart';

// College Repository Provider
final collegeRepositoryProvider = Provider<CollegeRepository>((ref) {
  return CollegeRepository(Supabase.instance.client);
});

// Current College Provider
final currentCollegeProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repository = ref.watch(collegeRepositoryProvider);
  return await repository.getCurrentCollege();
});

// Students Provider with filters
final studentsProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, String?>>((ref, filters) async {
  final repository = ref.watch(collegeRepositoryProvider);
  final college = await ref.watch(currentCollegeProvider.future);
  
  if (college == null) return [];
  
  return await repository.getStudents(
    collegeId: college['id'],
    department: filters['department'],
    batch: filters['batch'],
    placementStatus: filters['placementStatus'],
    searchQuery: filters['searchQuery'],
  );
});
```

## 🚀 Step 7: Deploy and Test

### 7.1 Complete Deployment

```powershell
# Run the complete deployment script
.\deploy_email_system.ps1
```

### 7.2 Test Everything

```powershell
# Test the complete system
.\test_email_system.ps1
```

### 7.3 Verify in Flutter App

1. Run your Flutter app
2. Navigate to Student Management
3. Try inviting students
4. Try sending bulk messages
5. Check email delivery in Resend dashboard

## 📊 Step 8: Monitor and Debug

### 8.1 Check Logs

```bash
# Check Edge Function logs
supabase functions logs send-student-invites
supabase functions logs send-bulk-message

# Check database logs
supabase logs
```

### 8.2 Monitor Email Delivery

1. Go to [Resend Dashboard](https://resend.com/emails)
2. Check email delivery status
3. Monitor bounce rates and opens

### 8.3 Debug Common Issues

**Issue: "RESEND_API_KEY not configured"**
```bash
# Check if secret is set
supabase secrets list

# Reset if needed
supabase secrets set RESEND_API_KEY=re_YOUR_RESEND_API_KEY
```

**Issue: "Function not found"**
```bash
# Redeploy functions
supabase functions deploy send-student-invites --no-verify-jwt
```

**Issue: Flutter compilation errors**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## ✅ Success Checklist

- [ ] Database migration completed
- [ ] Supabase secrets configured
- [ ] Edge Functions deployed
- [ ] Flutter dependencies updated
- [ ] Repository and providers configured
- [ ] Test emails sent successfully
- [ ] Flutter app compiles and runs
- [ ] Email system integrated in UI
- [ ] Error handling working
- [ ] Monitoring set up

## 🎉 You're Done!

Your CareerBridge email system is now fully functional! Students can be invited, bulk messages can be sent, and all email communications are tracked in the database.

**Next Steps:**
1. Customize email templates
2. Set up domain verification in Resend
3. Add more email automation features
4. Monitor usage and optimize performance