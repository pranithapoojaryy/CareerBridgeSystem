-- =====================================================
-- FIX STORAGE RLS POLICIES ONLY
-- =====================================================
-- This script only fixes the profile photo upload issue

-- 1. Ensure profile_photo_url column exists
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

-- 2. Fix Storage RLS Policies for profile_photos
-- Drop existing policies
DROP POLICY IF EXISTS "Users can upload their own profile photo" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile photo" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile photo" ON storage.objects;
DROP POLICY IF EXISTS "Profile photos are publicly accessible" ON storage.objects;

-- Create new policies with correct path handling
CREATE POLICY "Users can upload their own profile photo" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'profile_photos' AND 
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can update their own profile photo" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'profile_photos' AND vojiogjiojrtortgopkrttgokefpfkd m mc f53poy876k99463
    0  503
    j62
    5u4=t;l;mmzlma, .km4;4t6\=]\\ji,o2o'/5486
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete their own profile photo" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'profile_photos' AND 
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Profile photos are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'profile_photos');

-- 3. Ensure the profile_photos bucket exists
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile_photos',
  'profile_photos',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

SELECT 'Storage policies fixed! Profile photo upload should work now.' as status;8io4ol57787+0opl/k6+6+03.0/.