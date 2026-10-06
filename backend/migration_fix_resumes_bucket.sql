-- Ensure the 'resumes' bucket exists and is public
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'resumes', 
  'resumes', 
  true, 
  5242880, -- 5MB limit
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO UPDATE SET 
  public = true,
  allowed_mime_types = ARRAY['application/pdf'];

-- Helper policy to allow public read access for resumes
DROP POLICY IF EXISTS "Public Resumes Access" ON storage.objects;
CREATE POLICY "Public Resumes Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'resumes' );

-- Allow authenticated users to upload their own resumes
DROP POLICY IF EXISTS "User Upload Resume" ON storage.objects;
CREATE POLICY "User Upload Resume"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'resumes' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to update their own resumes
DROP POLICY IF EXISTS "User Update Resume" ON storage.objects;
CREATE POLICY "User Update Resume"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'resumes' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to delete their own resumes
DROP POLICY IF EXISTS "User Delete Resume" ON storage.objects;
CREATE POLICY "User Delete Resume"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'resumes' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
