-- Allow students to delete their own certificates
DROP POLICY IF EXISTS "Students can delete own certifications" ON student_certifications;
CREATE POLICY "Students can delete own certifications" ON student_certifications
    FOR DELETE USING (auth.uid() = student_id);

-- Verify policy creation
SELECT * FROM pg_policies WHERE tablename = 'student_certifications' AND policyname = 'Students can delete own certifications';
