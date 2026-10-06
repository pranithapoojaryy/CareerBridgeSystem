-- Migration 012: Job System
-- Author: CareerBridge Team
-- Date: 2026-01-14

-- 1. Create Jobs Table
CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    recruiter_id UUID REFERENCES public.profiles(id) NOT NULL,
    organization_id UUID REFERENCES public.organizations(id), -- Denormalized for easy company logic
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    requirements TEXT,
    location TEXT,
    salary_range TEXT,
    job_type TEXT CHECK (job_type IN ('Full-time', 'Part-time', 'Internship', 'Contract', 'Freelance')),
    is_featured BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'closed', 'draft')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Create Job Applications Table
CREATE TABLE IF NOT EXISTS public.job_applications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE NOT NULL,
    student_id UUID REFERENCES public.profiles(id) NOT NULL,
    resume_url TEXT,
    cover_letter TEXT,
    status TEXT DEFAULT 'applied' CHECK (status IN ('applied', 'reviewing', 'shortlisted', 'rejected', 'hired')),
    applied_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(job_id, student_id) -- Prevent duplicate applications
);

-- 3. Enable RLS
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for Jobs

-- Everyone can view open jobs
CREATE POLICY "Public can view open jobs" 
ON public.jobs FOR SELECT 
USING (status = 'open' OR auth.uid() = recruiter_id);

-- Recruiters can manage their own jobs
CREATE POLICY "Recruiters can insert jobs" 
ON public.jobs FOR INSERT 
WITH CHECK (
    auth.uid() = recruiter_id AND 
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'recruiter')
);

CREATE POLICY "Recruiters can update own jobs" 
ON public.jobs FOR UPDATE 
USING (auth.uid() = recruiter_id);

CREATE POLICY "Recruiters can delete own jobs" 
ON public.jobs FOR DELETE 
USING (auth.uid() = recruiter_id);


-- 5. RLS Policies for Applications

-- Students can view their own applications
CREATE POLICY "Students can view own applications" 
ON public.job_applications FOR SELECT 
USING (auth.uid() = student_id);

-- Students can apply (insert)
CREATE POLICY "Students can apply to jobs" 
ON public.job_applications FOR INSERT 
WITH CHECK (auth.uid() = student_id);

-- Recruiters can view applications for their jobs
CREATE POLICY "Recruiters can view applications for their jobs" 
ON public.job_applications FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM public.jobs 
        WHERE jobs.id = job_applications.job_id 
        AND jobs.recruiter_id = auth.uid()
    )
);

-- Recruiters can update status of applications for their jobs
CREATE POLICY "Recruiters can update application status" 
ON public.job_applications FOR UPDATE 
USING (
    EXISTS (
        SELECT 1 FROM public.jobs 
        WHERE jobs.id = job_applications.job_id 
        AND jobs.recruiter_id = auth.uid()
    )
);

-- College Admins can view applications of their students
-- This is a bit more complex (Join: App -> Student -> Profile -> OrgID == Admin -> Profile -> OrgID)
-- For MVP/Performance, we might skip a direct RLS policy for this complex join on every row 
-- and instead rely on a SECURITY DEFINER function for the college dashboard to fetch this data.
-- But here is a policy attempt:
CREATE POLICY "College Admins can view student applications" 
ON public.job_applications FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM public.profiles student_prof
        WHERE student_prof.id = job_applications.student_id
        AND student_prof.organization_id IN (
            SELECT organization_id FROM public.profiles WHERE id = auth.uid() AND (role = 'college_admin' OR role = 'admin')
        )
    )
);

-- 6. Indexes
CREATE INDEX idx_jobs_recruiter ON public.jobs(recruiter_id);
CREATE INDEX idx_jobs_status ON public.jobs(status);
CREATE INDEX idx_jobs_created_at ON public.jobs(created_at DESC);
CREATE INDEX idx_applications_student ON public.job_applications(student_id);
CREATE INDEX idx_applications_job ON public.job_applications(job_id);

-- 7. Grant access
GRANT ALL ON public.jobs TO postgres, authenticated, service_role;
GRANT ALL ON public.job_applications TO postgres, authenticated, service_role;
GRANT SELECT ON public.jobs TO anon; -- Allow public to view jobs? Maybe.
