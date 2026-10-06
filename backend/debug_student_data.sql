-- =====================================================
-- DEBUG STUDENT DATA
-- =====================================================
-- This script helps debug why students aren't showing in college dashboard

-- 1. Check all students in profiles table
SELECT 'STUDENTS IN PROFILES TABLE:' as info;
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
SELECT 'COLLEGES IN ORGANIZATIONS TABLE:' as info;
SELECT 
    o.id,
    o.name,
    o.short_code,
    o.created_by,
    o.created_at
FROM organizations o
ORDER BY o.created_at DESC;

-- 3. Check student_profiles table
SELECT 'STUDENT PROFILES TABLE:' as info;
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
SELECT 'STUDENT-COLLEGE RELATIONSHIPS:' as info;
SELECT 
    p.email as student_email,
    p.full_name as student_name,
    p.organization_id as profile_org_id,
    o.name as college_name,
    sp.college_id as student_profile_college_id,
    sp.placement_status,
    CASE 
        WHEN p.organization_id::text = sp.college_id THEN '✅ LINKED'
        WHEN p.organization_id IS NULL THEN '❌ NO ORG ID'
        WHEN sp.college_id IS NULL THEN '❌ NO COLLEGE ID'
        ELSE '⚠️ MISMATCH'
    END as link_status
FROM profiles p
LEFT JOIN organizations o ON p.organization_id = o.id
LEFT JOIN student_profiles sp ON p.id = sp.id
WHERE p.role = 'student'
ORDER BY p.created_at DESC;

-- 5. Check what the college repository query would return
SELECT 'WHAT COLLEGE REPOSITORY SHOULD RETURN:' as info;
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.phone,
    p.organization_id,
    p.created_at,
    p.updated_at,
    jsonb_build_object(
        'usn', sp.usn,
        'cgpa', sp.cgpa,
        'placement_status', sp.placement_status,
        'placed_company', sp.placed_company,
        'placed_package', sp.placed_package,
        'semester', sp.semester,
        'current_year', sp.current_year,
        'department_id', sp.department_id,
        'program_id', sp.program_id,
        'batch_id', sp.batch_id
    ) as student_profiles,
    jsonb_build_object(
        'id', o.id,
        'name', o.name,
        'short_code', o.short_code
    ) as organizations
FROM profiles p
INNER JOIN student_profiles sp ON p.id = sp.id
INNER JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student'
ORDER BY p.created_at DESC;

-- 6. Show current user info (if you're logged in as college admin)
SELECT 'CURRENT USER INFO:' as info;
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.role,
    p.organization_id,
    o.name as college_name
FROM profiles p
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.id = auth.uid();

SELECT '🔍 Debug complete! Check the results above to identify the issue.' as final_message;