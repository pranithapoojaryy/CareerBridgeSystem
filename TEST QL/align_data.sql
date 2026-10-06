-- ALIGN DATA SCRIPT
-- This script fixes the mismatch between your User Profile and the Course Data.

-- 1. Get the Provider ID from one of your valid courses (e.g., 'CareerBridge')
-- 2. Update your User Profile to match that Organization ID.
-- 3. Ensure your role is set to 'college' so you can see the dashboard.

UPDATE profiles
SET 
  organization_id = (
    SELECT provider_id 
    FROM learning_courses 
    WHERE title = 'CareerBridge' 
    LIMIT 1
  ),
  role = 'college' -- Force role to college just in case
WHERE id = auth.uid();

-- Verify the fix
SELECT 
  'Fix Applied' as status,
  id as user_id, 
  organization_id as new_org_id,
  (SELECT provider_id FROM learning_courses WHERE title = 'CareerBridge' LIMIT 1) as course_provider_id
FROM profiles
WHERE id = auth.uid();
