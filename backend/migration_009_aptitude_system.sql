-- =====================================================
-- MIGRATION 009: APTITUDE TESTING SYSTEM
-- =====================================================
-- Run this after migration_008_certification_system.sql

-- =====================================================
-- 1. APTITUDE MODULES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.aptitude_modules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT,
    category TEXT NOT NULL CHECK (category IN ('logical_reasoning', 'quantitative_aptitude', 'verbal_ability', 'technical', 'general_knowledge')),
    difficulty_levels JSONB DEFAULT '["easy", "medium", "hard"]'::jsonb,
    color_code TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- =====================================================
-- 2. APTITUDE QUESTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.aptitude_questions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    module_id UUID REFERENCES public.aptitude_modules(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    options JSONB NOT NULL, -- Array of 4 options: ["Option A", "Option B", "Option C", "Option D"]
    correct_answer INTEGER NOT NULL CHECK (correct_answer BETWEEN 0 AND 3), -- Index 0-3
    explanation TEXT,
    difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    tags JSONB DEFAULT '[]'::jsonb,
    generated_by TEXT DEFAULT 'gemini', -- 'gemini', 'manual', 'imported'
    source_metadata JSONB DEFAULT '{}'::jsonb, -- Store Gemini prompt, version, etc.
    usage_count INTEGER DEFAULT 0, -- Track how many times this question was used
    average_accuracy DECIMAL(5,2), -- Track average success rate
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- =====================================================
-- 3. APTITUDE TESTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.aptitude_tests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    module_id UUID REFERENCES public.aptitude_modules(id) ON DELETE SET NULL,
    test_type TEXT NOT NULL CHECK (test_type IN ('practice', 'assignment')),
    title TEXT NOT NULL,
    description TEXT,
    difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    duration_minutes INTEGER NOT NULL DEFAULT 30,
    total_questions INTEGER NOT NULL DEFAULT 20,
    passing_score INTEGER DEFAULT 60 CHECK (passing_score BETWEEN 0 AND 100),
    instructions TEXT,
    negative_marking BOOLEAN DEFAULT FALSE,
    negative_marks_per_question DECIMAL(3,2) DEFAULT 0.25,
    shuffle_questions BOOLEAN DEFAULT TRUE,
    shuffle_options BOOLEAN DEFAULT TRUE,
    show_results_immediately BOOLEAN DEFAULT TRUE,
    show_correct_answers BOOLEAN DEFAULT TRUE,
    allow_review BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES auth.users(id),
    organization_id UUID REFERENCES public.organizations(id), -- College or Company
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- =====================================================
-- 4. TEST ASSIGNMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.test_assignments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    test_id UUID REFERENCES public.aptitude_tests(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES auth.users(id), -- College admin or Recruiter
    assigned_by_role TEXT CHECK (assigned_by_role IN ('college', 'college_admin', 'recruiter', 'organization_admin')),
    organization_id UUID REFERENCES public.organizations(id),
    
    -- Assignment target (can be individual or group)
    assignment_type TEXT NOT NULL CHECK (assignment_type IN ('individual', 'department', 'batch', 'all_students', 'job_applicants')),
    assigned_to_user UUID REFERENCES auth.users(id), -- For individual assignments
    assigned_to_department TEXT, -- For department-wide assignments
    assigned_to_batch TEXT, -- For batch-wide assignments
    assigned_to_job_id UUID, -- For job applicants
    
    -- Settings
    start_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deadline TIMESTAMP WITH TIME ZONE,
    max_attempts INTEGER DEFAULT 1,
    is_mandatory BOOLEAN DEFAULT FALSE,
    weightage DECIMAL(5,2) DEFAULT 15.00, -- Points toward skill score
    
    -- Notifications
    send_notification BOOLEAN DEFAULT TRUE,
    notification_sent BOOLEAN DEFAULT FALSE,
    reminder_sent BOOLEAN DEFAULT FALSE,
    
    -- Stats
    total_assigned INTEGER DEFAULT 0,
    total_completed INTEGER DEFAULT 0,
    total_pending INTEGER DEFAULT 0,
    average_score DECIMAL(5,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- =====================================================
-- 5. APTITUDE ATTEMPTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.aptitude_attempts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    test_id UUID REFERENCES public.aptitude_tests(id) ON DELETE CASCADE,
    assignment_id UUID REFERENCES public.test_assignments(id) ON DELETE SET NULL, -- NULL for practice tests
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Test metadata
    test_type TEXT NOT NULL CHECK (test_type IN ('practice', 'assignment')),
    module_name TEXT,
    difficulty TEXT,
    
    -- Attempt details
    attempt_number INTEGER DEFAULT 1,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    end_time TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    time_remaining_seconds INTEGER,
    
    -- Questions & Answers
    questions JSONB NOT NULL, -- Array of question IDs in order shown
    answers JSONB DEFAULT '{}'::jsonb, -- Map of question_id -> selected_option_index
    marked_for_review JSONB DEFAULT '[]'::jsonb, -- Array of question IDs marked for review
    time_per_question JSONB DEFAULT '{}'::jsonb, -- Map of question_id -> seconds_spent
    
    -- Scoring
    total_questions INTEGER NOT NULL,
    attempted_questions INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    incorrect_answers INTEGER DEFAULT 0,
    unanswered INTEGER DEFAULT 0,
    score DECIMAL(5,2),
    percentage DECIMAL(5,2),
    
    -- Status
    status TEXT DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned', 'timed_out', 'submitted')),
    submitted_at TIMESTAMP WITH TIME ZONE,
    
    -- Analytics
    device_info JSONB DEFAULT '{}'::jsonb,
    browser_info JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    UNIQUE(test_id, student_id, attempt_number)
);

-- =====================================================
-- 6. INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_aptitude_questions_module ON public.aptitude_questions(module_id);
CREATE INDEX IF NOT EXISTS idx_aptitude_questions_difficulty ON public.aptitude_questions(difficulty);
CREATE INDEX IF NOT EXISTS idx_aptitude_questions_active ON public.aptitude_questions(is_active);

CREATE INDEX IF NOT EXISTS idx_aptitude_tests_module ON public.aptitude_tests(module_id);
CREATE INDEX IF NOT EXISTS idx_aptitude_tests_type ON public.aptitude_tests(test_type);
CREATE INDEX IF NOT EXISTS idx_aptitude_tests_org ON public.aptitude_tests(organization_id);

CREATE INDEX IF NOT EXISTS idx_test_assignments_test ON public.test_assignments(test_id);
CREATE INDEX IF NOT EXISTS idx_test_assignments_assigned_by ON public.test_assignments(assigned_by);
CREATE INDEX IF NOT EXISTS idx_test_assignments_org ON public.test_assignments(organization_id);
CREATE INDEX IF NOT EXISTS idx_test_assignments_user ON public.test_assignments(assigned_to_user);
CREATE INDEX IF NOT EXISTS idx_test_assignments_deadline ON public.test_assignments(deadline);

CREATE INDEX IF NOT EXISTS idx_aptitude_attempts_test ON public.aptitude_attempts(test_id);
CREATE INDEX IF NOT EXISTS idx_aptitude_attempts_student ON public.aptitude_attempts(student_id);
CREATE INDEX IF NOT EXISTS idx_aptitude_attempts_assignment ON public.aptitude_attempts(assignment_id);
CREATE INDEX IF NOT EXISTS idx_aptitude_attempts_status ON public.aptitude_attempts(status);
CREATE INDEX IF NOT EXISTS idx_aptitude_attempts_type ON public.aptitude_attempts(test_type);

-- =====================================================
-- 7. ENABLE ROW LEVEL SECURITY
-- =====================================================
ALTER TABLE public.aptitude_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aptitude_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aptitude_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aptitude_attempts ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 8. RLS POLICIES - APTITUDE MODULES
-- =====================================================
DROP POLICY IF EXISTS "Everyone can view active modules" ON public.aptitude_modules;
CREATE POLICY "Everyone can view active modules" ON public.aptitude_modules
    FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Admins can manage modules" ON public.aptitude_modules;
CREATE POLICY "Admins can manage modules" ON public.aptitude_modules
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('admin', 'super_admin')
        )
    );

