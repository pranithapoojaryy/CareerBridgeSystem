-- Setup Storage for Post Images

-- 1. Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'post_images', 
    'post_images', 
    true, 
    5242880, -- 5MB limit
    '{image/png, image/jpeg, image/gif, image/webp}'
)
ON CONFLICT (id) DO UPDATE SET 
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = '{image/png, image/jpeg, image/gif, image/webp}';

-- 2. Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Public Access to Post Images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Users Can Upload Post Images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own post images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own post images" ON storage.objects;

-- 3. Create RLS Policies

-- Public Read Access
CREATE POLICY "Public Access to Post Images"
ON storage.objects FOR SELECT
USING ( bucket_id = 'post_images' );

-- Authenticated Upload Access (Insert)
CREATE POLICY "Authenticated Users Can Upload Post Images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'post_images' AND
    auth.role() = 'authenticated'
);

-- Owner Update Access
CREATE POLICY "Users can update own post images"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'post_images' AND
    auth.uid() = owner
);

-- Owner Delete Access
CREATE POLICY "Users can delete own post images"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'post_images' AND
    auth.uid() = owner
);
