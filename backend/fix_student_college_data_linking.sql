-- =====================================================
-- FIX STUDENT COLLEGE DATA LINKING
-- =====================================================
-- This script fixes the issue where students register but don't appear in college dashboard

-- Step 1: Check current state of student data
SELECT 'Current student data in profiles table:' as info;
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

-- Step 2: Check if student_profiles records exist
SELECT 'Current student_profiles records:' as info;
SELECT COUNT(*) as student_profiles_count FROM student_profiles;

-- Step 3: Create student_profiles records for students who don't have them
INSERT INTO student_profiles (
    id,
    college_id,
    placement_status,
    created_at,
    updated_at
)
SELECT 
    p.id,
    p.organization_id,
    'seeking',
    p.created_at,
    p.updated_at
FROM profiles p
WHERE p.role = 'student'
AND NOT EXISTS (
    SELECT 1 FROM student_profiles sp WHERE sp.id = p.id
)
ON CONFLICT (id) DO NOTHING;

-- Step 4: Update college_id in student_profiles for existing records
UPDATE student_profiles 
SET college_id = (
    SELECT organization_id 
    FROM profiles 
    WHERE profiles.id = student_profiles.id
)
WHERE college_id IS NULL
AND EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = student_profiles.id 
    AND profiles.organization_id IS NOT NULL
);

-- Step 5: Link students to colleges based on email domain if organization_id is null
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

-- Step 6: Update student_profiles with the newly linked college_id
UPDATE student_profiles 
SET college_id = (
    SELECT organization_id 
    FROM profiles 
    WHERE profiles.id = student_profiles.id
)
WHERE college_id IS NULL
AND EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = student_profiles.id 
    AND profiles.organization_id IS NOT NULL
);

-- Step 7: Create a trigger to automatically create student_profiles when a student registers
CREATE OR REPLACE FUNCTION create_student_profile()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create student_profile for students
    IF NEW.role = 'student' THEN
        INSERT INTO student_profiles (
            id,
            college_id,
            placement_status,
            created_at,
            updated_at
        ) VALUES (
            NEW.id,
            NEW.organization_id,
            'seeking',
            NEW.created_at,
            NEW.updated_at
        )
        ON CONFLICT (id) DO UPDATE SET
            college_id = NEW.organization_id,
            updated_at = NEW.updated_at;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_create_student_profile ON profiles;

-- Create the trigger
CREATE TRIGGER trigger_create_student_profile
    AFTER INSERT OR UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION create_student_profile();

-- Step 8: Show final results
SELECT 'Final student data after fixes:' as info;
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.role,
    p.organization_id,
    o.name as college_name,
    sp.placement_status,
    sp.college_id as student_profile_college_id
FROM profiles p 
LEFT JOIN organizations o ON p.organization_id = o.id
LEFT JOIN student_profiles sp ON p.id = sp.id
WHERE p.role = 'student'
ORDER BY p.created_at DESC;

SELECT 'Student college data linking completed successfully!' as status;