-- =====================================================
-- FIX SINGLE STUDENT LINKING
-- =====================================================
-- This script fixes the linking for your specific student

-- Step 1: Show current state
SELECT 'CURRENT STATE:' as info;
SELECT 
    p.email,
    p.full_name,
    p.organization_id,
    sp.college_id,
    o.name as college_name
FROM profiles p
LEFT JOIN student_profiles sp ON p.id = sp.id
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student';

-- Step 2: Create student_profiles record if missing
INSERT INTO student_profiles (
    id,
    college_id,
    placement_status,
    created_at,
    updated_at
)
SELECT 
    p.id,
    p.organization_id::text,
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
)
WHERE EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = student_profiles.id 
    AND profiles.role = 'student'
    AND profiles.organization_id IS NOT NULL
);

-- Step 4: Show final state
SELECT 'FINAL STATE:' as info;
SELECT 
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
LEFT JOIN student_profiles sp ON p.id = sp.id
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student';

-- Step 5: Create trigger if it doesn't exist
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
            NEW.organization_id::text,
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

DROP TRIGGER IF EXISTS trigger_create_student_profile ON profiles;
CREATE TRIGGER trigger_create_student_profile
    AFTER INSERT OR UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION create_student_profile();

SELECT '✅ Student linking fix completed!' as final_message;