-- ==========================================
-- FIX: Link Profiles to Organizations
-- ==========================================
-- This script fixes the issue where College Admins are not displaying
-- their College Name/Logo because their profile is not explicitly
-- linked to the organization they created.

-- 1. Update profiles to link to the organization they created
UPDATE public.profiles
SET organization_id = organizations.id
FROM public.organizations
WHERE profiles.id = organizations.created_by
AND profiles.organization_id IS NULL;

-- 2. Verify the fix
SELECT 
    p.email, 
    p.role, 
    o.name as linked_organization
FROM public.profiles p
JOIN public.organizations o ON p.organization_id = o.id
WHERE p.role IN ('admin', 'college_admin');
