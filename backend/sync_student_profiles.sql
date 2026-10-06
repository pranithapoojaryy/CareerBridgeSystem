-- Migration: Synchronize student profile data across profiles and student_profiles tables
-- Reason: Ensure data consistency after simplifying the profile setup flow

-- 1. Sync data from student_profiles to profiles for students (where profiles has nulls)
UPDATE public.profiles p
SET 
  skills = COALESCE(p.skills, sp.skills),
  interests = COALESCE(p.interests, sp.interests),
  linkedin_url = COALESCE(p.linkedin_url, sp.linkedin_url),
  github_url = COALESCE(p.github_url, sp.github_url),
  portfolio_url = COALESCE(p.portfolio_url, sp.portfolio_url)
FROM public.student_profiles sp
WHERE p.id = sp.id AND p.role = 'student';

-- 2. Sync data from profiles to student_profiles (where student_profiles has nulls)
UPDATE public.student_profiles sp
SET 
  skills = COALESCE(sp.skills, p.skills),
  interests = COALESCE(sp.interests, p.interests),
  linkedin_url = COALESCE(sp.linkedin_url, p.linkedin_url),
  github_url = COALESCE(sp.github_url, p.github_url),
  portfolio_url = COALESCE(sp.portfolio_url, p.portfolio_url)
FROM public.profiles p
WHERE p.id = sp.id AND p.role = 'student';

-- 3. Mark all student profiles as complete in the profiles table if they have base data
UPDATE public.profiles
SET is_profile_complete = true, profile_completion = 100
WHERE role = 'student' AND (bio IS NOT NULL OR skills IS NOT NULL);
