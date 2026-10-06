-- ================================================================
-- FIX: Recruiter Registration Crash
-- ================================================================
-- Problem: The handle_new_user trigger inserts type='company' into
-- organizations table, but the CHECK constraint only allows:
-- 'college', 'university', 'institute'
-- This causes the trigger to fail, which crashes recruiter signup.
--
-- Run this in Supabase SQL Editor to fix.
-- ================================================================

-- Fix 1: Update the organizations table type CHECK constraint to also allow 'company'
ALTER TABLE public.organizations
  DROP CONSTRAINT IF EXISTS organizations_type_check;

ALTER TABLE public.organizations
  ADD CONSTRAINT organizations_type_check
  CHECK (type IN ('college', 'university', 'institute', 'company'));

-- Fix 2: Add company_size and headquarters columns if they don't exist
ALTER TABLE public.organizations
  ADD COLUMN IF NOT EXISTS company_size TEXT,
  ADD COLUMN IF NOT EXISTS headquarters TEXT;

-- Fix 3: Update the trigger to be more resilient (handle missing columns)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_org_id uuid;
  v_role text;
  v_company_name text;
  v_short_code text;
BEGIN
  v_role := new.raw_user_meta_data ->> 'role';

  -- For recruiters, create an organization first
  IF v_role = 'recruiter' THEN
    v_company_name := COALESCE(new.raw_user_meta_data ->> 'company_name', 'Company');
    -- Build short_code safely
    v_short_code := UPPER(SUBSTRING(REPLACE(v_company_name, ' ', ''), 1, 6));
    IF v_short_code = '' THEN v_short_code := 'ORG'; END IF;

    BEGIN
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
        v_company_name,
        v_short_code,
        'company',  -- now valid after constraint fix above
        COALESCE(new.raw_user_meta_data ->> 'industry', 'Technology'),
        new.raw_user_meta_data ->> 'company_size',
        new.raw_user_meta_data ->> 'company_location',
        new.raw_user_meta_data ->> 'company_website',
        'Company profile for ' || v_company_name,
        new.id
      )
      RETURNING id INTO v_org_id;
    EXCEPTION WHEN OTHERS THEN
      -- If org creation fails, continue without it
      RAISE WARNING 'Could not create organization for recruiter %: %', new.id, SQLERRM;
      v_org_id := NULL;
    END;

    -- Create profile with organization link
    BEGIN
      INSERT INTO public.profiles (
        id,
        email,
        role,
        full_name,
        phone,
        organization_id,
        job_title
      )
      VALUES (
        new.id,
        new.email,
        v_role,
        new.raw_user_meta_data ->> 'full_name',
        new.raw_user_meta_data ->> 'phone',
        v_org_id,
        new.raw_user_meta_data ->> 'designation'
      )
      ON CONFLICT (id) DO UPDATE SET
        organization_id = COALESCE(EXCLUDED.organization_id, profiles.organization_id),
        job_title = COALESCE(EXCLUDED.job_title, profiles.job_title),
        updated_at = NOW();
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Could not create profile for recruiter %: %', new.id, SQLERRM;
    END;

  ELSE
    -- For non-recruiters, create profile normally
    BEGIN
      INSERT INTO public.profiles (id, email, role, full_name)
      VALUES (
        new.id,
        new.email,
        v_role,
        new.raw_user_meta_data ->> 'full_name'
      )
      ON CONFLICT (id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Could not create profile for user %: %', new.id, SQLERRM;
    END;
  END IF;

  RETURN new;
END;
$$;

-- Fix 4: Recreate the trigger (ensure it's attached)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Fix 5: Allow authenticated users to insert into organizations (needed for Flutter fallback)
DROP POLICY IF EXISTS "Recruiters can insert organizations" ON public.organizations;
CREATE POLICY "Recruiters can insert organizations" ON public.organizations
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Fix 6: Fix any existing recruiters who got stuck without a profile
-- (Run this to fix users who tried to register before this patch)
DO $$
DECLARE
  u RECORD;
  v_org_id uuid;
  v_company_name text;
  v_short_code text;
BEGIN
  FOR u IN
    SELECT au.id, au.email, au.raw_user_meta_data
    FROM auth.users au
    LEFT JOIN public.profiles p ON p.id = au.id
    WHERE (au.raw_user_meta_data ->> 'role') = 'recruiter'
      AND p.id IS NULL
  LOOP
    v_company_name := COALESCE(u.raw_user_meta_data ->> 'company_name', 'Company');
    v_short_code := UPPER(SUBSTRING(REPLACE(v_company_name, ' ', ''), 1, 6));
    IF v_short_code = '' THEN v_short_code := 'ORG'; END IF;

    -- Try creating org
    BEGIN
      INSERT INTO public.organizations (name, short_code, type, industry, company_size, headquarters, website, description, created_by)
      VALUES (
        v_company_name, v_short_code, 'company',
        COALESCE(u.raw_user_meta_data ->> 'industry', 'Technology'),
        u.raw_user_meta_data ->> 'company_size',
        u.raw_user_meta_data ->> 'company_location',
        u.raw_user_meta_data ->> 'company_website',
        'Company profile for ' || v_company_name,
        u.id
      )
      RETURNING id INTO v_org_id;
    EXCEPTION WHEN OTHERS THEN
      v_org_id := NULL;
    END;

    -- Create missing profile
    BEGIN
      INSERT INTO public.profiles (id, email, role, full_name, phone, organization_id, job_title, profile_completion)
      VALUES (
        u.id, u.email, 'recruiter',
        COALESCE(u.raw_user_meta_data ->> 'full_name', 'Recruiter'),
        u.raw_user_meta_data ->> 'phone',
        v_org_id,
        u.raw_user_meta_data ->> 'designation',
        30
      )
      ON CONFLICT (id) DO NOTHING;
      RAISE NOTICE 'Fixed missing profile for recruiter: %', u.email;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Could not fix profile for %: %', u.email, SQLERRM;
    END;
  END LOOP;
END $$;

-- Verify fix
SELECT
  au.email,
  au.raw_user_meta_data ->> 'role' AS role,
  p.id AS profile_id,
  p.organization_id,
  o.name AS org_name
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
LEFT JOIN public.organizations o ON o.id = p.organization_id
WHERE (au.raw_user_meta_data ->> 'role') = 'recruiter'
ORDER BY au.created_at DESC;
