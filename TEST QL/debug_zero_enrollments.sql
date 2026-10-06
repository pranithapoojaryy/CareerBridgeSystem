-- Debug: Why Are Enrollments Showing 0?

-- Step 1: Check if you're logged in and get your info
SELECT 
  auth.uid() as my_user_id,
  p.id as profile_id,
  p.full_name,
  p.email,
  p.role,
  p.organization_id
FROM profiles p
WHERE p.id = auth.uid();

-- Step 2: Check total enrollments in database (bypassing RLS temporarily)
-- Run this to see if ANY enrollments exist
SELECT COUNT(*) as total_enrollments_in_db
FROM student_course_enrollments;

-- Step 3: Check courses owned by your organization
SELECT 
  c.id,
  c.title,
  c.provider_id,
  (SELECT organization_id FROM profiles WHERE id = auth.uid()) as my_org_id,
  CASE 
    WHEN c.provider_id = (SELECT organization_id FROM profiles WHERE id = auth.uid()) 
    THEN 'MATCH ✓' 
    ELSE 'NO MATCH ✗' 
  END as org_match
FROM learning_courses c
ORDER BY c.created_at DESC
LIMIT 10;

-- Step 4: Check enrollments that you SHOULD be able to see
SELECT 
  e.id as enrollment_id,
  c.title as course_title,
  c.provider_id as course_org,
  (SELECT organization_id FROM profiles WHERE id = auth.uid()) as my_org,
  p.full_name as student_name,
  e.enrolled_at
FROM student_course_enrollments e
JOIN learning_courses c ON e.course_id = c.id
JOIN profiles p ON e.student_id = p.id
WHERE c.provider_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
LIMIT 20;

-- Step 5: Check if RLS policies exist
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename IN ('student_course_enrollments', 'learning_courses')
ORDER BY tablename, policyname;

-- Step 6: Manually test the join that the function uses
SELECT 
  COUNT(DISTINCT e.id) as should_be_enrollment_count,
  COUNT(DISTINCT c.id) as course_count,
  (SELECT organization_id FROM profiles WHERE id = auth.uid()) as checking_for_org_id
FROM learning_courses c
LEFT JOIN student_course_enrollments e ON c.id = e.course_id
WHERE c.provider_id = (SELECT organization_id FROM profiles WHERE id = auth.uid());

-- Step 7: If still zero, check if you need to create test enrollments
-- First, let's see what students exist in your org
SELECT 
  p.id,
  p.full_name,
  p.email,
  p.role
FROM profiles p
WHERE p.organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
  AND p.role = 'student'
LIMIT 10;
