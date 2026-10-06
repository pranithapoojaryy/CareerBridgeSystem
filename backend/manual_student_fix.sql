-- =====================================================
-- MANUAL STUDENT FIX
-- =====================================================
-- This manually creates student_profiles for existing students

-- First, let's see what we have
SELECT 'CURRENT PROFILES:' as info;
SELECT id, email, full_name, role, organization_id FROM profiles WHERE role = 'student';

SELECT 'CURRENT STUDENT_PROFILES:' as info;
SELECT * FROM student_profiles;

-- Create student_profiles for any student that doesn't have one
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
    7.5, -- Default CGPA
    6,   -- Default semester
    3,   -- Default year
    p.created_at,
    now()
FROM profiles p
WHERE p.role = 'student'
AND NOT EXISTS (
    SELECT 1 FROM student_profiles sp WHERE sp.id = p.id
)
ON CONFLICT (id) DO UPDATE SET
    college_id = EXCLUDED.college_id,
    updated_at = now();

-- Verify the fix
SELECT 'VERIFICATION:' as info;
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.organization_id::text as profile_org_id,
    sp.college_id,
    sp.placement_status,
    sp.usn,
    sp.cgpa,
    CASE 
        WHEN p.organization_id::text = sp.college_id THEN '✅ LINKED'
        ELSE '❌ NOT LINKED'
    END as status
FROM profiles p
LEFT JOIN student_profiles sp ON p.id = sp.id
WHERE p.role = 'student'
ORDER BY p.created_at DESC;

SELECT '✅ Manual fix completed!' as result;