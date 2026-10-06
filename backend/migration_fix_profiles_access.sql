-- Allow all authenticated users to view public profile information
-- This is necessary for students to see the name/avatar of the reviewer in feedback, 
-- and for general networking features.

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone"
ON public.profiles
FOR SELECT
USING ( output IS NOT NULL ); -- A trick, better is distinct policy or boolean true

-- Let's use a standard policy
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON public.profiles;
CREATE POLICY "Profiles are viewable by authenticated users"
ON public.profiles
FOR SELECT
TO authenticated
USING (true);

-- Ensure RLS is enabled (should be already)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
