-- =====================================================
-- SETUP RESUME SYSTEM
-- =====================================================
-- Run this to add resume builder functionality

\i migration_006_resume_system.sql

-- Add skills column to profiles if it doesn't exist (for resume pre-filling)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS skills JSONB DEFAULT '[]'::jsonb;

-- Success message
SELECT 'Resume system setup completed successfully!' as status;