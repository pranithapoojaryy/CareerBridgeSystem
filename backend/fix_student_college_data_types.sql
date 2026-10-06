-- =====================================================
-- FIX STUDENT COLLEGE DATA TYPES AND LINKING
-- =====================================================
-- This script fixes data type mismatches and ensures proper linking

-- Step 1: Check current data types
SELECT 'Current data types:' as info;
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE (table_name = 'profiles' AND column_name = 'organization_id')
   OR (table_name = 'student_profiles' AND column_name = 'college_id')
   OR (table_name = 'organizations' AND column_name = 'id');

-- Step 2: Fix the college_id column type in student_profiles to match organization_id
-- First, let's see what type organization_id actually is
DO $$
DECLARE
    org_id_type text;
BEGIN
    SELECT data_type INTO org_id_type
    FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'organization_id';
    
    RAISE NOTICE 'organization_id type: %', org_id_type;
    
    -- If organization_id is UUID, we need to change college_id to UUID
    IF org_id_type = 'uuid' THEN
        -- First, clear any invalid data
        UPDATE student_profiles SET college_id = NULL WHERE college_id = '';
        
        -- Add a new UUID column
        ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS college_uuid UUID;
        
        -- Convert existing valid college_id values to UUID
        UPDATE student_profiles 
        SET college_uuid = college_id::uuid 
        WHERE college_id IS NOT NULL 
        AND college_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
        
        -- Drop the old column and rename the new one
        ALTER TABLE student_profiles DROP COLUMN IF EXISTS college_id;
        ALTER TABLE student_profiles RENAME COLUMN college_uuid TO college_id;
        
        -- Add foreign key constraint
        ALTER TABLE student_profiles 
        ADD CONSTRAINT fk_student_profiles_college_id 
        FOREIGN KEY (college_id) REFERENCES organizations(id);
        
        RAISE NOTICE 'Fixed college_id to UUID type';
    END IF;
END $$;

-- Step 3: Now create student_profiles records for students who don't have them
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

SELECT 'Student college data linking with proper data types completed successfully!' as status;