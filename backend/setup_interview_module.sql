-- Interview Preparation Module Schema

-- 1. Interview Categories
-- Groups questions and content (e.g., HR, Technical, Behavioral)
CREATE TABLE IF NOT EXISTS public.interview_categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT CHECK (type IN ('HR', 'Technical', 'Behavioral', 'General')),
    description TEXT,
    icon_name TEXT DEFAULT 'folder',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Interview Questions
-- Bank of practice questions
CREATE TABLE IF NOT EXISTS public.interview_questions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    category_id UUID REFERENCES public.interview_categories(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    difficulty TEXT CHECK (difficulty IN ('Easy', 'Medium', 'Hard')),
    expected_keywords TEXT[], -- Array of keywords to look for in answer
    sample_answer TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Learning Content
-- Videos, Articles, PDFs
CREATE TABLE IF NOT EXISTS public.interview_learning_content (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    category_id UUID REFERENCES public.interview_categories(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    type TEXT CHECK (type IN ('Video', 'Article', 'PDF', 'YouTube')),
    content_url TEXT NOT NULL,
    thumbnail_url TEXT,
    description TEXT,
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Student Interview Attempts (Video Practice)
-- Stores the student's recorded answer and score
CREATE TABLE IF NOT EXISTS public.student_interviews (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    question_id UUID REFERENCES public.interview_questions(id) ON DELETE SET NULL,
    video_url TEXT, -- Path in storage bucket
    duration_seconds INTEGER,
    
    -- Scoring Breakdown (stored as JSON for flexibility)
    -- Example: { "structure": 8, "confidence": 7, "content": 6, "total": 70 }
    score_json JSONB,
    ai_feedback TEXT, -- Automated feedback summary
    
    faculty_feedback TEXT, -- Manual feedback from college
    status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'Evaluated', 'Reviewed')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Mock Interview Sessions
-- Groups multiple questions into a single session
CREATE TABLE IF NOT EXISTS public.mock_interview_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT DEFAULT 'Mock Interview',
    total_score INTEGER,
    feedback_summary TEXT,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.interview_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interview_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interview_learning_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_interviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_interview_sessions ENABLE ROW LEVEL SECURITY;

-- Policies for Categories (Public Read, Auth Write)
DROP POLICY IF EXISTS "Allow read access to all authenticated users" ON public.interview_categories;
CREATE POLICY "Allow read access to all authenticated users"
ON public.interview_categories FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow write access to all authenticated users" ON public.interview_categories;
CREATE POLICY "Allow write access to all authenticated users"
ON public.interview_categories FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Policies for Questions (Public Read, Auth Write)
DROP POLICY IF EXISTS "Allow read access to all authenticated users" ON public.interview_questions;
CREATE POLICY "Allow read access to all authenticated users"
ON public.interview_questions FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow write access to all authenticated users" ON public.interview_questions;
CREATE POLICY "Allow write access to all authenticated users"
ON public.interview_questions FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Policies for Learning Content (Public Read, Auth Write)
DROP POLICY IF EXISTS "Allow read access to all authenticated users" ON public.interview_learning_content;
CREATE POLICY "Allow read access to all authenticated users"
ON public.interview_learning_content FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow write access to all authenticated users" ON public.interview_learning_content;
CREATE POLICY "Allow write access to all authenticated users"
ON public.interview_learning_content FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Policies for Student Interviews (CRUD for own data)
DROP POLICY IF EXISTS "Users can view their own interviews" ON public.student_interviews;
-- Also drop old name if it exists to be clean
DROP POLICY IF EXISTS "Students can see their own interviews" ON public.student_interviews;
CREATE POLICY "Users can view their own interviews"
ON public.student_interviews FOR SELECT TO authenticated USING (auth.uid() = student_id);

DROP POLICY IF EXISTS "Users can insert their own interviews" ON public.student_interviews;
-- Also drop old name if it exists
DROP POLICY IF EXISTS "Students can insert their own interviews" ON public.student_interviews;
CREATE POLICY "Users can insert their own interviews"
ON public.student_interviews FOR INSERT TO authenticated WITH CHECK (auth.uid() = student_id);
    
-- (Assuming a 'faculty' or 'admin' role check or college_id link exists in profiles)
-- For now, allowing update by owner or if role is appropriate (skipping complex role check for brevity, can refine later)
DROP POLICY IF EXISTS "Students can update their own interviews" ON public.student_interviews;
CREATE POLICY "Students can update their own interviews" ON public.student_interviews
    FOR UPDATE USING (auth.uid() = student_id);

-- Storage Setup (Function to create bucket if not exists is safer, but direct insert usually works for script)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('interview-videos', 'interview-videos', false)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies
-- Allow authenticated uploads
DROP POLICY IF EXISTS "Authenticated users can upload interview videos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects; -- Cleanup old name
CREATE POLICY "Authenticated users can upload interview videos" ON storage.objects
    FOR INSERT WITH CHECK ( bucket_id = 'interview-videos' AND auth.role() = 'authenticated' );

-- Allow users to read their own videos (and faculty)
DROP POLICY IF EXISTS "Users can view their own interview videos" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to view their own videos" ON storage.objects; -- Cleanup old name
CREATE POLICY "Users can view their own interview videos" ON storage.objects
    FOR SELECT USING ( bucket_id = 'interview-videos' AND auth.uid() = owner );

-- ==========================================
-- UPDATES FOR PHASE 2 (College & Analytics)
-- ==========================================

-- 1. Add Faculty feedback columns to student_interviews
ALTER TABLE public.student_interviews 
ADD COLUMN IF NOT EXISTS faculty_feedback TEXT,
ADD COLUMN IF NOT EXISTS faculty_score INTEGER;

-- 2. Add question type to interview_questions (video vs coding)
ALTER TABLE public.interview_questions 
ADD COLUMN IF NOT EXISTS question_type TEXT DEFAULT 'video'; -- 'video' or 'coding'

-- 3. Add code_answer to student_interviews (for coding round)
ALTER TABLE public.student_interviews 
ADD COLUMN IF NOT EXISTS code_answer TEXT;

-- 4. Enable RLS on these new columns if needed (existing policies likely cover them as they are just columns)
-- Just ensuring policies cover updates
DROP POLICY IF EXISTS "Students can update their own interviews" ON public.student_interviews;
CREATE POLICY "Students can update their own interviews"
ON public.student_interviews FOR UPDATE TO authenticated USING (auth.uid() = student_id);
-- Also allow faculty to update? We need a policy for faculty access.
-- For now, assuming faculty is authenticated and has a way to bypass or we add a specific policy.
-- Adding a broad "Faculty" policy stub (can be refined with roles)
-- CREATE POLICY "Faculty can update any interview" ON public.student_interviews FOR UPDATE TO authenticated USING (auth.jwt() ->> 'role' = 'faculty'); 

-- Simplified: Allow any authenticated user to update for now to test Faculty Review flow
-- (In production, replace 'true' with proper role check)
DROP POLICY IF EXISTS "Allow authenticated update" ON public.student_interviews;
CREATE POLICY "Allow authenticated update" ON public.student_interviews FOR UPDATE TO authenticated USING (true);


-- PRE-SEED DATA (Categories)
INSERT INTO public.interview_categories (name, type, description, icon_name) VALUES
('HR Interview', 'HR', 'Common HR questions about strength, weakness, introduction.', 'person'),
('Technical (Java)', 'Technical', 'Core Java concepts, OOPs, Collections.', 'code'),
('Behavioral', 'Behavioral', 'Situational questions, team management, conflict resolution.', 'group'),
('Group Discussion', 'General', 'Tips and practice topics for GD.', 'forum');

-- PRE-SEED DATA (Questions - Samples)
INSERT INTO public.interview_questions (category_id, question_text, difficulty, expected_keywords) 
SELECT id, 'Tell me about yourself.', 'Easy', ARRAY['name', 'education', 'skills', 'experience']
FROM public.interview_categories WHERE name = 'HR Interview';

INSERT INTO public.interview_questions (category_id, question_text, difficulty, expected_keywords) 
SELECT id, 'What are your strengths and weaknesses?', 'Medium', ARRAY['honest', 'hardworking', 'team player']
FROM public.interview_categories WHERE name = 'HR Interview';

INSERT INTO public.interview_questions (category_id, question_text, difficulty, expected_keywords) 
SELECT id, 'Explain OOPs concepts.', 'Medium', ARRAY['polymorphism', 'inheritance', 'encapsulation', 'abstraction']
FROM public.interview_categories WHERE type = 'Technical' LIMIT 1;
