-- =====================================================
-- CAREERBRIDGE HIRE - STEP 1: BASE TABLES
-- =====================================================
-- Run this FIRST in your Supabase SQL Editor

BEGIN;

-- =====================================================
-- 1. ORGANIZATIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.organizations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT DEFAULT 'college' CHECK (type IN ('college', 'university', 'institute')),
    website TEXT,
    logo_url TEXT,
    banner_url TEXT,
    description TEXT,
    tagline TEXT,
    primary_color TEXT DEFAULT '#6EC9F5',
    social_links JSONB DEFAULT '{}'::jsonb,
    address TEXT,
    city TEXT,
    state TEXT,
    country TEXT DEFAULT 'India',
    pincode TEXT,
    phone TEXT,
    email TEXT,
    allowed_emails_domain TEXT,
    established_year INTEGER,
    accreditation JSONB DEFAULT '[]'::jsonb,
    created_by UUID REFERENCES auth.users(id),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add missing columns to existing organizations table (if it exists)
DO $$ 
BEGIN
    -- Add columns one by one to handle existing table
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN type TEXT DEFAULT 'college';
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN banner_url TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN tagline TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN primary_color TEXT DEFAULT '#6EC9F5';
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN social_links JSONB DEFAULT '{}'::jsonb;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN address TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN city TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN state TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN country TEXT DEFAULT 'India';
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN pincode TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN phone TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN email TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN allowed_emails_domain TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN established_year INTEGER;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN accreditation JSONB DEFAULT '[]'::jsonb;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN created_by UUID REFERENCES auth.users(id);
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.organizations ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
END $$;

-- =====================================================
-- 2. PROFILES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('student', 'college', 'college_admin', 'recruiter', 'HR', 'admin')),
    full_name TEXT,
    phone TEXT,
    avatar_url TEXT,
    organization_id UUID REFERENCES public.organizations(id),
    is_verified BOOLEAN DEFAULT FALSE,
    profile_completion INTEGER DEFAULT 0 CHECK (profile_completion BETWEEN 0 AND 100),
    last_active TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add missing columns to existing profiles table (if it exists)
DO $$ 
BEGIN
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN phone TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN avatar_url TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN organization_id UUID REFERENCES public.organizations(id);
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN profile_completion INTEGER DEFAULT 0;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN last_active TIMESTAMP WITH TIME ZONE DEFAULT now();
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
END $$;

-- =====================================================
-- 3. COLLEGE STRUCTURE TABLES
-- =====================================================

-- College Departments
CREATE TABLE IF NOT EXISTS public.college_departments (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL,
    name TEXT NOT NULL,
    code TEXT,
    head_of_dept_name TEXT,
    contact_email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    CONSTRAINT college_departments_pkey PRIMARY KEY (id),
    CONSTRAINT college_departments_org_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE
);

-- College Programs
CREATE TABLE IF NOT EXISTS public.college_programs (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    dept_id UUID NOT NULL,
    name TEXT NOT NULL,
    type TEXT,
    duration_years INTEGER DEFAULT 2,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    CONSTRAINT college_programs_pkey PRIMARY KEY (id),
    CONSTRAINT college_programs_dept_fkey FOREIGN KEY (dept_id) REFERENCES public.college_departments(id) ON DELETE CASCADE
);

-- College Batches
CREATE TABLE IF NOT EXISTS public.college_batches (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    program_id UUID NOT NULL,
    name TEXT NOT NULL,
    start_year INTEGER,
    end_year INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    CONSTRAINT college_batches_pkey PRIMARY KEY (id),
    CONSTRAINT college_batches_program_fkey FOREIGN KEY (program_id) REFERENCES public.college_programs(id) ON DELETE CASCADE
);

-- =====================================================
-- 4. CREATE BASIC INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_organizations_domain ON public.organizations(allowed_emails_domain);
CREATE INDEX IF NOT EXISTS idx_profiles_organization_id ON public.profiles(organization_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_college_departments_org_id ON public.college_departments(org_id);
CREATE INDEX IF NOT EXISTS idx_college_programs_dept_id ON public.college_programs(dept_id);
CREATE INDEX IF NOT EXISTS idx_college_batches_program_id ON public.college_batches(program_id);

-- =====================================================
-- 5. ENABLE RLS ON BASE TABLES
-- =====================================================

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.college_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.college_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.college_batches ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 6. CREATE BASIC POLICIES (SIMPLE ONES ONLY)
-- =====================================================

-- Profiles - basic policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Organizations - basic read policy
DROP POLICY IF EXISTS "Users can view organizations" ON public.organizations;
CREATE POLICY "Users can view organizations" ON public.organizations
    FOR SELECT USING (true); -- Allow reading for now, will restrict later

-- College structure - basic read policies
DROP POLICY IF EXISTS "Users can view departments" ON public.college_departments;
CREATE POLICY "Users can view departments" ON public.college_departments
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can view programs" ON public.college_programs;
CREATE POLICY "Users can view programs" ON public.college_programs
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can view batches" ON public.college_batches;
CREATE POLICY "Users can view batches" ON public.college_batches
    FOR SELECT USING (true);

-- =====================================================
-- 7. CREATE UPDATE FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add basic update triggers
DROP TRIGGER IF EXISTS update_organizations_updated_at ON public.organizations;
CREATE TRIGGER update_organizations_updated_at
    BEFORE UPDATE ON public.organizations
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

COMMIT;

-- Success message
SELECT 'Step 1 Complete: Base tables created successfully! ✅' as status,
       'Now run setup_step_2_features.sql' as next_step;