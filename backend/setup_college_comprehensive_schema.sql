-- =====================================================
-- CAREERBRIDGE HIRE - COMPREHENSIVE COLLEGE SCHEMA
-- =====================================================
-- This file contains all database tables needed for the college-side features
-- Run this after the basic setup files

-- =====================================================
-- 1. CORE TABLES (Enhanced)
-- =====================================================

-- Ensure profiles table exists with all needed columns
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

-- Ensure organizations table exists with enhanced columns
CREATE TABLE IF NOT EXISTS public.organizations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('college', 'university', 'institute')),
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
    allowed_emails_domain TEXT, -- For auto-verification
    established_year INTEGER,
    accreditation JSONB DEFAULT '[]'::jsonb, -- NAAC, NBA, etc.
    created_by UUID REFERENCES auth.users(id),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- =====================================================
-- 2. STUDENT MANAGEMENT TABLES
-- =====================================================

-- Enhanced student profiles
CREATE TABLE IF NOT EXISTS public.student_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    usn TEXT UNIQUE, -- University Seat Number
    college_id TEXT,
    department_id UUID REFERENCES public.college_departments(id),
    program_id UUID REFERENCES public.college_programs(id),
    batch_id UUID REFERENCES public.college_batches(id),
    semester INTEGER,
    current_year INTEGER,
    cgpa DECIMAL(3,2),
    sgpa JSONB DEFAULT '[]'::jsonb, -- Semester-wise SGPA
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
    placed_package BIGINT, -- In rupees
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

-- Student external profiles (LeetCode, GitHub, etc.)
CREATE TABLE IF NOT EXISTS public.student_external_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    platform TEXT NOT NULL CHECK (platform IN ('github', 'leetcode', 'hackerrank', 'codechef', 'codeforces', 'kaggle', 'behance', 'dribbble')),
    username TEXT NOT NULL,
    profile_url TEXT,
    stats JSONB DEFAULT '{}'::jsonb, -- Platform-specific stats
    last_synced_at TIMESTAMP WITH TIME ZONE,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(student_id, platform)
);

-- =====================================================
-- 3. EVENTS MANAGEMENT TABLES
-- =====================================================

-- Events table
CREATE TABLE IF NOT EXISTS public.events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    college_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_type TEXT NOT NULL CHECK (event_type IN ('hackathon', 'workshop', 'guest_lecture', 'competition', 'seminar', 'webinar', 'placement_drive', 'cultural', 'technical')),
    category TEXT, -- Additional categorization
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    registration_start TIMESTAMP WITH TIME ZONE,
    registration_end TIMESTAMP WITH TIME ZONE,
    venue TEXT,
    is_online BOOLEAN DEFAULT FALSE,
    meeting_link TEXT,
    max_participants INTEGER,
    current_participants INTEGER DEFAULT 0,
    registration_fee DECIMAL(10,2) DEFAULT 0,
    prizes JSONB DEFAULT '[]'::jsonb, -- Prize details
    sponsors JSONB DEFAULT '[]'::jsonb,
    organizers JSONB DEFAULT '[]'::jsonb,
    speakers JSONB DEFAULT '[]'::jsonb,
    agenda JSONB DEFAULT '[]'::jsonb,
    requirements TEXT,
    instructions TEXT,
    tags JSONB DEFAULT '[]'::jsonb,
    banner_url TEXT,
    certificate_template_url TEXT,
    provide_certificate BOOLEAN DEFAULT FALSE,
    requires_approval BOOLEAN DEFAULT FALSE,
    is_published BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'ongoing', 'completed', 'cancelled')),
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Event registrations
CREATE TABLE IF NOT EXISTS public.event_registrations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    registration_data JSONB DEFAULT '{}'::jsonb, -- Form responses
    team_name TEXT,
    team_members JSONB DEFAULT '[]'::jsonb,
    status TEXT DEFAULT 'registered' CHECK (status IN ('registered', 'approved', 'rejected', 'attended', 'no_show')),
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    payment_id TEXT,
    attended BOOLEAN DEFAULT FALSE,
    attendance_time TIMESTAMP WITH TIME ZONE,
    certificate_issued BOOLEAN DEFAULT FALSE,
    certificate_url TEXT,
    feedback_rating INTEGER CHECK (feedback_rating BETWEEN 1 AND 5),
    feedback_comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(event_id, student_id)
);

