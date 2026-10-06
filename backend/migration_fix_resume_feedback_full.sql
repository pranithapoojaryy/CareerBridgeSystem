-- Comprehensive fix for Resume Feedback table and policies

-- 1. Ensure Table Exists
CREATE TABLE IF NOT EXISTS public.resume_feedback (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES auth.users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Enable RLS
ALTER TABLE public.resume_feedback ENABLE ROW LEVEL SECURITY;

-- 3. Policy: Students can view their own feedback
DROP POLICY IF EXISTS "Students can view own resume feedback" ON public.resume_feedback;
CREATE POLICY "Students can view own resume feedback"
ON public.resume_feedback
FOR SELECT
USING (auth.uid() = student_id);

-- 4. Policy: Reviewers (College Admins/Recruiters) management
DROP POLICY IF EXISTS "Reviewers can manage feedback" ON public.resume_feedback;
CREATE POLICY "Reviewers can manage feedback"
ON public.resume_feedback
FOR ALL
USING (
  -- User matches the provider_id (created it)
  auth.uid() = provider_id 
  OR 
  -- Or belongs to a reviewer role
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() 
    AND role IN ('college_admin', 'college', 'recruiter')
  )
);

-- 5. Grants (just in case)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.resume_feedback TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE resume_feedback_id_seq TO authenticated; -- If serial, though uuid uses gen_random_uuid()
