# Profile Photo and College Info Fixes

## Issues Fixed

### 1. Profile Photo Upload Error (StorageException 403)
**Problem**: `StorageException(message: new row violates row-level security policy, statusCode: 403,error: Unauthorized)`

**Root Cause**: The ImageService was uploading files to path `profiles/$fileName` but RLS policies expected `$userId/$fileName`

**Solution**: 
- Updated `ImageService.uploadProfilePhoto()` to use correct path format: `$userId/$fileName`
- Fixed `deleteOldPhoto()` method to handle the correct URL path structure
- Removed unnecessary `dart:typed_data` import

**Files Modified**:
- `frontend/lib/core/services/image_service.dart`

### 2. College Info Not Loading
**Problem**: Organization ID and Department ID showing as "None" in debug info

**Root Cause**: Students not properly linked to their colleges in the database

**Solution**:
- Added debug logging to `_loadStudentProfile()` method
- Created SQL scripts to automatically link students to colleges based on email domain
- Added comprehensive error handling and logging

**Files Modified**:
- `frontend/lib/features/student/presentation/student_dashboard_screen.dart`

**SQL Scripts Created**:
- `backend/fix_storage_only.sql` - Fixes only the storage/photo upload issue
- `backend/fix_student_college_simple.sql` - Interactive script to link students to colleges
- `backend/fix_all_issues.sql` - Comprehensive fix for all issues

### 3. RangeError: Index out of range
**Problem**: `RangeError (index): Index out of range: index should be less than 1: 1`

**Root Cause**: Sidebar has 24 menu items (indices 0-23) but dashboard `_screens` array only has 23 items. When clicking logout (index 23), it tried to access non-existent screen.

**Solution**:
- Added bounds checking in dashboard screen navigation
- Changed `_screens[_selectedIndex]` to `_selectedIndex < _screens.length ? _screens[_selectedIndex] : _screens[0]`

**Files Modified**:
- `frontend/lib/features/student/presentation/student_dashboard_screen.dart`

## How to Apply Fixes

### Option 1: Fix Storage Issue Only (Recommended First)
Run this to fix profile photo uploads immediately:

```sql
-- Run this in your Supabase SQL editor
\i backend/fix_storage_only.sql
```

### Option 2: Interactive College Linking
Run this to see colleges and students, then manually link them:

```sql
-- Run this in your Supabase SQL editor
\i backend/fix_student_college_simple.sql
```

This script will:
1. Show all colleges in your database
2. Show students that need to be linked
3. Try automatic linking based on email domain
4. Provide examples for manual linking

### Option 3: Complete Fix (If Email Domains Are Set)
Only run this if your colleges have `allowed_emails_domain` set:

```sql
-- Run this in your Supabase SQL editor
\i backend/fix_all_issues.sql
```

## Database Schema Note

The organizations table uses `allowed_emails_domain` (not `email_domain`) for the email domain field. Make sure your colleges have this field populated for automatic student linking to work.

## Manual Student Linking

If automatic linking doesn't work, you can manually link students:

```sql
-- Get college ID
SELECT id, name FROM organizations WHERE type = 'college';

-- Link specific student to college
UPDATE profiles 
SET organization_id = 'your-college-id-here'
WHERE email = 'student@example.com' AND role = 'student';

-- Link all students from a domain to a college
UPDATE profiles 
SET organization_id = 'your-college-id-here'
WHERE email LIKE '%@yourdomain.com' AND role = 'student';
```

## Verification Steps

After running the fixes:

1. **Profile Photo Upload**: Try uploading a profile photo - should work without 403 errors
2. **College Info**: Check if college name displays instead of "Your College"
3. **Navigation**: Verify no RangeError when clicking sidebar items

## Debug Information

The student dashboard now includes comprehensive logging to help diagnose issues:
- User ID logging
- Profile data logging
- Organization loading status
- College info loading confirmation

Check your browser console or app logs for detailed information about what's happening during profile loading.

## Storage Bucket Structure

Profile photos are now stored as:
```
profile_photos/
  ├── {user_id_1}/
  │   ├── profile_123456789.jpg
  │   └── profile_987654321.jpg
  └── {user_id_2}/
      └── profile_555666777.jpg
```

This structure ensures RLS policies work correctly and users can only access their own photos.