-- =====================================================
-- 4. SKILL ASSESSMENTS TABLES
-- =====================================================

-- Skills master table
CREATE TABLE IF NOT EXISTS public.skills (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('programming', 'web_development', 'mobile_development', 'data_science', 'ai_ml', 'devops', 'database', 'cloud', 'cybersecurity', 'ui_ux', 'soft_skills', 'aptitude', 'domain_knowledge')),
    subcategory TEXT,
    description TEXT,
    icon_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    demand_score INTEGER DEFAULT 50 CHECK (demand_score BETWEEN 0 AND 100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Assessments table
CREATE TABLE IF NOT EXISTS public.assessments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    college_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    skill_id UUID REFERENCES public.skills(id),
    category TEXT NOT NULL CHECK (category IN ('programming', 'aptitude', 'domain', 'soft_skills', 'technical')),
    difficulty TEXT NOT NULL CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
    duration_minutes INTEGER NOT NULL,
    total_questions INTEGER NOT NULL,
    passing_score INTEGER NOT NULL CHECK (passing_score BETWEEN 0 AND 100),
    instructions TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    allow_retakes BOOLEAN DEFAULT FALSE,
    show_results BOOLEAN DEFAULT TRUE,
    randomize_questions BOOLEAN DEFAULT TRUE,
    proctoring_enabled BOOLEAN DEFAULT FALSE,
    tags JSONB DEFAULT '[]'::jsonb,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Question bank
CREATE TABLE IF NOT EXISTS public.questions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    assessment_id UUID REFERENCES public.assessments(id) ON DELETE CASCADE,
    skill_id UUID REFERENCES public.skills(id),
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL CHECK (question_type IN ('mcq', 'multiple_select', 'true_false', 'coding', 'descriptive')),
    options JSONB DEFAULT '[]'::jsonb, -- For MCQ questions
    correct_answers JSONB DEFAULT '[]'::jsonb,
    explanation TEXT,
    difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
    points INTEGER DEFAULT 1,
    time_limit_seconds INTEGER,
    code_template TEXT, -- For coding questions
    test_cases JSONB DEFAULT '[]'::jsonb, -- For coding questions
    tags JSONB DEFAULT '[]'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Assessment attempts
CREATE TABLE IF NOT EXISTS public.assessment_attempts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    assessment_id UUID REFERENCES public.assessments(id) ON DELETE CASCADE,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    attempt_number INTEGER DEFAULT 1,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    end_time TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    total_questions INTEGER,
    attempted_questions INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    score DECIMAL(5,2),
    percentage DECIMAL(5,2),
    status TEXT DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned', 'timed_out')),
    answers JSONB DEFAULT '{}'::jsonb, -- Question ID -> Answer mapping
    time_spent JSONB DEFAULT '{}'::jsonb, -- Question ID -> Time spent mapping
    is_proctored BOOLEAN DEFAULT FALSE,
    proctoring_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Student skill validations
CREATE TABLE IF NOT EXISTS public.student_skill_validations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    skill_id UUID REFERENCES public.skills(id),
    validation_type TEXT NOT NULL CHECK (validation_type IN ('assessment', 'certification', 'project', 'endorsement', 'external_profile')),
    validation_source TEXT, -- Assessment ID, Certificate name, Project ID, etc.
    proficiency_level TEXT CHECK (proficiency_level IN ('beginner', 'intermediate', 'advanced', 'expert')),
    score DECIMAL(5,2),
    certificate_url TEXT,
    verified_by UUID REFERENCES auth.users(id),
    verification_date TIMESTAMP WITH TIME ZONE,
    is_verified BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- =====================================================
-- 5. LEARNING PATHS TABLES
-- =====================================================

-- Learning paths
CREATE TABLE IF NOT EXISTS public.learning_paths (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    college_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    difficulty TEXT CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
    estimated_hours INTEGER,
    skills_covered JSONB DEFAULT '[]'::jsonb,
    prerequisites JSONB DEFAULT '[]'::jsonb,
    learning_outcomes JSONB DEFAULT '[]'::jsonb,
    banner_url TEXT,
    is_published BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    enrollment_count INTEGER DEFAULT 0,
    completion_rate DECIMAL(5,2) DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Learning modules within paths
CREATE TABLE IF NOT EXISTS public.learning_modules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    path_id UUID REFERENCES public.learning_paths(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    module_type TEXT CHECK (module_type IN ('video', 'article', 'quiz', 'assignment', 'project', 'live_session')),
    content_url TEXT,
    content_text TEXT,
    duration_minutes INTEGER,
    sequence_order INTEGER NOT NULL,
    is_mandatory BOOLEAN DEFAULT TRUE,
    passing_criteria JSONB DEFAULT '{}'::jsonb,
    resources JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Student learning progress
CREATE TABLE IF NOT EXISTS public.student_learning_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    path_id UUID REFERENCES public.learning_paths(id) ON DELETE CASCADE,
    module_id UUID REFERENCES public.learning_modules(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed', 'skipped')),
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage BETWEEN 0 AND 100),
    time_spent_minutes INTEGER DEFAULT 0,
    score DECIMAL(5,2),
    attempts INTEGER DEFAULT 0,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(student_id, path_id, module_id)
);

-- =====================================================
-- 6. PROJECTS & PORTFOLIO TABLES
-- =====================================================

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
    role TEXT, -- Role in the project
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

-- Project endorsements/reviews
CREATE TABLE IF NOT EXISTS public.project_endorsements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID REFERENCES public.student_projects(id) ON DELETE CASCADE,
    endorsed_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    endorser_type TEXT CHECK (endorser_type IN ('faculty', 'mentor', 'peer', 'industry_expert')),
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    skills_validated JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(project_id, endorsed_by)
);

-- =====================================================
-- 7. ACHIEVEMENTS & CERTIFICATIONS TABLES
-- =====================================================

-- Student achievements
CREATE TABLE IF NOT EXISTS public.student_achievements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_type TEXT NOT NULL CHECK (achievement_type IN ('hackathon', 'competition', 'certification', 'publication', 'patent', 'award', 'scholarship', 'internship', 'job_offer')),
    title TEXT NOT NULL,
    description TEXT,
    issuer TEXT, -- Organization/Company that issued
    achievement_date DATE,
    expiry_date DATE,
    certificate_url TEXT,
    verification_url TEXT,
    position TEXT, -- Winner, Runner-up, Top 10, etc.
    prize_amount DECIMAL(10,2),
    skills_demonstrated JSONB DEFAULT '[]'::jsonb,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES auth.users(id),
    verification_date TIMESTAMP WITH TIME ZONE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- =====================================================
-- 8. MOCK INTERVIEWS TABLES
-- =====================================================

-- Mock interview sessions
CREATE TABLE IF NOT EXISTS public.mock_interviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    interviewer_id UUID REFERENCES auth.users(id), -- Can be faculty, mentor, or AI
    interview_type TEXT NOT NULL CHECK (interview_type IN ('technical', 'hr', 'behavioral', 'case_study', 'group_discussion')),
    interview_mode TEXT NOT NULL CHECK (interview_mode IN ('ai', 'peer', 'expert', 'faculty')),
    scheduled_at TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER DEFAULT 30,
    status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'no_show')),
    meeting_link TEXT,
    recording_url TEXT,
    questions JSONB DEFAULT '[]'::jsonb,
    responses JSONB DEFAULT '[]'::jsonb,
    feedback JSONB DEFAULT '{}'::jsonb,
    overall_rating INTEGER CHECK (overall_rating BETWEEN 1 AND 10),
    strengths JSONB DEFAULT '[]'::jsonb,
    areas_for_improvement JSONB DEFAULT '[]'::jsonb,
    recommendations TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- =====================================================
