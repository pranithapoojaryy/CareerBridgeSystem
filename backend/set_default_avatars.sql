-- Fix: Set default avatar_url for users who have NO photo
-- Uses ui-avatars.com to generate an image based on their name

UPDATE public.profiles
SET 
  avatar_url = 'https://ui-avatars.com/api/?name=' || regexp_replace(full_name, ' ', '+', 'g') || '&background=random&color=fff&size=512',
  profile_image_url = 'https://ui-avatars.com/api/?name=' || regexp_replace(full_name, ' ', '+', 'g') || '&background=random&color=fff&size=512'
WHERE 
  (profile_image_url IS NULL OR profile_image_url = '') 
  AND (avatar_url IS NULL OR avatar_url = '');

-- Also update the trigger to default to this if no avatar provided
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  default_avatar TEXT;
BEGIN
  default_avatar := 'https://ui-avatars.com/api/?name=' || regexp_replace(COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.email), ' ', '+', 'g') || '&background=random&color=fff&size=512';
  
  INSERT INTO public.profiles (id, email, role, full_name, avatar_url, profile_image_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'role', 'student'),
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data ->> 'avatar_url', NEW.raw_user_meta_data ->> 'picture', default_avatar), 
    COALESCE(NEW.raw_user_meta_data ->> 'avatar_url', NEW.raw_user_meta_data ->> 'picture', default_avatar)
  );
  RETURN NEW;
END;
$$;
