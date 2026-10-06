-- =====================================================
-- MIGRATION: FIX ADMIN ACCESS & DELETION
-- Purpose: 
-- 1. robust deletion of tests (cascading).
-- 2. allow college admins to view student attempts (bypass RLS).
-- =====================================================

-- 1. RPC for Cascading Deletion
CREATE OR REPLACE FUNCTION public.delete_aptitude_test(p_test_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Delete Attempts
    DELETE FROM public.aptitude_attempts WHERE test_id = p_test_id;
    
    -- Delete Assignments
    DELETE FROM public.test_assignments WHERE test_id = p_test_id;
    
    -- Delete Questions (linked via new column)
    DELETE FROM public.aptitude_questions WHERE linked_test_id = p_test_id;
    
    -- Delete Questions (legacy tag based - cleanup)
    -- Optional: Only if we are sure they are not reused. 
    -- For now, `linked_test_id` handles the new ones.
    
    -- Delete Test
    DELETE FROM public.aptitude_tests WHERE id = p_test_id;
END;
$$;

-- 2. RPC for Fetching Attempts (Admin View)
-- Joins with profiles automatically to return clean data
CREATE OR REPLACE FUNCTION public.get_test_attempts_admin(p_test_id UUID)
RETURNS TABLE (
    id UUID,
    student_id UUID,
    score NUMERIC,
    status TEXT,
    created_at TIMESTAMPTZ,
    student_name TEXT,
    student_email TEXT,
    student_avatar TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.student_id,
        a.score,
        a.status::TEXT,
        a.created_at,
        p.full_name AS student_name,
        p.email AS student_email,
        p.avatar_url AS student_avatar
    FROM public.aptitude_attempts a
    LEFT JOIN public.profiles p ON a.student_id = p.id
    WHERE a.test_id = p_test_id
    ORDER BY a.created_at DESC;
END;
$$;
