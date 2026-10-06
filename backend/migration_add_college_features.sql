-- =====================================================
-- CAREERBRIDGE HIRE - ADD COLLEGE FEATURES TO EXISTING DB
-- =====================================================
-- This migration adds college features to your existing schema

BEGIN;

-- =====================================================
-- 1. ADD MISSING COLUMNS TO EXISTING TABLES
-- =====================================================

-- Add missing columns to profiles table
DO $$ 
BEGIN
    -- Add phone column if it doesn't exist
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN phone TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add avatar_url column if it doesn't exist
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN avatar_url TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add organization_id column if it doesn't exist
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN organization_id UUID REFERENCES public.organizations(id);
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add is_verified column if it doesn't exist
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add profile_completion column if it doesn't exist
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN profile_completion INTEGER DEFAULT 0 CHECK (profile_completion BETWEEN 0 AND 100);
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add last_active column if it doesn't exist
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN last_active TIMESTAMP WITH TIME ZONE DEFAULT now();
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add updated_at column if it doesn't exist
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
END $$;

-- Add missing columns to student_profiles table
DO $$ 
BEGIN
    -- Add usn column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN usn TEXT UNIQUE;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add department_id column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN department_id UUID REFERENCES public.college_departments(id);
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add program_id column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN program_id UUID REFERENCES public.college_programs(id);
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add batch_id column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN batch_id UUID REFERENCES public.college_batches(id);
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add semester column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN semester INTEGER;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add current_year column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN current_year INTEGER;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add sgpa column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN sgpa JSONB DEFAULT '[]'::jsonb;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add backlogs column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN backlogs INTEGER DEFAULT 0;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add backlog_subjects column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN backlog_subjects JSONB DEFAULT '[]'::jsonb;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add verified_skills column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN verified_skills JSONB DEFAULT '[]'::jsonb;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add interests column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN interests JSONB DEFAULT '[]'::jsonb;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add portfolio_url column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN portfolio_url TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add github_url column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN github_url TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add linkedin_url column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN linkedin_url TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add leetcode_username column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN leetcode_username TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add hackerrank_username column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN hackerrank_username TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add placement_status column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN placement_status TEXT DEFAULT 'seeking' CHECK (placement_status IN ('seeking', 'interviewing', 'placed', 'not_interested'));
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add placed_company column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN placed_company TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add placed_package column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN placed_package BIGINT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add placed_role column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN placed_role TEXT;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add placement_date column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN placement_date DATE;
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
    
    -- Add created_at column if it doesn't exist
    BEGIN
        ALTER TABLE public.student_profiles ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT now();
    EXCEPTION
        WHEN duplicate_column THEN NULL;
    END;
END $$;

-- =====================================================
-- 2. CREATE NEW TABLES FOR COLLEGE FEATURES
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

-- Events table
CREATE TABLE IF NOT EXISTS public.events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    college_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_type TEXT NOT NULL CHECK (event_type IN ('hackathon', 'workshop', 'guest_lecture', 'competition', 'seminar', 'webinar', 'placement_drive', 'cultural', 'technical')),
    category TEXT,
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
    prizes JSONB DEFAULT '[]'::jsonb,
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
    registration_data JSONB DEFAULT '{}'::jsonb,
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
    options JSONB DEFAULT '[]'::jsonb,
    correct_answers JSONB DEFAULT '[]'::jsonb,
    explanation TEXT,
    difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
    points INTEGER DEFAULT 1,
    time_limit_seconds INTEGER,
    code_template TEXT,
    test_cases JSONB DEFAULT '[]'::jsonb,
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
    answers JSONB DEFAULT '{}'::jsonb,
    time_spent JSONB DEFAULT '{}'::jsonb,
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
    validation_source TEXT,
    proficiency_level TEXT CHECK (proficiency_level IN ('beginner', 'intermediate', 'advanced', 'expert')),
    score DECIMAL(5,2),
    certificate_url TEXT,
    verified_by UUID REFERENCES auth.users(id),
    verification_date TIMESTAMP WITH TIME ZONE,
    is_verified BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Announcements
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    college_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    announcement_type TEXT CHECK (announcement_type IN ('general', 'placement', 'academic', 'event', 'urgent', 'celebration')),
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    target_audience JSONB DEFAULT '[]'::jsonb,
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
    conversation_id UUID,
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
-- 3. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Student profiles indexes
CREATE INDEX IF NOT EXISTS idx_student_profiles_department_id ON public.student_profiles(department_id);
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
-- 4. ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_skill_validations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. CREATE RLS POLICIES
-- =====================================================

-- Skills policies
DROP POLICY IF EXISTS "Everyone can view active skills" ON public.skills;
CREATE POLICY "Everyone can view active skills" ON public.skills
    FOR SELECT USING (is_active = true);

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

-- Event registrations policies
DROP POLICY IF EXISTS "Students can register for events" ON public.event_registrations;
CREATE POLICY "Students can register for events" ON public.event_registrations
    FOR ALL USING (auth.uid() = student_id);

-- Messages policies
DROP POLICY IF EXISTS "Users can view their messages" ON public.messages;
CREATE POLICY "Users can view their messages" ON public.messages
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
CREATE POLICY "Users can send messages" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Announcements policies
DROP POLICY IF EXISTS "College admins can manage announcements" ON public.announcements;
CREATE POLICY "College admins can manage announcements" ON public.announcements
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() 
            AND p.role IN ('college', 'college_admin')
            AND p.organization_id = announcements.college_id
        )
    );

DROP POLICY IF EXISTS "Students can view published announcements" ON public.announcements;
CREATE POLICY "Students can view published announcements" ON public.announcements
    FOR SELECT USING (is_published = true);

-- =====================================================
-- 6. CREATE UPDATE TRIGGERS
-- =====================================================

-- Create update function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add update triggers for new tables
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

DROP TRIGGER IF EXISTS update_announcements_updated_at ON public.announcements;
CREATE TRIGGER update_announcements_updated_at
    BEFORE UPDATE ON public.announcements
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- Add update trigger for profiles if it doesn't exist
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- =====================================================
-- 7. INSERT INITIAL SKILLS DATA
-- =====================================================

INSERT INTO public.skills (name, category, subcategory, description) VALUES
-- Programming Languages
('Python', 'programming', 'languages', 'High-level programming language'),
('Java', 'programming', 'languages', 'Object-oriented programming language'),
('JavaScript', 'programming', 'languages', 'Dynamic programming language for web'),
('C++', 'programming', 'languages', 'System programming language'),
('C', 'programming', 'languages', 'Low-level programming language'),
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

COMMIT;

-- Success message
SELECT 'College features added successfully! 🎉' as status,
       'Events, Assessments, and Student Management are now ready to use.' as message,
       (SELECT COUNT(*) FROM public.skills) as skills_loaded;