-- =====================================================
-- 9. RLS POLICIES - APTITUDE QUESTIONS
-- =====================================================
DROP POLICY IF EXISTS "Authenticated users view active questions" ON public.aptitude_questions;
CREATE POLICY "Authenticated users view active questions" ON public.aptitude_questions
    FOR SELECT USING (auth.uid() IS NOT NULL AND is_active = true);

DROP POLICY IF EXISTS "Admins and college manage questions" ON public.aptitude_questions;
CREATE POLICY "Admins and college manage questions" ON public.aptitude_questions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND role IN ('admin', 'super_admin', 'college', 'college_admin', 'recruiter', 'organization_admin')
        )
    );

-- =====================================================
-- 10. RLS POLICIES - APTITUDE TESTS
-- =====================================================
DROP POLICY IF EXISTS "Students view active tests" ON public.aptitude_tests;
CREATE POLICY "Students view active tests" ON public.aptitude_tests
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND is_active = true
    );

DROP POLICY IF EXISTS "College/Recruiter manage own tests" ON public.aptitude_tests;
CREATE POLICY "College/Recruiter manage own tests" ON public.aptitude_tests
    FOR ALL USING (
        auth.uid() = created_by OR
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND (
                role IN ('admin', 'super_admin') OR
                (role IN ('college', 'college_admin', 'organization_admin') AND organization_id = aptitude_tests.organization_id)
            )
        )
    );

