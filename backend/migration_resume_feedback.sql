-- Migration for Resume Feedback and Storage

BEGIN;

-- 1. Create resume_feedback table
CREATE TABLE IF NOT EXISTS public.resume_feedback (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES auth.users(id), -- Reviewer (College/Recruiter)
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. RLS for resume_feedback
ALTER TABLE public.resume_feedback ENABLE ROW LEVEL SECURITY;

-- Policy: Students can view their own feedback
CREATE POLICY "Students can view own resume feedback"
ON public.resume_feedback
FOR SELECT
USING (auth.uid() = student_id);

-- Policy: College Admins/Recruiters can view and insert feedback
-- (Simplified: Allow any authenticated user to insert for now, checking logic in app or trigger later if strictness needed. 
-- Ideally we check if provider_id matches auth.uid())
CREATE POLICY "Reviewers can manage feedback"
ON public.resume_feedback
FOR ALL
USING (auth.uid() = provider_id OR 
       EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('college_admin', 'college', 'recruiter')));

-- 3. Storage Bucket Setup (Idempotent)
INSERT INTO storage.buckets (id, name, public)
VALUES ('resumes', 'resumes', true)
ON CONFLICT (id) DO NOTHING;

-- 4. Storage Policies
-- Allow authenticated users to upload their own resume
CREATE POLICY "Users can upload their own resume"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'resumes' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow authenticated users to update/delete their own resume
CREATE POLICY "Users can update their own resume"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'resumes' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own resume"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'resumes' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow public read access to resumes (or restricted to auth users)
CREATE POLICY "Public read access to resumes"
ON storage.objects
FOR SELECT
USING (bucket_id = 'resumes');

COMMIT;
