-- =====================================================
-- FIX ALL CURRENT ISSUES
-- =====================================================
-- This script fixes profile photo RLS, student college linking, and other issues

-- 1. Fix Storage RLS Policies for profile_photos
-- Drop existing policies
DROP POLICY IF EXISTS "Users can upload their own profile photo" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile photo" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile photo" ON storage.objects;
DROP POLICY IF EXISTS "Profile photos are publicly accessible" ON storage.objects;

-- Create new policies with better path handling
CREATE POLICY "Users can upload their own profile photo" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'profile_photos' AND 
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can update their own profile photo" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'profile_photos' AND 
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete their own profile photo" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'profile_photos' AND 
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Profile photos are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'profile_photos');

-- 2. Link students to colleges based on email domain
UPDATE profiles 
SET organization_id = (
    SELECT o.id 
    FROM organizations o 
    WHERE o.allowed_emails_domain IS NOT NULL 
    AND profiles.email LIKE '%@' || o.allowed_emails_domain
    LIMIT 1
)
WHERE role = 'student' 
AND organization_id IS NULL
AND EXISTS (
    SELECT 1 
    FROM organizations o 
    WHERE o.allowed_emails_domain IS NOT NULL 
    AND profiles.email LIKE '%@' || o.allowed_emails_domain
);

-- 3. Ensure profile_photo_url column exists
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

-- 4. Show current status
SELECT 
    'Students without college:' as category,
    COUNT(*) as count
FROM profiles 
WHERE role = 'student' AND organization_id IS NULL

UNION ALL

SELECT 
    'Students with college:' as category,
    COUNT(*) as count
FROM profiles 
WHERE role = 'student' AND organization_id IS NOT NULL

UNION ALL

SELECT 
    'Total students:' as category,
    COUNT(*) as count
FROM profiles 
WHERE role = 'student';

-- 5. Show student-college mapping
SELECT 
    p.email,
    p.full_name,
    CASE 
        WHEN p.organization_id IS NOT NULL THEN o.name 
        ELSE 'No College Linked' 
    END as college_name,
    o.allowed_emails_domain
FROM profiles p 
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student'
ORDER BY p.organization_id IS NULL DESC, p.email;

SELECT 'All issues fixed successfully!' as status;