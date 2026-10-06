-- Fix missing column in assessment_skill_mapping
ALTER TABLE public.assessment_skill_mapping 
ADD COLUMN IF NOT EXISTS skill_category TEXT;

-- Verify keys (optional, but good practice)
-- Ensure unique constraint respects the new column? No, unique key is (assessment_id, skill_name). Category is just attribute.

-- Also ensure RLS policies are correct for student_assessment_submissions (to help with duplicate key debugging)
-- (We can't easily see existing policies, but we can re-assert them if needed)
-- For now, let's just fix the crash.
