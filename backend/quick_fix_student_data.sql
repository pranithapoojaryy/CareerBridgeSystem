-- =====================================================
-- QUICK FIX FOR STUDENT DATA
-- =====================================================
-- This creates the missing student_profiles record immediately

-- Step 1: Show current student data
SELECT 'CURRENT STUDENT DATA:' as info;
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.role,
    p.organization_id,
    o.name as college_name
FROM profiles p
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student'
ORDER BY p.created_at DESC;

-- Step 2: Check if student_profiles exists
SELECT 'STUDENT PROFILES CHECK:' as info;
SELECT 
    sp.id,
    sp.college_id,
    sp.placement_status
FROM student_profiles sp;

-- Step 3: Create missing student_profiles records
INSERT INTO student_profiles (
    id,
    college_id,
    placement_status,
    usn,
    cgpa,
    created_at,
    updated_at
)
SELECT 
    p.id,
    p.organization_id::text,
    'seeking',
    'USN' || SUBSTRING(p.id::text, 1, 6), -- Generate a temporary USN
    0.0,
    p.created_at,
    p.updated_at
FROM profiles p
WHERE p.role = 'student'
AND NOT EXISTS (
    SELECT 1 FROM student_profiles sp WHERE sp.id = p.id
)
ON CONFLICT (id) DO UPDATE SET
    college_id = EXCLUDED.college_id,
    updated_at = now();

-- Step 4: Verify the fix
SELECT 'VERIFICATION - STUDENT WITH PROFILE:' as info;
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.organization_id::text as profile_org_id,
    sp.college_id,
    sp.placement_status,
    sp.usn,
    o.name as college_name,
    CASE 
        WHEN p.organization_id::text = sp.college_id THEN '✅ LINKED'
        ELSE '❌ NOT LINKED'
    END as status
FROM profiles p
LEFT JOIN student_profiles sp ON p.id = sp.id
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student'
ORDER BY p.created_at DESC;

-- Step 5: Test the exact query that was failing
SELECT 'TEST QUERY THAT WAS FAILING:' as info;
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
    o.name as college_name
FROM profiles p
LEFT JOIN student_profiles sp ON p.id = sp.id
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student'
AND p.organization_id = 'eb302e28-12cf-4737-87f6-f69bff28f865'  -- Your college ID from the error
ORDER BY p.created_at DESC;

SELECT '🎉 Quick fix completed! Your student should now appear in the college dashboard.' as final_message;