-- Fix: Set Organization ID for Faculty User

-- Step 1: Check your current profile (run this first)
SELECT 
  id,
  email,
  full_name,
  role,
  organization_id,
  CASE 
    WHEN organization_id IS NULL THEN '⚠️ MISSING - This is the problem!'
    ELSE '✓ Set'
  END as org_id_status
FROM profiles
WHERE id = auth.uid();

-- Step 2: Find what organization you should belong to
-- Check all organizations in the system
SELECT 
  id as organization_id,
  name as organization_name,
  type as org_type
FROM organizations
ORDER BY name;

-- Step 3: Find organization from existing courses
SELECT DISTINCT
  c.provider_id as organization_id,
  o.name as organization_name
FROM learning_courses c
LEFT JOIN organizations o ON c.provider_id = o.id
WHERE c.provider_id IS NOT NULL
LIMIT 10;

-- Step 4: Update your profile with the correct organization_id
-- REPLACE 'YOUR_ORG_ID_HERE' with actual organization ID from Step 2 or 3
UPDATE profiles
SET organization_id = 'YOUR_ORG_ID_HERE'  -- ⚠️ REPLACE THIS
WHERE id = auth.uid();

-- Example: If your organization is "Poornaprajna Institute of Management"
-- First find its ID:
SELECT id, name FROM organizations WHERE name LIKE '%Poornaprajna%';

-- Then update (using the actual UUID):
-- UPDATE profiles
-- SET organization_id = (SELECT id FROM organizations WHERE name LIKE '%Poornaprajna%')
-- WHERE id = auth.uid();

-- Step 5: Verify the update worked
SELECT 
  id,
  email,
  full_name,
  role,
  organization_id,
  (SELECT name FROM organizations WHERE id = profiles.organization_id) as org_name
FROM profiles
WHERE id = auth.uid();

-- Step 6: Test if you can now see courses
SELECT 
  COUNT(*) as courses_i_can_see
FROM learning_courses
WHERE provider_id = (SELECT organization_id FROM profiles WHERE id = auth.uid());

-- Step 7: Test if you can now see enrollments
SELECT 
  COUNT(*) as enrollments_i_can_see
FROM student_course_enrollments e
JOIN learning_courses c ON e.course_id = c.id
WHERE c.provider_id = (SELECT organization_id FROM profiles WHERE id = auth.uid());

-- Step 8: Re-run the analytics function
SELECT * FROM get_course_enrollment_stats(
  (SELECT organization_id FROM profiles WHERE id = auth.uid())
);
