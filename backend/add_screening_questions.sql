-- Add screening_questions column to jobs table for video interview setup
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS screening_questions JSONB DEFAULT '[]'::jsonb;

-- Comment on column
COMMENT ON COLUMN jobs.screening_questions IS 'List of questions for video screening interview';
