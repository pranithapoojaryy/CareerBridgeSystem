-- Debug script to check actual counts in database
-- Run this in Supabase SQL Editor to see what the actual counts are

-- Check students count
SELECT COUNT(*) as student_count FROM profiles WHERE role = 'student';

-- Check colleges count  
SELECT COUNT(*) as college_count FROM organizations WHERE type = 'college';

-- Check recruiters count
SELECT COUNT(*) as recruiter_count FROM profiles WHERE role = 'recruiter';

-- Check placements count
SELECT COUNT(*) as placement_count FROM job_applications WHERE status = 'hired';

-- Test the function directly
SELECT * FROM get_public_stats();
