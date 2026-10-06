-- =====================================================
-- CHECK DATA TYPES FOR STUDENT-COLLEGE LINKING
-- =====================================================

-- Check the data types of relevant columns
SELECT 'Column data types:' as info;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('profiles', 'student_profiles', 'organizations')
AND column_name IN ('id', 'organization_id', 'college_id')
ORDER BY table_name, column_name;

-- Check if there are any existing records to understand the data
SELECT 'Sample data from profiles:' as info;
SELECT 
    id,
    email,
    role,
    organization_id,
    pg_typeof(organization_id) as org_id_type
FROM profiles 
WHERE role = 'student'
LIMIT 3;

SELECT 'Sample data from organizations:' as info;
SELECT 
    id,
    name,
    pg_typeof(id) as id_type
FROM organizations 
LIMIT 3;

SELECT 'Sample data from student_profiles:' as info;
SELECT 
    id,
    college_id,
    pg_typeof(college_id) as college_id_type
FROM student_profiles 
LIMIT 3;