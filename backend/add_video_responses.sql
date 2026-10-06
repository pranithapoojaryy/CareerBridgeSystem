-- Add video_responses column to job_applications table
ALTER TABLE job_applications 
ADD COLUMN IF NOT EXISTS video_responses JSONB DEFAULT '[]'::jsonb;

-- Comment on column
COMMENT ON COLUMN job_applications.video_responses IS 'List of video interview Q&A';
