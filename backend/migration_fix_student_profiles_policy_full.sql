-- Allow college admins to fully manage student_profiles (SELECT, UPDATE)
-- This replaces previous partial policies.

BEGIN;

-- Drop existing college policies on student_profiles
DROP POLICY IF EXISTS "College admins can update student profiles extension" ON public.student_profiles;
DROP POLICY IF EXISTS "College admins can manage student profiles" ON public.student_profiles;

-- Create comprehensive policy for College Admins
CREATE POLICY "College admins can manage student profiles"
ON public.student_profiles
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.profiles AS p_student
    JOIN public.profiles AS p_admin ON p_student.organization_id = p_admin.organization_id
    WHERE p_student.id = student_profiles.id
    AND p_admin.id = auth.uid()
    AND p_admin.role IN ('college_admin', 'college')
  )
);

COMMIT;
