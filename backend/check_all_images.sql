-- Check all possible image columns
SELECT id, full_name, email, avatar_url, profile_image_url, profile_photo_url
FROM public.profiles 
ORDER BY created_at DESC 
LIMIT 10;
