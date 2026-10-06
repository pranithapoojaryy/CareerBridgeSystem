-- FIX ANALYTICS COLUMNS
-- The error "column does not exist" happens because the table already existed with an older structure.
-- This script adds the missing columns required by the new Analytics functions.

-- 1. Add 'last_accessed_at' to student_lecture_progress if missing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'student_lecture_progress' 
        AND column_name = 'last_accessed_at'
    ) THEN
        ALTER TABLE public.student_lecture_progress 
        ADD COLUMN last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- 2. Add 'details' to student_assessment_submissions if missing (just in case)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'student_assessment_submissions' 
        AND column_name = 'details'
    ) THEN
        ALTER TABLE public.student_assessment_submissions 
        ADD COLUMN details JSONB DEFAULT '{}'::jsonb;
    END IF;
END $$;

-- 3. Verify the fix by running the Active Students count query manually
SELECT COUNT(DISTINCT slp.student_id) as active_students_check
FROM student_lecture_progress slp
JOIN profiles p ON slp.student_id = p.id
LIMIT 1;
