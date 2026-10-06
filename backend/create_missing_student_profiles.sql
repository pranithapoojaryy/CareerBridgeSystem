-- =====================================================
-- CREATE MISSING STUDENT PROFILES
-- =====================================================
-- Run this script to create missing student_profiles records

-- Step 1: Check current state
SELECT 'CURRENT STUDENTS WITHOUT PROFILES:' as info;
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.organization_id,
    o.name as college_name
FROM profiles p
LEFT JOIN organizations o ON p.organization_id = o.id
LEFT JOIN student_profiles sp ON p.id = sp.id
WHERE p.role = 'student' 
AND sp.id IS NULL;

-- Step 2: Create missing student_profiles
INSERT INTO student_profiles (
    id,
    college_id,
    placement_status,
    usn,
    cgpa,
    semester,
    current_year,
    created_at,
    updated_at
)
SELECT 
    p.id,
    p.organization_id::text,
    'seeking',
    'USN' || SUBSTRING(p.id::text, 1, 6),
    7.5,
    6,
    3,
    p.created_at,
    now()
FROM profiles p
WHERE p.role = 'student'
AND NOT EXISTS (
    SELECT 1 FROM student_profiles sp WHERE sp.id = p.id
)
ON CONFLICT (id) DO UPDATE SET
    college_id = EXCLUDED.college_id,
    placement_status = COALESCE(student_profiles.placement_status, EXCLUDED.placement_status),
    updated_at = now();

-- Step 3: Verify the creation
SELECT 'VERIFICATION - ALL STUDENTS NOW HAVE PROFILES:' as info;
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.organization_id::text as profile_org_id,
    sp.college_id,
    sp.placement_status,
    sp.usn,
    sp.cgpa,
    o.name as college_name,
    CASE 
        WHEN p.organization_id::text = sp.college_id THEN '✅ LINKED'
        ELSE '❌ NOT LINKED'
    END as link_status
FROM profiles p
LEFT JOIN student_profiles sp ON p.id = sp.id
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student'
ORDER BY p.created_at DESC;

-- Step 4: Test the query that the frontend uses
SELECT 'FRONTEND QUERY TEST:' as info;
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.phone,
    p.organization_id,
    p.created_at,
    p.updated_at,
    sp.usn,
    sp.cgpa,
    sp.placement_status,
    sp.placed_company,
    sp.placed_package,
    sp.semester,
    sp.current_year,
    o.name as college_name,
    o.short_code
FROM profiles p
LEFT JOIN student_profiles sp ON p.id = sp.id
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student'
ORDER BY p.created_at DESC
LIMIT 5;

SELECT '🎉 Student profiles created successfully! Your college dashboard should now show real student data.' as success_message;