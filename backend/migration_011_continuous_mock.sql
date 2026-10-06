-- Migration 011: Continuous Mock Video Support

-- 1. Add video field to Mock Attempts (for the single continuous recording)
ALTER TABLE public.mock_attempts
ADD COLUMN IF NOT EXISTS video_path TEXT;

-- 2. Add timestamps to Student Interviews (to segregate answers in the single video)
-- We store offset in seconds (or null if it's a coding question)
ALTER TABLE public.student_interviews
ADD COLUMN IF NOT EXISTS answer_start_offset INTEGER,
ADD COLUMN IF NOT EXISTS answer_end_offset INTEGER;
