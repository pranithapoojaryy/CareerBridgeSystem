-- FIX SCRIPT FOR 500 ERROR
-- Run this in Supabase SQL Editor

-- 1. Ensure 'role' in profiles has no restrictive constraints
DO $$ 
BEGIN 
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'profiles_role_check') THEN 
        ALTER TABLE public.profiles DROP CONSTRAINT profiles_role_check; 
    END IF; 
END $$;

-- 2. Make sure the trigger handles NULLs and CONFLICTS gracefully
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, full_name)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data ->> 'role', 'student'),
    COALESCE(new.raw_user_meta_data ->> 'full_name', '')
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    full_name = EXCLUDED.full_name;
  RETURN new;
END;
$$;
