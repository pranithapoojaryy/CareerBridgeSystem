
-- Check user profiles and their roles
SELECT id, email, role, full_name, profile_completion, organization_id 
FROM profiles 
ORDER BY created_at DESC 
LIMIT 10;
