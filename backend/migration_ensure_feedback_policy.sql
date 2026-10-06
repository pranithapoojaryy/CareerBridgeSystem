-- Ensure robust RLS policies for resume_feedback

-- 1. Students can view their own feedback
DROP POLICY IF EXISTS "Students can view own resume feedback" ON public.resume_feedback;
CREATE POLICY "Students can view own resume feedback"
ON public.resume_feedback
FOR SELECT
USING (auth.uid() = student_id);

-- 2. Reviewers (College Admins/Recruiters) can view feedback they gave OR all feedback (depending on requirement)
-- For now, let's allow them to see feedback they created, AND let's ensure they can INSERT.
DROP POLICY IF EXISTS "Reviewers can manage feedback" ON public.resume_feedback;
CREATE POLICY "Reviewers can manage feedback"
ON public.resume_feedback
FOR ALL
USING (
  -- User can modify their own feedback
  auth.uid() = provider_id 
  OR 
  -- College Admins and Recruiters can access
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() 
    AND role IN ('college_admin', 'college', 'recruiter')
  )
);