-- 9. COMMUNICATION TABLES
-- =====================================================

-- Announcements
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    college_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    announcement_type TEXT CHECK (announcement_type IN ('general', 'placement', 'academic', 'event', 'urgent', 'celebration')),
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    target_audience JSONB DEFAULT '[]'::jsonb, -- departments, batches, specific students
    attachments JSONB DEFAULT '[]'::jsonb,
    is_published BOOLEAN DEFAULT FALSE,
    publish_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    expires_at TIMESTAMP WITH TIME ZONE,
    views_count INTEGER DEFAULT 0,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Messages/Chat
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    recipient_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    conversation_id UUID, -- For grouping messages
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'file', 'image', 'video', 'audio')),
    content TEXT,
    file_url TEXT,
    file_name TEXT,
    file_size INTEGER,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT FALSE,
    reply_to UUID REFERENCES public.messages(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- =====================================================
-- 10. ANALYTICS TABLES
-- =====================================================

-- Student activity logs
CREATE TABLE IF NOT EXISTS public.student_activity_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL,
    activity_data JSONB DEFAULT '{}'::jsonb,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- College analytics data
CREATE TABLE IF NOT EXISTS public.college_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    college_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    metric_name TEXT NOT NULL,
    metric_value DECIMAL(15,2),
    metric_data JSONB DEFAULT '{}'::jsonb,
    date_recorded DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(college_id, metric_name, date_recorded)
);

