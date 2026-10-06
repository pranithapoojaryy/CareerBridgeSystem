-- Check what the college count query returns
SELECT COUNT(*) as college_count FROM organizations WHERE type = 'college';

-- Check all organizations to see what types exist
SELECT id, name, type FROM organizations ORDER BY created_at DESC;
