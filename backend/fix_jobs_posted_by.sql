-- Add posted_by column to jobs table
-- This column tracks which recruiter posted the job

ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS posted_by UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_jobs_posted_by ON jobs(posted_by);

-- Update existing jobs to set posted_by if possible
-- (This is optional - only if you want to backfill data)
-- UPDATE jobs SET posted_by = recruiter_id WHERE posted_by IS NULL AND recruiter_id IS NOT NULL;
