-- Fix for migration_011_landing_stats.sql
-- Run this to update the get_public_stats function

-- Drop and recreate the function
DROP FUNCTION IF EXISTS get_public_stats();

CREATE OR REPLACE FUNCTION get_public_stats()
RETURNS TABLE (
    total_students BIGINT,
    total_colleges BIGINT,
    total_recruiters BIGINT,
    total_placements BIGINT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM profiles WHERE role = 'student') as total_students,
        (SELECT COUNT(*) FROM organizations WHERE type = 'Affiliated') as total_colleges,
        (SELECT COUNT(*) FROM profiles WHERE role = 'recruiter') as total_recruiters,
        -- Placements: Set to 0 since job_applications table doesn't exist yet
        0::BIGINT as total_placements;
END;
$$;

-- Grant execute to anon (public)
GRANT EXECUTE ON FUNCTION get_public_stats() TO anon, authenticated;
