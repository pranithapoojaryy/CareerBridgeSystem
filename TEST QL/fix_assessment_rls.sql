-- Enable RLS for Assessment tables
ALTER TABLE learning_course_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_assessment_submissions ENABLE ROW LEVEL SECURITY;

-- ==========================================================
-- 1. LEARNING COURSE ASSESSMENTS
-- ==========================================================

-- DROP existing policies to avoid conflicts
DROP POLICY IF EXISTS "Assessments are viewable by everyone" ON learning_course_assessments;
DROP POLICY IF EXISTS "Course owners can manage assessments" ON learning_course_assessments;

-- View Policy: Allow everyone to view assessments (consistent with public lectures)
CREATE POLICY "Assessments are viewable by everyone"
ON learning_course_assessments FOR SELECT
USING ( true );

-- Manage Policy: Only course owners (via section -> course -> provider)
CREATE POLICY "Course owners can manage assessments"
ON learning_course_assessments FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM learning_course_sections s
    JOIN learning_courses c ON s.course_id = c.id
    WHERE s.id = learning_course_assessments.section_id
    AND c.provider_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM learning_course_sections s
    JOIN learning_courses c ON s.course_id = c.id
    WHERE s.id = learning_course_assessments.section_id
    AND c.provider_id = auth.uid()
  )
);

-- ==========================================================
-- 2. STUDENT ASSESSMENT SUBMISSIONS
-- ==========================================================

DROP POLICY IF EXISTS "Students can view own submissions" ON student_assessment_submissions;
DROP POLICY IF EXISTS "Students can submit assessments" ON student_assessment_submissions;
DROP POLICY IF EXISTS "Faculty can view submissions" ON student_assessment_submissions;
DROP POLICY IF EXISTS "Faculty can grade submissions" ON student_assessment_submissions;

-- Student View: Own submissions
CREATE POLICY "Students can view own submissions"
ON student_assessment_submissions FOR SELECT
TO authenticated
USING ( auth.uid() = student_id );

-- Student Insert: Own submissions
CREATE POLICY "Students can submit assessments"
ON student_assessment_submissions FOR INSERT
TO authenticated
WITH CHECK ( auth.uid() = student_id );

-- Faculty View: Submissions for their courses
CREATE POLICY "Faculty can view submissions"
ON student_assessment_submissions FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM learning_course_assessments a
    JOIN learning_course_sections s ON a.section_id = s.id
    JOIN learning_courses c ON s.course_id = c.id
    WHERE a.id = student_assessment_submissions.assessment_id
    AND c.provider_id = auth.uid()
  )
);

-- Faculty Update: Grading submissions
CREATE POLICY "Faculty can grade submissions"
ON student_assessment_submissions FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM learning_course_assessments a
    JOIN learning_course_sections s ON a.section_id = s.id
    JOIN learning_courses c ON s.course_id = c.id
    WHERE a.id = student_assessment_submissions.assessment_id
    AND c.provider_id = auth.uid()
  )
);
