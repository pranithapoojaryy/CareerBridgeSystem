-- Fix: Sync avatar_url from auth.users metadata to public.profiles

-- 1. Update the handle_new_user function to include avatar_url for NEW users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'role', 'student'), -- Default to student if missing
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.email),
    NEW.raw_user_meta_data ->> 'avatar_url' -- Capture Google/Auth avatar
  );
  RETURN NEW;
END;
$$;

-- 2. Backfill: Update EXISTING profiles that have missing avatars
-- We join public.profiles with auth.users to pull the data
DO $$
BEGIN
    UPDATE public.profiles p
    SET avatar_url = u.raw_user_meta_data ->> 'avatar_url'
    FROM auth.users u
    WHERE p.id = u.id
      AND (p.avatar_url IS NULL OR p.avatar_url = '')
      AND u.raw_user_meta_data ->> 'avatar_url' IS NOT NULL;
      
    -- Also update full_name if missing
    UPDATE public.profiles p
    SET full_name = u.raw_user_meta_data ->> 'full_name'
    FROM auth.users u
    WHERE p.id = u.id
      AND (p.full_name IS NULL OR p.full_name = '' OR p.full_name = u.email)
      AND u.raw_user_meta_data ->> 'full_name' IS NOT NULL;
END $$;
