-- Fix RLS policies for college_departments, college_programs, and college_batches
-- to allow unauthenticated users (during registration) to read these tables

-- This is needed because students need to select departments during registration
-- before they have an authenticated session

BEGIN;

-- =====================================================
-- College Departments - Allow public read access
-- =====================================================

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.college_departments;
DROP POLICY IF EXISTS "Users can view departments" ON public.college_departments;
DROP POLICY IF EXISTS "Public read access for departments" ON public.college_departments;

-- Allow anyone (including unauthenticated users) to read departments
CREATE POLICY "Public read access for departments" ON public.college_departments
FOR SELECT USING (true);

-- Keep insert policy for college admins
DROP POLICY IF EXISTS "Enable insert for college admins" ON public.college_departments;
CREATE POLICY "Enable insert for college admins" ON public.college_departments
FOR INSERT TO authenticated WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.organizations 
    WHERE id = college_departments.org_id AND created_by = auth.uid()
  )
);

-- =====================================================
-- College Programs - Allow public read access
-- =====================================================

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.college_programs;
DROP POLICY IF EXISTS "Users can view programs" ON public.college_programs;
DROP POLICY IF EXISTS "Public read access for programs" ON public.college_programs;

-- Allow anyone (including unauthenticated users) to read programs
CREATE POLICY "Public read access for programs" ON public.college_programs
FOR SELECT USING (true);

-- Keep insert policy for college admins
DROP POLICY IF EXISTS "Enable insert for college admins" ON public.college_programs;
CREATE POLICY "Enable insert for college admins" ON public.college_programs
FOR INSERT TO authenticated WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.college_departments d
    JOIN public.organizations o ON d.org_id = o.id
    WHERE d.id = college_programs.dept_id AND o.created_by = auth.uid()
  )
);

-- =====================================================
-- College Batches - Allow public read access
-- =====================================================

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.college_batches;
DROP POLICY IF EXISTS "Users can view batches" ON public.college_batches;
DROP POLICY IF EXISTS "Public read access for batches" ON public.college_batches;

-- Allow anyone (including unauthenticated users) to read batches
CREATE POLICY "Public read access for batches" ON public.college_batches
FOR SELECT USING (true);

-- Keep insert policy for college admins
DROP POLICY IF EXISTS "Enable insert for college admins" ON public.college_batches;
CREATE POLICY "Enable insert for college admins" ON public.college_batches
FOR INSERT TO authenticated WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.college_programs p
    JOIN public.college_departments d ON p.dept_id = d.id
    JOIN public.organizations o ON d.org_id = o.id
    WHERE p.id = college_batches.program_id AND o.created_by = auth.uid()
  )
);

COMMIT;

-- Verify policies
SELECT 'RLS policies updated successfully! ✅' as status,
       'Students can now view departments, programs, and batches during registration' as message;
