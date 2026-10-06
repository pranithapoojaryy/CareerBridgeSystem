-- Fix Foreign Keys to reference public.profiles instead of auth.users
-- This allows PostgREST to automatically join with the profiles table to fetch names/avatars.

-- 1. Drop existing constraints (names might vary, so using DO block or specific names if known)
-- We created them as:
-- resume_feedback_student_id_fkey referencing auth.users
-- resume_feedback_provider_id_fkey referencing auth.users

ALTER TABLE public.resume_feedback DROP CONSTRAINT IF EXISTS resume_feedback_student_id_fkey;
ALTER TABLE public.resume_feedback DROP CONSTRAINT IF EXISTS resume_feedback_provider_id_fkey;

-- 2. Add new constraints referencing public.profiles
-- Ensure profiles exist first (they should)

ALTER TABLE public.resume_feedback
ADD CONSTRAINT resume_feedback_student_id_fkey_profiles
FOREIGN KEY (student_id)
REFERENCES public.profiles(id)
ON DELETE CASCADE;

ALTER TABLE public.resume_feedback
ADD CONSTRAINT resume_feedback_provider_id_fkey_profiles
FOREIGN KEY (provider_id)
REFERENCES public.profiles(id)
ON DELETE SET NULL; -- If provider is deleted, keep feedback but nullify? Or Cascade? Let's say Set NULL or CASCADE.
