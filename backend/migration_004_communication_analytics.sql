-- =====================================================
-- MIGRATION 004: COMMUNICATION AND ANALYTICS
-- =====================================================
-- Run this after migration_003_events_assessments.sql

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

-- Mock interview sessions
CREATE TABLE IF NOT EXISTS public.mock_interviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    interviewer_id UUID REFERENCES auth.users(id),
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

-- Learning modules
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

-- College analytics
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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_announcements_college_id ON public.announcements(college_id);
CREATE INDEX IF NOT EXISTS idx_announcements_published ON public.announcements(is_published);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_recipient_id ON public.messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);
CREATE INDEX IF NOT EXISTS idx_mock_interviews_student_id ON public.mock_interviews(student_id);
CREATE INDEX IF NOT EXISTS idx_learning_paths_college_id ON public.learning_paths(college_id);
CREATE INDEX IF NOT EXISTS idx_learning_modules_path_id ON public.learning_modules(path_id);
CREATE INDEX IF NOT EXISTS idx_student_learning_progress_student_id ON public.student_learning_progress(student_id);
CREATE INDEX IF NOT EXISTS idx_student_activity_logs_student_id ON public.student_activity_logs(student_id);
CREATE INDEX IF NOT EXISTS idx_college_analytics_college_id ON public.college_analytics(college_id);

-- Enable RLS
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_interviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_learning_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.college_analytics ENABLE ROW LEVEL SECURITY;

-- RLS Policies
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

DROP POLICY IF EXISTS "Users can view their messages" ON public.messages;
CREATE POLICY "Users can view their messages" ON public.messages
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
CREATE POLICY "Users can send messages" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

DROP POLICY IF EXISTS "Students can manage own mock interviews" ON public.mock_interviews;
CREATE POLICY "Students can manage own mock interviews" ON public.mock_interviews
    FOR ALL USING (auth.uid() = student_id OR auth.uid() = interviewer_id);

DROP POLICY IF EXISTS "College admins can manage learning paths" ON public.learning_paths;
CREATE POLICY "College admins can manage learning paths" ON public.learning_paths
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() 
            AND p.role IN ('college', 'college_admin')
            AND p.organization_id = learning_paths.college_id
        )
    );

DROP POLICY IF EXISTS "Students can view published learning paths" ON public.learning_paths;
CREATE POLICY "Students can view published learning paths" ON public.learning_paths
    FOR SELECT USING (is_published = true);

DROP POLICY IF EXISTS "Students can manage own progress" ON public.student_learning_progress;
CREATE POLICY "Students can manage own progress" ON public.student_learning_progress
    FOR ALL USING (auth.uid() = student_id);

DROP POLICY IF EXISTS "Students can create activity logs" ON public.student_activity_logs;
CREATE POLICY "Students can create activity logs" ON public.student_activity_logs
    FOR INSERT WITH CHECK (auth.uid() = student_id);

DROP POLICY IF EXISTS "College admins can view analytics" ON public.college_analytics;
CREATE POLICY "College admins can view analytics" ON public.college_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() 
            AND p.role IN ('college', 'college_admin')
            AND p.organization_id = college_analytics.college_id
        )
    );

-- Add update triggers
DROP TRIGGER IF EXISTS update_announcements_updated_at ON public.announcements;
CREATE TRIGGER update_announcements_updated_at
    BEFORE UPDATE ON public.announcements
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_mock_interviews_updated_at ON public.mock_interviews;
CREATE TRIGGER update_mock_interviews_updated_at
    BEFORE UPDATE ON public.mock_interviews
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_learning_paths_updated_at ON public.learning_paths;
CREATE TRIGGER update_learning_paths_updated_at
    BEFORE UPDATE ON public.learning_paths
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- Success message
SELECT 'Migration 004: Communication and analytics system created successfully' as status;