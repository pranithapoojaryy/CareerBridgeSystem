-- SIMPLE FIX: Set Your Organization ID

-- Step 1: Check your current profile
SELECT 
  id,
  email,
  full_name,
  role,
  organization_id,
  CASE 
    WHEN organization_id IS NULL THEN '❌ MISSING'
    ELSE '✅ SET'
  END as status
FROM profiles
WHERE id = auth.uid();

-- Step 2: Find your organization
-- Option A: By organization name
SELECT id, name, short_code, type
FROM organizations
ORDER BY created_at DESC;

-- Option B: If you created the courses, find org from your courses
SELECT DISTINCT
  c.provider_id as created_by_user_id,
  p.organization_id as their_org_id,
  o.name as org_name
FROM learning_courses c
LEFT JOIN profiles p ON c.provider_id = p.id
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE c.provider_id = auth.uid();

-- Step 3: UPDATE YOUR PROFILE (Choose ONE of these)

-- Option 1: If you know your organization name (e.g., "Poornaprajna")
UPDATE profiles
SET organization_id = (SELECT id FROM organizations WHERE name LIKE '%Poornaprajna%' LIMIT 1)
WHERE id = auth.uid();

-- Option 2: If you know the exact organization ID
-- UPDATE profiles
-- SET organization_id = 'PASTE_ORG_UUID_HERE'
-- WHERE id = auth.uid();

-- Option 3: Use the first/only organization in the system
-- UPDATE profiles
-- SET organization_id = (SELECT id FROM organizations ORDER BY created_at LIMIT 1)
-- WHERE id = auth.uid();

-- Step 4: Verify the fix
SELECT 
  p.id,
  p.email,
  p.full_name,
  p.role,
  p.organization_id,
  o.name as organization_name,
  o.short_code
FROM profiles p
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.id = auth.uid();

-- Step 5: Test if you can now see courses
SELECT 
  COUNT(*) as my_courses
FROM learning_courses c
JOIN profiles my_profile ON my_profile.id = auth.uid()
WHERE c.provider_id IN (
  SELECT id FROM profiles WHERE organization_id = my_profile.organization_id
);

-- Step 6: Test if you can see enrollments
SELECT 
  COUNT(*) as enrollments_visible
FROM student_course_enrollments e
JOIN learning_courses c ON e.course_id = c.id
JOIN profiles faculty ON faculty.id = auth.uid()
JOIN profiles course_creator ON c.provider_id = course_creator.id
WHERE course_creator.organization_id = faculty.organization_id;

-- Step 7: Re-run analytics
SELECT * FROM get_course_enrollment_stats(
  (SELECT organization_id FROM profiles WHERE id = auth.uid())
);
