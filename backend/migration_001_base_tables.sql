-- =====================================================
-- MIGRATION 001: BASE TABLES AND CORE STRUCTURE
-- =====================================================
-- Run this first to establish the foundation

-- Ensure organizations table exists with all needed columns
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

-- Add missing columns to existing organizations table
ALTER TABLE public.organizations 
ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'college' CHECK (type IN ('college', 'university', 'institute')),
ADD COLUMN IF NOT EXISTS banner_url TEXT,
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS tagline TEXT,
ADD COLUMN IF NOT EXISTS primary_color TEXT DEFAULT '#6EC9F5',
ADD COLUMN IF NOT EXISTS social_links JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS state TEXT,
ADD COLUMN IF NOT EXISTS country TEXT DEFAULT 'India',
ADD COLUMN IF NOT EXISTS pincode TEXT,
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS allowed_emails_domain TEXT,
ADD COLUMN IF NOT EXISTS established_year INTEGER,
ADD COLUMN IF NOT EXISTS accreditation JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Ensure profiles table exists with enhanced structure
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

-- Add missing columns to existing profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS avatar_url TEXT,
ADD COLUMN IF NOT EXISTS profile_photo_url TEXT,
ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES public.organizations(id),
ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS profile_completion INTEGER DEFAULT 0 CHECK (profile_completion BETWEEN 0 AND 100),
ADD COLUMN IF NOT EXISTS last_active TIMESTAMP WITH TIME ZONE DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Create College Departments Table (if not exists)
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

-- Create College Programs Table (if not exists)
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

-- Create College Batches Table (if not exists)
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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_organizations_domain ON public.organizations(allowed_emails_domain);
CREATE INDEX IF NOT EXISTS idx_profiles_organization_id ON public.profiles(organization_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- Enable RLS
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.college_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.college_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.college_batches ENABLE ROW LEVEL SECURITY;

-- Basic RLS Policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "College admins can view their organization" ON public.organizations;
CREATE POLICY "College admins can view their organization" ON public.organizations
    FOR SELECT USING (
        created_by = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND organization_id = organizations.id
        )
    );

-- Add update trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

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

-- Success message
SELECT 'Migration 001: Base tables created successfully' as status;