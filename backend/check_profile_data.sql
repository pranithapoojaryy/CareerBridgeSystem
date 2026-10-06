-- Check profile data to see if images are actually present
SELECT id, full_name, email, avatar_url, profile_image_url 
FROM public.profiles 
ORDER BY created_at DESC 
LIMIT 10;
