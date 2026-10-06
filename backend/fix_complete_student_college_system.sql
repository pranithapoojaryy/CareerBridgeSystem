-- =====================================================
-- COMPLETE STUDENT COLLEGE SYSTEM FIX
-- =====================================================
-- This fixes all issues: buffering, fake data, and data linking

-- Step 1: Check current state
SELECT 'CURRENT STATE ANALYSIS:' as info;

-- Check students in profiles
SELECT 'Students in profiles:' as check_type, COUNT(*) as count
FROM profiles WHERE role = 'student';

-- Check student_profiles records
SELECT 'Student profiles records:' as check_type, COUNT(*) as count
FROM student_profiles;

-- Check organizations
SELECT 'Organizations:' as check_type, COUNT(*) as count
FROM organizations;

-- Step 2: Create missing student_profiles records
-- Since college_id is TEXT and organization_id is UUID, we need to cast
INSERT INTO student_profiles (
    id,
    college_id,
    placement_status,
    created_at,
    updated_at
)
SELECT 
    p.id,
    p.organization_id::text,  -- Cast UUID to TEXT
    'seeking',
    p.created_at,
    p.updated_at
FROM profiles p
WHERE p.role = 'student'
AND NOT EXISTS (
    SELECT 1 FROM student_profiles sp WHERE sp.id = p.id
)
ON CONFLICT (id) DO UPDATE SET
    college_id = EXCLUDED.college_id,
    updated_at = EXCLUDED.updated_at;

-- Step 3: Update existing student_profiles with correct college_id
UPDATE student_profiles 
SET college_id = (
    SELECT organization_id::text 
    FROM profiles 
    WHERE profiles.id = student_profiles.id
),
updated_at = now()
WHERE EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = student_profiles.id 
    AND profiles.role = 'student'
    AND profiles.organization_id IS NOT NULL
);

-- Step 4: Create trigger for future students
CREATE OR REPLACE FUNCTION create_student_profile()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.role = 'student' THEN
        INSERT INTO student_profiles (
            id,
            college_id,
            placement_status,
            created_at,
            updated_at
        ) VALUES (
            NEW.id,
            NEW.organization_id::text,  -- Cast UUID to TEXT
            'seeking',
            NEW.created_at,
            NEW.updated_at
        )
        ON CONFLICT (id) DO UPDATE SET
            college_id = NEW.organization_id::text,
            updated_at = NEW.updated_at;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS trigger_create_student_profile ON profiles;
CREATE TRIGGER trigger_create_student_profile
    AFTER INSERT OR UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION create_student_profile();

-- Step 5: Verify the fix worked
SELECT 'VERIFICATION RESULTS:' as info;

-- Show linked students
SELECT 
    'LINKED STUDENTS:' as result_type,
    p.email,
    p.full_name,
    p.organization_id::text as profile_org_id,
    sp.college_id as student_profile_college_id,
    o.name as college_name,
    sp.placement_status,
    CASE 
        WHEN p.organization_id::text = sp.college_id THEN '✅ PROPERLY LINKED'
        ELSE '❌ STILL NOT LINKED'
    END as status
FROM profiles p
INNER JOIN student_profiles sp ON p.id = sp.id
INNER JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student'
ORDER BY p.created_at DESC;

-- Show summary stats
SELECT 
    'SUMMARY STATS:' as result_type,
    COUNT(p.id) as total_students,
    COUNT(sp.id) as students_with_profiles,
    COUNT(CASE WHEN p.organization_id::text = sp.college_id THEN 1 END) as properly_linked,
    COUNT(o.id) as students_with_colleges
FROM profiles p
LEFT JOIN student_profiles sp ON p.id = sp.id
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student';

-- Step 6: Test the exact query that the college repository uses
SELECT 'COLLEGE REPOSITORY TEST QUERY:' as info;
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

SELECT '🎉 Complete student college system fix completed!' as final_message;