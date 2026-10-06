-- Fix: Remove triggers that try to write to student_stats view
-- student_stats is now a view, so we cannot insert/update it directly.

-- 1. Drop trigger on aptitude_attempts
DROP TRIGGER IF EXISTS trg_update_skill_score_aptitude ON public.aptitude_attempts;
DROP FUNCTION IF EXISTS public.update_skill_score_on_aptitude_completion();

-- 2. Drop triggers on student_certifications and posts
DROP TRIGGER IF EXISTS trg_update_stats_certs ON public.student_certifications;
DROP TRIGGER IF EXISTS trg_update_stats_posts ON public.posts;

-- 3. Drop the function used by certs/posts triggers
DROP FUNCTION IF EXISTS public.update_student_stats_trigger();

-- 4. Verify status
SELECT 'Triggers dropped successfully' as status;