-- =====================================================
-- 11. INDEXES FOR PERFORMANCE
-- =====================================================

-- Student profiles indexes
CREATE INDEX IF NOT EXISTS idx_student_profiles_college_id ON public.student_profiles(department_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_batch_id ON public.student_profiles(batch_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_placement_status ON public.student_profiles(placement_status);
CREATE INDEX IF NOT EXISTS idx_student_profiles_cgpa ON public.student_profiles(cgpa);

-- Events indexes
CREATE INDEX IF NOT EXISTS idx_events_college_id ON public.events(college_id);
CREATE INDEX IF NOT EXISTS idx_events_type ON public.events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_status ON public.events(status);
CREATE INDEX IF NOT EXISTS idx_events_dates ON public.events(start_date, end_date);

-- Assessments indexes
CREATE INDEX IF NOT EXISTS idx_assessments_college_id ON public.assessments(college_id);
CREATE INDEX IF NOT EXISTS idx_assessments_skill_id ON public.assessments(skill_id);
CREATE INDEX IF NOT EXISTS idx_assessment_attempts_student_id ON public.assessment_attempts(student_id);
CREATE INDEX IF NOT EXISTS idx_assessment_attempts_assessment_id ON public.assessment_attempts(assessment_id);

-- Messages indexes
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_recipient_id ON public.messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);

-- =====================================================
-- 12. ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_academic_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_external_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_skill_validations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_learning_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_endorsements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_interviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.college_analytics ENABLE ROW LEVEL SECURITY;

-- Basic RLS Policies (Students can access their own data, College admins can access their college data)

-- Profiles policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Student profiles policies
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

-- Events policies
DROP POLICY IF EXISTS "College admins can manage their events" ON public.events;
CREATE POLICY "College admins can manage their events" ON public.events
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() 
            AND p.role IN ('college', 'college_admin')
            AND p.organization_id = events.college_id
        )
    );

DROP POLICY IF EXISTS "Students can view published events" ON public.events;
CREATE POLICY "Students can view published events" ON public.events
    FOR SELECT USING (is_published = true);

