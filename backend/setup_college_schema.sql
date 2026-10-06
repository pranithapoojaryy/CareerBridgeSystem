-- Add branding columns to organizations table
ALTER TABLE public.organizations 
ADD COLUMN IF NOT EXISTS description text,
ADD COLUMN IF NOT EXISTS banner_url text,
ADD COLUMN IF NOT EXISTS social_links jsonb DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS primary_color text DEFAULT '#F26B3A', -- Default to App Primary
ADD COLUMN IF NOT EXISTS tagline text,
ADD COLUMN IF NOT EXISTS allowed_emails_domain text; -- For domain-based auto-linking

-- Index for domain lookup
CREATE INDEX IF NOT EXISTS idx_organizations_domain ON public.organizations(allowed_emails_domain);

-- Create College Departments Table
CREATE TABLE IF NOT EXISTS public.college_departments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL,
  name text NOT NULL, -- e.g. "Department of Computer Applications"
  code text,          -- e.g. "MCA-DEPT"
  head_of_dept_name text,
  contact_email text,
  created_at timestamp with time zone DEFAULT now(),
  
  CONSTRAINT college_departments_pkey PRIMARY KEY (id),
  CONSTRAINT college_departments_org_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE
);

-- Create College Programs Table (Courses)
CREATE TABLE IF NOT EXISTS public.college_programs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  dept_id uuid NOT NULL,
  name text NOT NULL, -- e.g. "Master of Computer Applications"
  type text,          -- e.g. "PG", "UG", "Diploma"
  duration_years integer DEFAULT 2,
  created_at timestamp with time zone DEFAULT now(),
  
  CONSTRAINT college_programs_pkey PRIMARY KEY (id),
  CONSTRAINT college_programs_dept_fkey FOREIGN KEY (dept_id) REFERENCES public.college_departments(id) ON DELETE CASCADE
);

-- Create College Batches Table
CREATE TABLE IF NOT EXISTS public.college_batches (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  program_id uuid NOT NULL,
  name text NOT NULL, -- e.g. "2023-2025"
  start_year integer,
  end_year integer,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  
  CONSTRAINT college_batches_pkey PRIMARY KEY (id),
  CONSTRAINT college_batches_program_fkey FOREIGN KEY (program_id) REFERENCES public.college_programs(id) ON DELETE CASCADE
);

-- RLS Policies (Simple for now: allow all authenticated users to read, college admin to write their own)
ALTER TABLE public.college_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.college_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.college_batches ENABLE ROW LEVEL SECURITY;

-- Policies for Departments
-- Policies for Departments
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.college_departments;
CREATE POLICY "Enable read access for authenticated users" ON public.college_departments
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Enable insert for college admins" ON public.college_departments;
CREATE POLICY "Enable insert for college admins" ON public.college_departments
FOR INSERT TO authenticated WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.organizations 
    WHERE id = college_departments.org_id AND created_by = auth.uid()
  )
);

-- Policies for Programs
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.college_programs;
CREATE POLICY "Enable read access for authenticated users" ON public.college_programs
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Enable insert for college admins" ON public.college_programs;
CREATE POLICY "Enable insert for college admins" ON public.college_programs
FOR INSERT TO authenticated WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.college_departments d
    JOIN public.organizations o ON d.org_id = o.id
    WHERE d.id = college_programs.dept_id AND o.created_by = auth.uid()
  )
);

-- Policies for Batches
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.college_batches;
CREATE POLICY "Enable read access for authenticated users" ON public.college_batches
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Enable insert for college admins" ON public.college_batches;
CREATE POLICY "Enable insert for college admins" ON public.college_batches
FOR INSERT TO authenticated WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.college_programs p
    JOIN public.college_departments d ON p.dept_id = d.id
    JOIN public.organizations o ON d.org_id = o.id
    WHERE p.id = college_batches.program_id AND o.created_by = auth.uid()
  )
);
