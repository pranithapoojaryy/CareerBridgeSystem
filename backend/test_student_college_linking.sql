-- =====================================================
-- TEST STUDENT COLLEGE LINKING
-- =====================================================
-- This script tests if the student-college linking is working correctly

-- Test 1: Check if students exist in profiles table
SELECT 'TEST 1: Students in profiles table' as test_name;
SELECT 
    COUNT(*) as total_students,
    COUNT(CASE WHEN organization_id IS NOT NULL THEN 1 END) as linked_students,
    COUNT(CASE WHEN organization_id IS NULL THEN 1 END) as unlinked_students
FROM profiles 
WHERE role = 'student';

-- Test 2: Check if student_profiles records exist
SELECT 'TEST 2: Student profiles records' as test_name;
SELECT 
    COUNT(*) as total_student_profiles,
    COUNT(CASE WHEN college_id IS NOT NULL THEN 1 END) as linked_profiles,
    COUNT(CASE WHEN college_id IS NULL THEN 1 END) as unlinked_profiles
FROM student_profiles;

-- Test 3: Check data consistency between tables
SELECT 'TEST 3: Data consistency check' as test_name;
SELECT 
    COUNT(p.id) as students_in_profiles,
    COUNT(sp.id) as students_in_student_profiles,
    COUNT(CASE WHEN p.organization_id = sp.college_id THEN 1 END) as correctly_linked
FROM profiles p
LEFT JOIN student_profiles sp ON p.id = sp.id
WHERE p.role = 'student';

-- Test 4: Show sample student data (first 5 students)
SELECT 'TEST 4: Sample student data' as test_name;
SELECT 
    p.email,
    p.full_name,
    p.organization_id,
    o.name as college_name,
    sp.placement_status,
    sp.college_id,
    CASE 
        WHEN p.organization_id = sp.college_id THEN 'LINKED'
        WHEN p.organization_id IS NULL AND sp.college_id IS NULL THEN 'BOTH_NULL'
        ELSE 'MISMATCH'
    END as link_status
FROM profiles p
LEFT JOIN organizations o ON p.organization_id = o.id
LEFT JOIN student_profiles sp ON p.id = sp.id
WHERE p.role = 'student'
ORDER BY p.created_at DESC
LIMIT 5;

-- Test 5: Check if trigger is working (show trigger info)
SELECT 'TEST 5: Trigger status' as test_name;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_create_student_profile';

-- Test 6: College-wise student count
SELECT 'TEST 6: Students per college' as test_name;
SELECT 
    o.name as college_name,
    o.short_code,
    COUNT(p.id) as student_count
FROM organizations o
LEFT JOIN profiles p ON o.id = p.organization_id AND p.role = 'student'
GROUP BY o.id, o.name, o.short_code
HAVING COUNT(p.id) > 0
ORDER BY student_count DESC;

SELECT 'All tests completed!' as status;