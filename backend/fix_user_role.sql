-- Fix User Roles and Test Visibility
-- 1. Ensure all 'Student' (case variants) are normalized to 'student'
-- This fixes the RLS policy failure which strictly asserts role = 'student'.
UPDATE public.profiles
SET role = 'student'
WHERE role ILIKE 'student' AND role != 'student';

-- 2. Verify and Active Tests
-- Ensure all aptitude tests are active (just in case)
UPDATE public.aptitude_tests
SET is_active = true
WHERE is_active = false;

-- 3. Debug Output: Show me my current user details (run this in SQL Editor)
-- This helps verify who you are logged in as.
SELECT id, email, role FROM public.profiles WHERE id = auth.uid();

-- 4. Debug Output: Check tests visible to me now
SELECT 
    ta.id, 
    ta.assignment_type, 
    ta.test_id, 
    t.title,
    t.is_active
FROM public.test_assignments ta
JOIN public.aptitude_tests t ON ta.test_id = t.id
WHERE ta.assignment_type = 'all_students';
