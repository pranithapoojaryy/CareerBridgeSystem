-- fix_analytics_data.sql

-- 1. Reset Policies for Mock Definitions to be fully public to authenticated users
ALTER TABLE public.mock_definitions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read mocks" ON public.mock_definitions;
CREATE POLICY "Authenticated users can read mocks" ON public.mock_definitions 
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can manage mocks" ON public.mock_definitions;
CREATE POLICY "Authenticated users can manage mocks" ON public.mock_definitions 
FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 2. Reset Policies for Mock Attempts
ALTER TABLE public.mock_attempts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Student view own attempts" ON public.mock_attempts;
DROP POLICY IF EXISTS "Authenticated view attempts" ON public.mock_attempts;

-- Allow everyone to see all attempts (for debugging/College usage)
CREATE POLICY "Authenticated view attempts" ON public.mock_attempts 
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Student insert own attempts" ON public.mock_attempts;
CREATE POLICY "Student insert own attempts" ON public.mock_attempts 
FOR INSERT TO authenticated WITH CHECK (auth.uid() = student_id);

DROP POLICY IF EXISTS "Student update own attempts" ON public.mock_attempts;
DROP POLICY IF EXISTS "Authenticated update attempts" ON public.mock_attempts;
CREATE POLICY "Authenticated update attempts" ON public.mock_attempts 
FOR UPDATE TO authenticated USING (true);

-- 3. Verify Foreign Keys (just in case)
-- Ensure student_interviews has the correct FK
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'student_interviews_mock_attempt_id_fkey'
    ) THEN
        ALTER TABLE public.student_interviews 
        ADD CONSTRAINT student_interviews_mock_attempt_id_fkey 
        FOREIGN KEY (mock_attempt_id) REFERENCES public.mock_attempts(id);
    END IF;
END $$;
