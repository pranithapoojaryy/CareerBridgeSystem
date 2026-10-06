-- =====================================================
-- MIGRATION 002: STUDENT MANAGEMENT SYSTEM
-- =====================================================
-- Run this after migration_001_base_tables.sql

-- Enhanced student profiles
CREATE TABLE IF NOT EXISTS public.student_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    usn TEXT UNIQUE,
    college_id TEXT,
    department_id UUID REFERENCES public.college_departments(id),
    program_id UUID REFERENCES public.college_programs(id),
    batch_id UUID REFERENCES public.college_batches(id),
    semester INTEGER,
    current_year INTEGER,
    cgpa DECIMAL(3,2),
    sgpa JSONB DEFAULT '[]'::jsonb,
    backlogs INTEGER DEFAULT 0,
    backlog_subjects JSONB DEFAULT '[]'::jsonb,
    skills JSONB DEFAULT '[]'::jsonb,
    verified_skills JSONB DEFAULT '[]'::jsonb,
    interests JSONB DEFAULT '[]'::jsonb,
    resume_url TEXT,
    portfolio_url TEXT,
    github_url TEXT,
    linkedin_url TEXT,
    leetcode_username TEXT,
    hackerrank_username TEXT,
    codechef_username TEXT,
    codeforces_username TEXT,
    placement_status TEXT DEFAULT 'seeking' CHECK (placement_status IN ('seeking', 'interviewing', 'placed', 'not_interested')),
    placed_company TEXT,
    placed_package BIGINT,
    placed_role TEXT,
    placement_date DATE,
    is_placement_coordinator BOOLEAN DEFAULT FALSE,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    emergency_contact_relation TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Student academic records
CREATE TABLE IF NOT EXISTS public.student_academic_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    exam_type TEXT NOT NULL CHECK (exam_type IN ('10th', '12th', 'diploma', 'ug', 'pg')),
    board_university TEXT,
    school_college TEXT,
    year_of_passing INTEGER,
    percentage DECIMAL(5,2),
    cgpa DECIMAL(3,2),
    grade TEXT,
    subjects JSONB DEFAULT '[]'::jsonb,
    certificate_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Student external profiles
CREATE TABLE IF NOT EXISTS public.student_external_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    platform TEXT NOT NULL CHECK (platform IN ('github', 'leetcode', 'hackerrank', 'codechef', 'codeforces', 'kaggle', 'behance', 'dribbble')),
    username TEXT NOT NULL,
    profile_url TEXT,
    stats JSONB DEFAULT '{}'::jsonb,
    last_synced_at TIMESTAMP WITH TIME ZONE,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(student_id, platform)
);

-- Student projects
CREATE TABLE IF NOT EXISTS public.student_projects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    project_type TEXT CHECK (project_type IN ('academic', 'personal', 'internship', 'freelance', 'hackathon', 'open_source')),
    tech_stack JSONB DEFAULT '[]'::jsonb,
    skills_used JSONB DEFAULT '[]'::jsonb,
    github_url TEXT,
    live_demo_url TEXT,
    documentation_url TEXT,
    screenshots JSONB DEFAULT '[]'::jsonb,
    video_demo_url TEXT,
    team_size INTEGER DEFAULT 1,
    team_members JSONB DEFAULT '[]'::jsonb,
    role TEXT,
    duration_months INTEGER,
    start_date DATE,
    end_date DATE,
    is_featured BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES auth.users(id),
    verification_date TIMESTAMP WITH TIME ZONE,
    likes_count INTEGER DEFAULT 0,
    views_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Student achievements
CREATE TABLE IF NOT EXISTS public.student_achievements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_type TEXT NOT NULL CHECK (achievement_type IN ('hackathon', 'competition', 'certification', 'publication', 'patent', 'award', 'scholarship', 'internship', 'job_offer')),
    title TEXT NOT NULL,
    description TEXT,
    issuer TEXT,
    achievement_date DATE,
    expiry_date DATE,
    certificate_url TEXT,
    verification_url TEXT,
    position TEXT,
    prize_amount DECIMAL(10,2),
    skills_demonstrated JSONB DEFAULT '[]'::jsonb,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES auth.users(id),
    verification_date TIMESTAMP WITH TIME ZONE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_student_profiles_department_id ON public.student_profiles(department_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_batch_id ON public.student_profiles(batch_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_placement_status ON public.student_profiles(placement_status);
CREATE INDEX IF NOT EXISTS idx_student_profiles_cgpa ON public.student_profiles(cgpa);
CREATE INDEX IF NOT EXISTS idx_student_academic_records_student_id ON public.student_academic_records(student_id);
CREATE INDEX IF NOT EXISTS idx_student_external_profiles_student_id ON public.student_external_profiles(student_id);
CREATE INDEX IF NOT EXISTS idx_student_projects_student_id ON public.student_projects(student_id);
CREATE INDEX IF NOT EXISTS idx_student_achievements_student_id ON public.student_achievements(student_id);

-- Enable RLS
ALTER TABLE public.student_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_academic_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_external_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_achievements ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Students can manage own profile" ON public.student_profiles;
CREATE POLICY "Students can manage own profile" ON public.student_profiles
    FOR ALL USING (auth.uid() = id);

DROP POLICY IF EXISTS "College admins can view their students" ON public.student_profiles;
CREATE POLICY "College admins can view their students" ON public.student_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            JOIN public.college_departments cd ON p.organization_id = cd.org_id
            WHERE p.id = auth.uid() 
            AND p.role IN ('college', 'college_admin')
            AND cd.id = student_profiles.department_id
        )
    );

DROP POLICY IF EXISTS "Students can manage own records" ON public.student_academic_records;
CREATE POLICY "Students can manage own records" ON public.student_academic_records
    FOR ALL USING (auth.uid() = student_id);

DROP POLICY IF EXISTS "Students can manage own external profiles" ON public.student_external_profiles;
CREATE POLICY "Students can manage own external profiles" ON public.student_external_profiles
    FOR ALL USING (auth.uid() = student_id);

DROP POLICY IF EXISTS "Students can manage own projects" ON public.student_projects;
CREATE POLICY "Students can manage own projects" ON public.student_projects
    FOR ALL USING (auth.uid() = student_id);

DROP POLICY IF EXISTS "Students can manage own achievements" ON public.student_achievements;
CREATE POLICY "Students can manage own achievements" ON public.student_achievements
    FOR ALL USING (auth.uid() = student_id);

-- Add update triggers
DROP TRIGGER IF EXISTS update_student_profiles_updated_at ON public.student_profiles;
CREATE TRIGGER update_student_profiles_updated_at
    BEFORE UPDATE ON public.student_profiles
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_student_projects_updated_at ON public.student_projects;
CREATE TRIGGER update_student_projects_updated_at
    BEFORE UPDATE ON public.student_projects
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- Success message
SELECT 'Migration 002: Student system created successfully' as status;