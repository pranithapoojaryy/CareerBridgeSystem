-- FIX MISSING ORGANIZATION SCRIPT
-- 1. Create the missing 'Organization' that the courses belong to.
-- 2. Link your User Profile to that Organization.

-- Step 1: Insert missing organization
INSERT INTO public.organizations (id, name, type, description)
VALUES (
  '6984606b-f491-40cb-9984-696ee22ef86d', -- The ID from your course data
  'CareerBridge Academy',
  'college',
  'Default organization for imported courses'
)
ON CONFLICT (id) DO NOTHING;

-- Step 2: Link your user to this organization
UPDATE public.profiles
SET 
  organization_id = '6984606b-f491-40cb-9984-696ee22ef86d',
  role = 'college'
WHERE id = 'd2cd996e-9ead-40d4-8465-13f39e706633';

-- Step 3: Verify results
SELECT 
  p.email, 
  o.name as organization_name, 
  p.role 
FROM public.profiles p
JOIN public.organizations o ON p.organization_id = o.id
WHERE p.id = 'd2cd996e-9ead-40d4-8465-13f39e706633';
