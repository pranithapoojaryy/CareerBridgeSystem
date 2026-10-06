-- Migration: Fix Existing Recruiters Without Organizations
-- This script creates organizations for existing recruiters and links them to their profiles

-- Step 1: Create organizations for recruiters who don't have one
DO $$
DECLARE
  recruiter_record RECORD;
  user_metadata jsonb;
  new_org_id uuid;
BEGIN
  -- Loop through all recruiters without an organization
  FOR recruiter_record IN 
    SELECT p.id, p.email, u.raw_user_meta_data
    FROM profiles p
    JOIN auth.users u ON p.id = u.id
    WHERE p.role = 'recruiter' 
      AND p.organization_id IS NULL
  LOOP
    user_metadata := recruiter_record.raw_user_meta_data;
    
    -- Only create organization if company_name exists in metadata
    IF user_metadata ? 'company_name' AND user_metadata->>'company_name' IS NOT NULL THEN
      -- Create organization
      INSERT INTO public.organizations (
        name,
        short_code,
        type,
        industry,
        company_size,
        headquarters,
        website,
        description,
        created_by
      )
      VALUES (
        user_metadata ->> 'company_name',
        UPPER(SUBSTRING(REPLACE(user_metadata ->> 'company_name', ' ', ''), 1, 6)),
        'company',
        COALESCE(user_metadata ->> 'industry', 'Technology'),
        COALESCE(user_metadata ->> 'company_size', '1-10'),
        user_metadata ->> 'company_location',
        user_metadata ->> 'company_website',
        'Company profile for ' || (user_metadata ->> 'company_name'),
        recruiter_record.id
      )
      RETURNING id INTO new_org_id;
      
      -- Update recruiter profile with organization link and other details
      UPDATE public.profiles
      SET 
        organization_id = new_org_id,
        phone = COALESCE(phone, user_metadata ->> 'phone'),
        job_title = COALESCE(job_title, user_metadata ->> 'designation'),
        updated_at = NOW()
      WHERE id = recruiter_record.id;
      
      RAISE NOTICE 'Created organization % for recruiter %', 
        user_metadata ->> 'company_name', 
        recruiter_record.email;
    ELSE
      RAISE NOTICE 'Skipping recruiter % - no company_name in metadata', 
        recruiter_record.email;
    END IF;
  END LOOP;
END $$;

-- Step 2: Verify the migration
SELECT 
  p.email,
  p.full_name,
  p.role,
  o.name as organization_name,
  o.type as organization_type,
  CASE 
    WHEN p.organization_id IS NULL THEN 'NOT LINKED'
    ELSE 'LINKED'
  END as status
FROM profiles p
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'recruiter'
ORDER BY p.created_at DESC;