-- Assessment policies
DROP POLICY IF EXISTS "College admins can manage assessments" ON public.assessments;
CREATE POLICY "College admins can manage assessments" ON public.assessments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() 
            AND p.role IN ('college', 'college_admin')
            AND p.organization_id = assessments.college_id
        )
    );

DROP POLICY IF EXISTS "Students can view active assessments" ON public.assessments;
CREATE POLICY "Students can view active assessments" ON public.assessments
    FOR SELECT USING (is_active = true);

-- Assessment attempts policies
DROP POLICY IF EXISTS "Students can manage own attempts" ON public.assessment_attempts;
CREATE POLICY "Students can manage own attempts" ON public.assessment_attempts
    FOR ALL USING (auth.uid() = student_id);

-- Messages policies
DROP POLICY IF EXISTS "Users can view their messages" ON public.messages;
CREATE POLICY "Users can view their messages" ON public.messages
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
CREATE POLICY "Users can send messages" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- =====================================================
-- 13. FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers to relevant tables
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_organizations_updated_at ON public.organizations;
CREATE TRIGGER update_organizations_updated_at
    BEFORE UPDATE ON public.organizations
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_student_profiles_updated_at ON public.student_profiles;
CREATE TRIGGER update_student_profiles_updated_at
    BEFORE UPDATE ON public.student_profiles
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_events_updated_at ON public.events;
CREATE TRIGGER update_events_updated_at
    BEFORE UPDATE ON public.events
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_assessments_updated_at ON public.assessments;
CREATE TRIGGER update_assessments_updated_at
    BEFORE UPDATE ON public.assessments
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- Function to update profile completion percentage
CREATE OR REPLACE FUNCTION calculate_profile_completion()
RETURNS TRIGGER AS $$
DECLARE
    completion_score INTEGER := 0;
BEGIN
    -- Basic info (40 points)
    IF NEW.full_name IS NOT NULL AND NEW.full_name != '' THEN
        completion_score := completion_score + 10;
    END IF;
    
    IF NEW.phone IS NOT NULL AND NEW.phone != '' THEN
        completion_score := completion_score + 10;
    END IF;
    
    IF NEW.avatar_url IS NOT NULL AND NEW.avatar_url != '' THEN
        completion_score := completion_score + 10;
    END IF;
    
    IF NEW.email IS NOT NULL AND NEW.email != '' THEN
        completion_score := completion_score + 10;
    END IF;
    
    -- Check student profile completion (60 points)
    IF EXISTS (SELECT 1 FROM public.student_profiles WHERE id = NEW.id) THEN
        -- Add points based on student profile fields
        SELECT 
            CASE WHEN usn IS NOT NULL THEN 5 ELSE 0 END +
            CASE WHEN cgpa IS NOT NULL THEN 10 ELSE 0 END +
            CASE WHEN skills IS NOT NULL AND jsonb_array_length(skills) > 0 THEN 15 ELSE 0 END +
            CASE WHEN resume_url IS NOT NULL THEN 10 ELSE 0 END +
            CASE WHEN linkedin_url IS NOT NULL THEN 5 ELSE 0 END +
            CASE WHEN github_url IS NOT NULL THEN 5 ELSE 0 END +
            CASE WHEN array_length(string_to_array(description, ' '), 1) > 10 THEN 10 ELSE 0 END
        INTO completion_score
        FROM public.student_profiles 
        WHERE id = NEW.id;
        
        completion_score := completion_score + 40; -- Base points
    END IF;
    
    NEW.profile_completion := LEAST(completion_score, 100);
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add profile completion trigger
DROP TRIGGER IF EXISTS calculate_profile_completion_trigger ON public.profiles;
CREATE TRIGGER calculate_profile_completion_trigger
    BEFORE INSERT OR UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE PROCEDURE calculate_profile_completion();

-- =====================================================
-- 14. INITIAL DATA SEEDING
-- =====================================================

