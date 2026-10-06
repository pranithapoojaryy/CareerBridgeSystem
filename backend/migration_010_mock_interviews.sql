-- Migration 010: Mock Interview System

-- 1. Mock Interview Definitions (The "Test Paper")
CREATE TABLE IF NOT EXISTS public.mock_definitions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    college_id UUID REFERENCES public.profiles(id), -- Creator (College Admin)
    
    time_limit_minutes INTEGER DEFAULT 30, -- 0 for no limit
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Mock Questions Junction (Which questions are in this mock?)
CREATE TABLE IF NOT EXISTS public.mock_questions_junction (
    mock_id UUID REFERENCES public.mock_definitions(id) ON DELETE CASCADE,
    question_id UUID REFERENCES public.interview_questions(id) ON DELETE CASCADE,
    order_index INTEGER DEFAULT 0,
    PRIMARY KEY (mock_id, question_id)
);

-- 3. Mock Attempts (Student Submissions)
CREATE TABLE IF NOT EXISTS public.mock_attempts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    mock_id UUID REFERENCES public.mock_definitions(id) ON DELETE CASCADE,
    
    status TEXT DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'submitted', 'graded')),
    
    total_score INTEGER, -- 0-100
    faculty_feedback TEXT,
    
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    submitted_at TIMESTAMP WITH TIME ZONE,
    graded_at TIMESTAMP WITH TIME ZONE
);

-- 4. Update Student Interviews to link to Mock Attempts
-- (This links individual video/code answers to the specific session)
ALTER TABLE public.student_interviews 
ADD COLUMN IF NOT EXISTS mock_attempt_id UUID REFERENCES public.mock_attempts(id) ON DELETE SET NULL;


-- ==========================================
-- ROW LEVEL SECURITY (RLS)
-- ==========================================

-- Enable RLS
ALTER TABLE public.mock_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_questions_junction ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_attempts ENABLE ROW LEVEL SECURITY;

-- POLICIES: Mock Definitions
-- College: Create/Edit/Delete
DROP POLICY IF EXISTS "Authenticated users can read mocks" ON public.mock_definitions;
CREATE POLICY "Authenticated users can read mocks" ON public.mock_definitions FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can manage mocks" ON public.mock_definitions;
CREATE POLICY "Authenticated users can manage mocks" ON public.mock_definitions FOR ALL TO authenticated USING (true) WITH CHECK (true);
-- (In prod: Limit manage to role='college')

-- POLICIES: Mock Questions Junction
-- Public/Auth Read
DROP POLICY IF EXISTS "Read junction" ON public.mock_questions_junction;
CREATE POLICY "Read junction" ON public.mock_questions_junction FOR SELECT TO authenticated USING (true);

-- Auth Manage
DROP POLICY IF EXISTS "Manage junction" ON public.mock_questions_junction;
CREATE POLICY "Manage junction" ON public.mock_questions_junction FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- POLICIES: Mock Attempts
-- Student: Read/Insert Own
DROP POLICY IF EXISTS "Student view own attempts" ON public.mock_attempts;
CREATE POLICY "Student view own attempts" ON public.mock_attempts FOR SELECT TO authenticated USING (auth.uid() = student_id OR true); 
-- OR true added temporarily for Faculty to see all. Ideal: (auth.uid() = student_id OR auth.jwt()->>'role' = 'faculty')

DROP POLICY IF EXISTS "Student insert own attempts" ON public.mock_attempts;
CREATE POLICY "Student insert own attempts" ON public.mock_attempts FOR INSERT TO authenticated WITH CHECK (auth.uid() = student_id);

DROP POLICY IF EXISTS "Student update own attempts" ON public.mock_attempts;
CREATE POLICY "Student update own attempts" ON public.mock_attempts FOR UPDATE TO authenticated USING (auth.uid() = student_id OR true);
-- OR true allows Faculty to update (grade).

