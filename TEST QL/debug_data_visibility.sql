-- Diagnostic Script: Check for ID Mismatches and Data Visibility
-- Run this in Supabase SQL Editor to see what the database actually contains relative to your user.

SELECT '--- USER INFO ---' as section;
SELECT 
    id as user_id, 
    email, 
    role, 
    organization_id 
FROM profiles 
WHERE id = auth.uid();

SELECT '--- COURSES (Raw Check) ---' as section;
-- List courses and who "provides" them. 
-- Valid courses should have provider_id equal to your organization_id above.
SELECT 
    id as course_id, 
    title, 
    provider_id 
FROM learning_courses;

SELECT '--- ENROLLMENTS (Raw Check) ---' as section;
SELECT count(*) as total_enrollments FROM student_course_enrollments;

SELECT '--- ENROLLMENTS (Detailed) ---' as section;
SELECT 
    e.id, 
    e.student_id, 
    e.course_id, 
    c.title as course_title, 
    c.provider_id
FROM student_course_enrollments e
JOIN learning_courses c ON e.course_id = c.id;

-- If 'provider_id' column doesn't match 'organization_id' from USER INFO,
-- that explains why Analytics shows 0.
