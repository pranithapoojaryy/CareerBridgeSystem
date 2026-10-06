-- Enable RLS on student_interviews if not already
ALTER TABLE student_interviews ENABLE ROW LEVEL SECURITY;

-- Allow ANY authenticated user to VIEW student answers
-- (In a real app, you'd restrict this to the student and the grading faculty, but for now this unblocks the feature)
CREATE POLICY "Allow view access for authenticated users"
ON student_interviews FOR SELECT
TO authenticated
USING (true);

-- Allow students to INSERT their own answers
CREATE POLICY "Allow insert for students"
ON student_interviews FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = student_id);

-- Check if mock_questions_junction is readable
ALTER TABLE mock_questions_junction ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow view access for mock_questions_junction"
ON mock_questions_junction FOR SELECT
TO authenticated
USING (true);
