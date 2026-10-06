-- Allow college admins to update student_profiles
-- This is necessary because is_verified exists on both tables and we need to sync them,
-- or triggers might be cascading updates.

BEGIN;

-- Enable RLS on student_profiles if not already
ALTER TABLE public.student_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing college policy if exists (to be safe)
DROP POLICY IF EXISTS "College admins can update student profiles extension" ON public.student_profiles;

-- Create policy for College Admins to update student_profiles
CREATE POLICY "College admins can update student profiles extension"
ON public.student_profiles
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = student_profiles.id
    AND profiles.organization_id IN (
      SELECT organization_id FROM public.profiles WHERE id = auth.uid()
    )
  )
  AND
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('college_admin', 'college')
  )
);

COMMIT;
