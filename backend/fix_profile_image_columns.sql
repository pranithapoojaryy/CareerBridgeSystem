-- Fix: Synchronize ALL profile columns: avatar_url, profile_image_url, AND profile_photo_url
-- This script ensures that if ANY of these columns has data, the others get it too.

-- 1. Ensure all columns exist
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS profile_image_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

-- 2. Backfill Logic
DO $$
BEGIN
    -- Case 1: Master is profile_photo_url (used by ImageService)
    -- Sync profile_photo_url -> avatar_url & profile_image_url
    UPDATE public.profiles
    SET 
        avatar_url = profile_photo_url,
        profile_image_url = profile_photo_url
    WHERE (profile_photo_url IS NOT NULL AND profile_photo_url <> '')
      AND (avatar_url IS NULL OR avatar_url = '');

    -- Case 2: Master is avatar_url (used by Auth/Google)
    -- Sync avatar_url -> profile_photo_url & profile_image_url
    UPDATE public.profiles
    SET 
        profile_photo_url = avatar_url,
        profile_image_url = avatar_url
    WHERE (avatar_url IS NOT NULL AND avatar_url <> '')
      AND (profile_photo_url IS NULL OR profile_photo_url = '');

    -- Case 3: Sync Metadata (Google Auth 'picture' or 'avatar_url') if ALL are empty
    UPDATE public.profiles p
    SET 
        profile_photo_url = COALESCE(u.raw_user_meta_data ->> 'avatar_url', u.raw_user_meta_data ->> 'picture'),
        profile_image_url = COALESCE(u.raw_user_meta_data ->> 'avatar_url', u.raw_user_meta_data ->> 'picture'),
        avatar_url = COALESCE(u.raw_user_meta_data ->> 'avatar_url', u.raw_user_meta_data ->> 'picture')
    FROM auth.users u
    WHERE p.id = u.id
      AND (p.profile_photo_url IS NULL OR p.profile_photo_url = '')
      AND (u.raw_user_meta_data ->> 'avatar_url' IS NOT NULL OR u.raw_user_meta_data ->> 'picture' IS NOT NULL);

END $$;

-- 3. Update Trigger to populate ALL columns for new users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  url TEXT;
BEGIN
  url := COALESCE(NEW.raw_user_meta_data ->> 'avatar_url', NEW.raw_user_meta_data ->> 'picture');

  INSERT INTO public.profiles (id, email, role, full_name, avatar_url, profile_image_url, profile_photo_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'role', 'student'),
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.email),
    url, -- avatar_url
    url, -- profile_image_url
    url  -- profile_photo_url
  );
  RETURN NEW;
END;
$$;
