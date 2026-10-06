-- =====================================================
-- TEST FRONTEND QUERY
-- =====================================================
-- This tests the exact query structure the frontend expects

-- Test the query that matches the frontend repository structure
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.phone,
    p.organization_id,
    p.created_at,
    p.updated_at,
    -- Student profiles as nested object (like the frontend expects)
    CASE 
        WHEN sp.id IS NOT NULL THEN
            json_build_object(
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
            )
        ELSE null
    END as student_profiles,
    -- Organizations as nested object
    CASE 
        WHEN o.id IS NOT NULL THEN
            json_build_object(
                'id', o.id,
                'name', o.name,
                'short_code', o.short_code
            )
        ELSE null
    END as organizations
FROM profiles p
LEFT JOIN student_profiles sp ON p.id = sp.id
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student'
ORDER BY p.created_at DESC;

-- Test student stats calculation
SELECT 'STUDENT STATS TEST:' as info;
SELECT 
    COUNT(p.id) as total_students,
    COUNT(CASE WHEN sp.placement_status = 'placed' THEN 1 END) as placed_students,
    ROUND(AVG(COALESCE(sp.cgpa, 0)), 2) as average_cgpa,
    ROUND(AVG(COALESCE(p.profile_completion, 0))) as average_completion,
    COUNT(CASE WHEN COALESCE(sp.placement_status, 'seeking') != 'not_interested' THEN 1 END) as active_students,
    CASE 
        WHEN COUNT(p.id) > 0 THEN 
            ROUND((COUNT(CASE WHEN sp.placement_status = 'placed' THEN 1 END) * 100.0 / COUNT(p.id)), 0)
        ELSE 0 
    END as placement_rate
FROM profiles p
LEFT JOIN student_profiles sp ON p.id = sp.id
WHERE p.role = 'student';

SELECT '✅ Frontend query test completed!' as result;