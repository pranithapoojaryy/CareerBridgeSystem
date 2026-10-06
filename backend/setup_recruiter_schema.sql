-- Create companies table
CREATE TABLE IF NOT EXISTS public.companies (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    website TEXT,
    industry TEXT,
    logo_url TEXT,
    description TEXT,
    address TEXT,
    domain TEXT, -- Extracted from website or email for verification
    created_by UUID REFERENCES auth.users(id), -- Added for RLS
    is_verified BOOLEAN DEFAULT FALSE,
    verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    trust_score INT DEFAULT 10 CHECK (trust_score BETWEEN 0 AND 100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Ensure created_by column exists (handle case where table already existed)
ALTER TABLE public.companies ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- Create recruiters table (Profile linked to auth.users)
CREATE TABLE IF NOT EXISTS public.recruiters (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL,
    full_name TEXT, -- Can be triggered from raw_user_meta_data
    job_title TEXT,
    phone TEXT,
    linkedin_url TEXT,
    is_primary_contact BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recruiters ENABLE ROW LEVEL SECURITY;

-- Policies for companies
-- 1. Recruiters can view their own company (or one they created)
DROP POLICY IF EXISTS "Recruiters can view their own company" ON public.companies;
CREATE POLICY "Recruiters can view their own company" ON public.companies
    FOR SELECT
    USING (
        id IN (SELECT company_id FROM public.recruiters WHERE id = auth.uid())
        OR created_by = auth.uid()
    );

-- 2. Recruiters can update their own company
DROP POLICY IF EXISTS "Recruiters can update their own company" ON public.companies;
CREATE POLICY "Recruiters can update their own company" ON public.companies
    FOR UPDATE
    USING (
        id IN (SELECT company_id FROM public.recruiters WHERE id = auth.uid())
        OR created_by = auth.uid()
    );

-- 3. Authenticated users can create companies
DROP POLICY IF EXISTS "Authenticated users can create companies" ON public.companies;
CREATE POLICY "Authenticated users can create companies" ON public.companies
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Policies for recruiters
-- 1. Users can view own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.recruiters;
CREATE POLICY "Users can view own profile" ON public.recruiters
    FOR SELECT
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.recruiters;
CREATE POLICY "Users can update own profile" ON public.recruiters
    FOR UPDATE
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.recruiters;
CREATE POLICY "Users can insert own profile" ON public.recruiters
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Trigger to update 'updated_at'
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_companies_updated_at ON public.companies;
CREATE TRIGGER update_companies_updated_at
    BEFORE UPDATE ON public.companies
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_recruiters_updated_at ON public.recruiters;
CREATE TRIGGER update_recruiters_updated_at
    BEFORE UPDATE ON public.recruiters
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();