-- =====================================================
-- 11. RLS POLICIES - TEST ASSIGNMENTS
-- =====================================================
DROP POLICY IF EXISTS "Students view own assignments" ON public.test_assignments;
CREATE POLICY "Students view own assignments" ON public.test_assignments
    FOR SELECT USING (
        assigned_to_user = auth.uid() OR
        (assignment_type = 'all_students' AND EXISTS (
            SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'student'
        )) OR
        (assignment_type = 'department' AND EXISTS (
            SELECT 1 FROM public.student_profiles 
            WHERE id = auth.uid() 
            AND department_id::TEXT = test_assignments.assigned_to_department
        )) OR
        (assignment_type = 'batch' AND EXISTS (
            SELECT 1 FROM public.student_profiles 
            WHERE id = auth.uid() 
            AND batch_id::TEXT = test_assignments.assigned_to_batch
        ))
    );

DROP POLICY IF EXISTS "Assigners manage own assignments" ON public.test_assignments;
CREATE POLICY "Assigners manage own assignments" ON public.test_assignments
    FOR ALL USING (
        auth.uid() = assigned_by OR
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() 
            AND (
                role IN ('admin', 'super_admin') OR
                (role IN ('college', 'college_admin', 'organization_admin') AND organization_id = test_assignments.organization_id)
            )
        )
    );

-- =====================================================
-- 12. RLS POLICIES - APTITUDE ATTEMPTS
-- =====================================================
DROP POLICY IF EXISTS "Students manage own attempts" ON public.aptitude_attempts;
CREATE POLICY "Students manage own attempts" ON public.aptitude_attempts
    FOR ALL USING (auth.uid() = student_id);

DROP POLICY IF EXISTS "College/Recruiter view assigned attempts" ON public.aptitude_attempts;
CREATE POLICY "College/Recruiter view assigned attempts" ON public.aptitude_attempts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.test_assignments ta
            WHERE ta.id = aptitude_attempts.assignment_id
            AND (
                ta.assigned_by = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM public.profiles p
                    WHERE p.id = auth.uid() 
                    AND (
                        p.role IN ('admin', 'super_admin') OR
                        (p.role IN ('college', 'college_admin', 'organization_admin', 'recruiter') 
                         AND p.organization_id = ta.organization_id)
                    )
                )
            )
        )
    );

-- =====================================================
-- 13. UPDATE TRIGGERS
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_aptitude_modules_updated_at ON public.aptitude_modules;
CREATE TRIGGER update_aptitude_modules_updated_at
    BEFORE UPDATE ON public.aptitude_modules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_aptitude_questions_updated_at ON public.aptitude_questions;
CREATE TRIGGER update_aptitude_questions_updated_at
    BEFORE UPDATE ON public.aptitude_questions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_aptitude_tests_updated_at ON public.aptitude_tests;
CREATE TRIGGER update_aptitude_tests_updated_at
    BEFORE UPDATE ON public.aptitude_tests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_test_assignments_updated_at ON public.test_assignments;
CREATE TRIGGER update_test_assignments_updated_at
    BEFORE UPDATE ON public.test_assignments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 14. SEED DEFAULT MODULES
-- =====================================================
INSERT INTO public.aptitude_modules (name, description, icon, category, color_code, display_order) VALUES
('Logical Reasoning', 'Test your logical thinking and problem-solving abilities', '🧩', 'logical_reasoning', '#FF6B6B', 1),
('Quantitative Aptitude', 'Assess your mathematical and numerical skills', '🔢', 'quantitative_aptitude', '#4ECDC4', 2),
('Verbal Ability', 'Evaluate your language, grammar, and comprehension skills', '📚', 'verbal_ability', '#45B7D1', 3),
('Technical Aptitude', 'Test your technical knowledge and reasoning', '⚙️', 'technical', '#96CEB4', 4),
('General Knowledge', 'Assess your awareness of current affairs and general knowledge', '🌍', 'general_knowledge', '#FFEAA7', 5)
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
SELECT 'Migration 009: Aptitude Testing System created successfully' as status;
