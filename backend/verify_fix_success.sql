-- =====================================================
-- VERIFY FIX SUCCESS
-- =====================================================
-- Quick verification that student-college linking is working

-- 1. Count students and their linking status
SELECT 
    'SUMMARY' as check_type,
    COUNT(*) as total_students,
    COUNT(CASE WHEN sp.id IS NOT NULL THEN 1 END) as students_with_profiles,
    COUNT(CASE WHEN p.organization_id IS NOT NULL THEN 1 END) as students_with_college,
    COUNT(CASE WHEN p.organization_id::text = sp.college_id THEN 1 END) as properly_linked
FROM profiles p
LEFT JOIN student_profiles sp ON p.id = sp.id
WHERE p.role = 'student';

-- 2. Show sample of properly linked students
SELECT 
    'SAMPLE_LINKED_STUDENTS' as check_type,
    p.email,
    p.full_name,
    o.name as college_name,
    sp.placement_status
FROM profiles p
JOIN student_profiles sp ON p.id = sp.id
JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student'
LIMIT 5;

-- 3. Check for any unlinked students
SELECT 
    'UNLINKED_STUDENTS' as check_type,
    COUNT(*) as count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ All students properly linked!'
        ELSE '⚠️ Some students need manual linking'
    END as status
FROM profiles p
LEFT JOIN student_profiles sp ON p.id = sp.id
WHERE p.role = 'student'
AND (p.organization_id IS NULL OR sp.college_id IS NULL OR p.organization_id::text != sp.college_id);

-- 4. Verify trigger exists
SELECT 
    'TRIGGER_STATUS' as check_type,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Trigger is active'
        ELSE '❌ Trigger missing - run fix script'
    END as status
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_create_student_profile';

-- 5. College-wise student distribution
SELECT 
    'COLLEGE_DISTRIBUTION' as check_type,
    o.name as college_name,
    COUNT(p.id) as student_count
FROM organizations o
LEFT JOIN profiles p ON o.id = p.organization_id AND p.role = 'student'
GROUP BY o.id, o.name
HAVING COUNT(p.id) > 0
ORDER BY student_count DESC;

SELECT '🎉 Verification complete! Check results above.' as final_message;