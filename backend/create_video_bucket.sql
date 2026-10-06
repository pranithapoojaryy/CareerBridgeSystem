-- Create the video_interviews bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('video_interviews', 'video_interviews', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing policies to avoid conflicts if re-running
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Upload" ON storage.objects;
DROP POLICY IF EXISTS "Individual Update" ON storage.objects;
DROP POLICY IF EXISTS "Individual Delete" ON storage.objects;

-- Set up RLS policies for the bucket

-- Allow public access to view videos
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'video_interviews' );

-- Allow authenticated users to upload their own videos
CREATE POLICY "Authenticated Upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'video_interviews' 
  AND auth.role() = 'authenticated'
);

-- Allow users to update/delete their own videos (optional but good for cleanup)
CREATE POLICY "Individual Update"
ON storage.objects FOR UPDATE
USING ( auth.uid() = owner )
WITH CHECK ( bucket_id = 'video_interviews' );

CREATE POLICY "Individual Delete"
ON storage.objects FOR DELETE
USING ( auth.uid() = owner AND bucket_id = 'video_interviews' );
