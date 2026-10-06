-- =====================================================
-- DEBUG COLLEGE STUDENT ISSUE
-- =====================================================
-- This script helps identify why students aren't showing up in college dashboard

-- 1. Check all students in the system
SELECT '1. ALL STUDENTS IN SYSTEM:' as step;
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.role,
    p.organization_id,
    p.created_at
FROM profiles p
WHERE p.role = 'student'
ORDER BY p.created_at DESC;

-- 2. Check all organizations (colleges)
SELECT '2. ALL COLLEGES IN SYSTEM:' as step;
SELECT 
    o.id,
    o.name,
    o.short_code,
    o.created_by,
    o.created_at
FROM organizations o
ORDER BY o.created_at DESC;

-- 3. Check student_profiles table
SELECT '3. ALL STUDENT PROFILES:' as step;
SELECT 
    sp.id,
    sp.college_id,
    sp.placement_status,
    sp.usn,
    sp.cgpa,
    sp.created_at
FROM student_profiles sp
ORDER BY sp.created_at DESC;

-- 4. Check the relationship between students and colleges
SELECT '4. STUDENT-COLLEGE RELATIONSHIPS:' as step;
SELECT 
    p.id as student_id,
    p.email,
    p.full_name,
    p.organization_id as student_org_id,
    o.id as college_id,
    o.name as college_name,
    sp.college_id as profile_college_id,
    CASE 
        WHEN p.organization_id = o.id THEN '✅ PROFILE LINKED TO ORG'
        ELSE '❌ PROFILE NOT LINKED TO ORG'
    END as profile_org_link,
    CASE 
        WHEN p.organization_id::text = sp.college_id THEN '✅ PROFILE COLLEGE MATCHES'
        ELSE '❌ PROFILE COLLEGE MISMATCH'
    END as profile_college_link,
    CASE 
        WHEN sp.id IS NOT NULL THEN '✅ HAS STUDENT PROFILE'
        ELSE '❌ NO STUDENT PROFILE'
    END as has_profile
FROM profiles p
LEFT JOIN organizations o ON p.organization_id = o.id
LEFT JOIN student_profiles sp ON p.id = sp.id
WHERE p.role = 'student'
ORDER BY p.created_at DESC;

-- 5. Check data types to identify UUID vs TEXT issues
SELECT '5. DATA TYPE ANALYSIS:' as step;
SELECT 
    'profiles.organization_id' as field,
    pg_typeof(organization_id) as data_type
FROM profiles 
WHERE role = 'student' 
LIMIT 1;

SELECT 
    'student_profiles.college_id' as field,
    pg_typeof(college_id) as data_type
FROM student_profiles 
LIMIT 1;

-- 6. Count students per college
SELECT '6. STUDENTS PER COLLEGE:' as step;
SELECT 
    o.name as college_name,
    o.id as college_id,
    COUNT(p.id) as total_students,
    COUNT(sp.id) as students_with_profiles
FROM organizations o
LEFT JOIN profiles p ON p.organization_id = o.id AND p.role = 'student'
LEFT JOIN student_profiles sp ON p.id = sp.id
GROUP BY o.id, o.name
ORDER BY total_students DESC;

SELECT '🔍 Debug analysis complete! Check the results above to identify the issue.' as final_message;