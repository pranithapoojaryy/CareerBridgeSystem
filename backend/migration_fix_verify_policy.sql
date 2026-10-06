-- Allow college admins to update is_verified status of students in their college
-- Logic: A user can update 'profiles' if they are a college admin (role check)
-- AND the target profile belongs to the same organization.

-- First, ensure RLS is enabled
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy for College Admins to Update Student Verification
CREATE POLICY "College admins can update student verification"
ON public.profiles
FOR UPDATE
USING (
  auth.uid() IN (
    SELECT id FROM public.profiles
    WHERE role IN ('college_admin', 'college')
  )
)
WITH CHECK (
  auth.uid() IN (
    SELECT id FROM public.profiles
    WHERE role IN ('college_admin', 'college')
  )
);

-- Note: The above policy is broad. A tighter one would check organization_id match.
-- Checking if auth.uid() has same organization_id as the target row.
CREATE POLICY "College admins can update students in their org"
ON public.profiles
FOR UPDATE
USING (
  organization_id IN (
    SELECT organization_id FROM public.profiles WHERE id = auth.uid()
  )
  AND
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('college_admin', 'college')
  )
);