-- Insert common skills
INSERT INTO public.skills (name, category, subcategory, description) VALUES
-- Programming Languages
('Python', 'programming', 'languages', 'High-level programming language'),
('Java', 'programming', 'languages', 'Object-oriented programming language'),
('JavaScript', 'programming', 'languages', 'Dynamic programming language for web'),
('C++', 'programming', 'languages', 'System programming language'),
('C', 'programming', 'languages', 'Low-level programming language'),
('Go', 'programming', 'languages', 'Modern system programming language'),
('Rust', 'programming', 'languages', 'Memory-safe system programming language'),
('TypeScript', 'programming', 'languages', 'Typed superset of JavaScript'),

-- Web Development
('React', 'web_development', 'frontend', 'JavaScript library for building UIs'),
('Angular', 'web_development', 'frontend', 'TypeScript-based web framework'),
('Vue.js', 'web_development', 'frontend', 'Progressive JavaScript framework'),
('Node.js', 'web_development', 'backend', 'JavaScript runtime for server-side'),
('Express.js', 'web_development', 'backend', 'Web framework for Node.js'),
('Django', 'web_development', 'backend', 'Python web framework'),
('Flask', 'web_development', 'backend', 'Lightweight Python web framework'),
('Spring Boot', 'web_development', 'backend', 'Java framework for web applications'),

-- Mobile Development
('Flutter', 'mobile_development', 'cross_platform', 'UI toolkit for mobile apps'),
('React Native', 'mobile_development', 'cross_platform', 'Framework for native mobile apps'),
('Android', 'mobile_development', 'native', 'Native Android development'),
('iOS', 'mobile_development', 'native', 'Native iOS development'),
('Kotlin', 'mobile_development', 'native', 'Modern language for Android'),
('Swift', 'mobile_development', 'native', 'Programming language for iOS'),

-- Data Science & AI
('Machine Learning', 'ai_ml', 'core', 'Algorithms that learn from data'),
('Deep Learning', 'ai_ml', 'advanced', 'Neural networks with multiple layers'),
('Data Analysis', 'data_science', 'core', 'Extracting insights from data'),
('Data Visualization', 'data_science', 'visualization', 'Presenting data graphically'),
('Pandas', 'data_science', 'tools', 'Data manipulation library for Python'),
('NumPy', 'data_science', 'tools', 'Numerical computing library for Python'),
('TensorFlow', 'ai_ml', 'frameworks', 'Open-source machine learning framework'),
('PyTorch', 'ai_ml', 'frameworks', 'Deep learning framework'),

-- Databases
('SQL', 'database', 'query', 'Structured Query Language'),
('MySQL', 'database', 'relational', 'Open-source relational database'),
('PostgreSQL', 'database', 'relational', 'Advanced open-source database'),
('MongoDB', 'database', 'nosql', 'Document-oriented NoSQL database'),
('Redis', 'database', 'cache', 'In-memory data structure store'),

-- Cloud & DevOps
('AWS', 'cloud', 'platforms', 'Amazon Web Services'),
('Azure', 'cloud', 'platforms', 'Microsoft Azure cloud platform'),
('Google Cloud', 'cloud', 'platforms', 'Google Cloud Platform'),
('Docker', 'devops', 'containerization', 'Platform for containerized applications'),
('Kubernetes', 'devops', 'orchestration', 'Container orchestration platform'),
('Git', 'devops', 'version_control', 'Distributed version control system'),

-- Soft Skills
('Communication', 'soft_skills', 'interpersonal', 'Effective verbal and written communication'),
('Leadership', 'soft_skills', 'management', 'Ability to guide and motivate teams'),
('Problem Solving', 'soft_skills', 'analytical', 'Analytical thinking and solution finding'),
('Teamwork', 'soft_skills', 'collaboration', 'Working effectively in teams'),
('Time Management', 'soft_skills', 'productivity', 'Managing time and priorities effectively'),
('Critical Thinking', 'soft_skills', 'analytical', 'Objective analysis and evaluation')

ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

-- Add a comment to indicate successful completion
COMMENT ON SCHEMA public IS 'CareerBridge College Schema - Comprehensive database structure for college-side features';