-- Diagnose visibility issues
-- 1. Check if the assessment is active (essential for RLS 'Students view active tests')
SELECT 
    t.id as test_id, 
    t.title, 
    t.is_active, 
    ta.assignment_type 
FROM public.test_assignments ta
JOIN public.aptitude_tests t ON ta.test_id = t.id
WHERE ta.assignment_type = 'all_students';

-- 2. Check your student profiles
-- Replace 'student' check with count to verify we have students
SELECT role, count(*) FROM public.profiles GROUP BY role;

-- 3. Check if any student profiles exist
SELECT count(*) as student_profiles_count FROM public.student_profiles;
