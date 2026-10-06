-- FIX ENROLLMENT RLS AND CREATE ANALYTICS RPC
-- 1. Disable RLS for student_course_enrollments (Emergency Fix)
ALTER TABLE student_course_enrollments DISABLE ROW LEVEL SECURITY;

-- 2. Create RPC for reliable student count (Bypassing Dart SDK filtering issues)
CREATE OR REPLACE FUNCTION get_dashboard_student_count(org_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER -- Runs as admin
AS $$
DECLARE
    count_val INTEGER;
BEGIN
    SELECT count(*)
    INTO count_val
    FROM profiles
    WHERE organization_id = org_id
    AND role != 'college_admin'; -- Explicitly exclude admin
    
    RETURN count_val;
END;
$$;
