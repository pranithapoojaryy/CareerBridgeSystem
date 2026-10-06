-- =====================================================
-- SETUP PROFILE PHOTOS SYSTEM
-- =====================================================
-- Run this to add profile photo functionality

-- Add profile_photo_url column to profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

-- Run storage setup
\i migration_007_storage_setup.sql

-- Success message
SELECT 'Profile photos system setup completed successfully!' as status;