-- Migration 011: Public Landing Page Stats & Feed
-- DATE: 2025-12-30
-- AUTHOR: Antigravity

-- 1. Function to get platform statistics (Public Access)
CREATE OR REPLACE FUNCTION get_public_stats()
RETURNS TABLE (
    total_students BIGINT,
    total_colleges BIGINT,
    total_recruiters BIGINT,
    total_placements BIGINT
) 
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with CAREERBRIDGEd privileges to count users
AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM profiles WHERE role = 'student') as total_students,
        (SELECT COUNT(*) FROM organizations WHERE type = 'college') as total_colleges,
        (SELECT COUNT(*) FROM profiles WHERE role = 'recruiter') as total_recruiters,
        -- Simulating placements for now as we don't have a direct 'placements' table linking confirmed hires yet
        -- In a real scenario, this would count distinct students in 'job_applications' with status 'hired'
        (SELECT COUNT(*) FROM job_applications WHERE status = 'hired') as total_placements;
END;
$$;

-- Grant execute to anon (public)
GRANT EXECUTE ON FUNCTION get_public_stats() TO anon, authenticated;


-- 2. Function to get public feed glimpses (Public Access)
-- Returns simplified post data for the landing page ticker
CREATE OR REPLACE FUNCTION get_public_feed()
RETURNS TABLE (
    id UUID,
    content TEXT,
    created_at TIMESTAMPTZ,
    author_name TEXT,
    author_role TEXT,
    author_avatar TEXT,
    org_name TEXT,
    is_college_post BOOLEAN
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.content,
        p.created_at,
        prof.full_name as author_name,
        prof.role as author_role,
        COALESCE(prof.profile_photo_url, prof.avatar_url) as author_avatar,
        org.name as org_name,
        (prof.role IN ('admin', 'college_admin')) as is_college_post
    FROM posts p
    LEFT JOIN profiles prof ON p.user_id = prof.id
    LEFT JOIN organizations org ON prof.organization_id = org.id
    WHERE 
        p.is_pinned = false -- Standard posts only
    ORDER BY p.created_at DESC
    LIMIT 6;
END;
$$;

-- Grant execute to anon
GRANT EXECUTE ON FUNCTION get_public_feed() TO anon, authenticated;
