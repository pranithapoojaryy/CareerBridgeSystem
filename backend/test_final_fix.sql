-- =====================================================
-- TEST FINAL FIX
-- =====================================================
-- This tests if everything is working correctly

-- Test 1: Check if student data exists and is properly linked
SELECT 'TEST 1: Student Data Check' as test_name;
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.organization_id,
    sp.college_id,
    sp.placement_status,
    sp.usn,
    o.name as college_name,
    CASE 
        WHEN p.organization_id::text = sp.college_id THEN '✅ PROPERLY LINKED'
        ELSE '❌ NOT LINKED'
    END as link_status
FROM profiles p
LEFT JOIN student_profiles sp ON p.id = sp.id
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student'
ORDER BY p.created_at DESC;

-- Test 2: Test the exact query the college repository uses (with LEFT JOINs)
SELECT 'TEST 2: College Repository Query Test' as test_name;
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
LEFT JOIN student_profiles sp ON p.id = sp.id
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student'
ORDER BY p.created_at DESC;

-- Test 3: Test student stats query
SELECT 'TEST 3: Student Stats Query Test' as test_name;
SELECT 
    COUNT(p.id) as total_students,
    COUNT(CASE WHEN sp.placement_status = 'placed' THEN 1 END) as placed_students,
    ROUND(AVG(sp.cgpa), 2) as average_cgpa,
    ROUND(AVG(p.profile_completion)) as average_completion,
    COUNT(CASE WHEN sp.placement_status != 'not_interested' THEN 1 END) as active_students,
    CASE 
        WHEN COUNT(p.id) > 0 THEN 
            ROUND((COUNT(CASE WHEN sp.placement_status = 'placed' THEN 1 END) * 100.0 / COUNT(p.id)), 0)
        ELSE 0 
    END as placement_rate
FROM profiles p
LEFT JOIN student_profiles sp ON p.id = sp.id
WHERE p.role = 'student'
AND p.organization_id = 'eb302e28-12cf-4737-87f6-f69bff28f865'; -- Your college ID

-- Test 4: Check if trigger exists and is working
SELECT 'TEST 4: Trigger Status' as test_name;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_create_student_profile';

SELECT '🎉 All tests completed! Check the results above.' as final_message;