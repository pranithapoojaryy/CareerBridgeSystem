-- Migration V3: Change provider_id to TEXT in learning_courses
-- Handles ALL dependent policies and constraints

BEGIN;

-- 1. Drop Dependencies (Policies)
-- learning_courses
DROP POLICY IF EXISTS "Authenticated users can create courses" ON learning_courses;
DROP POLICY IF EXISTS "Creators can manage their courses" ON learning_courses;
DROP POLICY IF EXISTS "Users can delete their own courses" ON learning_courses;
DROP POLICY IF EXISTS "Users can update their own courses" ON learning_courses;

-- learning_course_sections
DROP POLICY IF EXISTS "Creators can manage sections" ON learning_course_sections;

-- learning_course_lectures
DROP POLICY IF EXISTS "Creators can manage lectures" ON learning_course_lectures;
DROP POLICY IF EXISTS "Course owners can manage lectures" ON learning_course_lectures;

-- course_enrollments
DROP POLICY IF EXISTS "Colleges can view enrollments for their courses" ON course_enrollments;

-- learning_course_it_metadata
DROP POLICY IF EXISTS "Creators can manage IT metadata" ON learning_course_it_metadata;

-- learning_course_mgmt_metadata
DROP POLICY IF EXISTS "Creators can manage mgmt metadata" ON learning_course_mgmt_metadata;

-- learning_course_assessments
DROP POLICY IF EXISTS "Course owners can manage assessments" ON learning_course_assessments;

-- student_assessment_submissions
DROP POLICY IF EXISTS "Faculty can view submissions" ON student_assessment_submissions;
DROP POLICY IF EXISTS "Faculty can grade submissions" ON student_assessment_submissions;


-- 2. Drop Foreign Key
ALTER TABLE learning_courses DROP CONSTRAINT IF EXISTS learning_courses_provider_id_fkey;

-- 3. Alter Column Type
ALTER TABLE learning_courses ALTER COLUMN provider_id TYPE text;


-- 4. Re-create Policies with Type Casting (auth.uid()::text)

-- learning_courses
CREATE POLICY "Authenticated users can create courses" ON learning_courses
FOR INSERT WITH CHECK (auth.uid()::text = provider_id);

CREATE POLICY "Creators can manage their courses" ON learning_courses
FOR ALL USING (auth.uid()::text = provider_id);

CREATE POLICY "Users can delete their own courses" ON learning_courses
FOR DELETE USING (auth.uid()::text = provider_id);

CREATE POLICY "Users can update their own courses" ON learning_courses
FOR UPDATE USING (auth.uid()::text = provider_id);

-- learning_course_sections
CREATE POLICY "Creators can manage sections" ON learning_course_sections
FOR ALL USING (EXISTS ( 
  SELECT 1 FROM learning_courses
  WHERE learning_courses.id = learning_course_sections.course_id 
  AND learning_courses.provider_id = auth.uid()::text
));

-- learning_course_lectures
CREATE POLICY "Creators can manage lectures" ON learning_course_lectures
FOR ALL USING (EXISTS ( 
  SELECT 1 FROM learning_course_sections s
  JOIN learning_courses c ON s.course_id = c.id
  WHERE s.id = learning_course_lectures.section_id 
  AND c.provider_id = auth.uid()::text
));

-- course_enrollments
CREATE POLICY "Colleges can view enrollments for their courses" ON course_enrollments
FOR ALL USING (EXISTS ( 
  SELECT 1 FROM learning_courses lc
  WHERE lc.id = course_enrollments.course_id 
  AND lc.provider_id = auth.uid()::text
));

-- learning_course_it_metadata
CREATE POLICY "Creators can manage IT metadata" ON learning_course_it_metadata
FOR ALL USING (EXISTS ( 
  SELECT 1 FROM learning_courses
  WHERE learning_courses.id = learning_course_it_metadata.course_id 
  AND learning_courses.provider_id = auth.uid()::text
));

-- learning_course_mgmt_metadata
CREATE POLICY "Creators can manage mgmt metadata" ON learning_course_mgmt_metadata
FOR ALL USING (EXISTS ( 
  SELECT 1 FROM learning_courses
  WHERE learning_courses.id = learning_course_mgmt_metadata.course_id 
  AND learning_courses.provider_id = auth.uid()::text
));

-- learning_course_assessments
CREATE POLICY "Course owners can manage assessments" ON learning_course_assessments
FOR ALL USING (EXISTS ( 
  SELECT 1 FROM learning_course_sections s
  JOIN learning_courses c ON s.course_id = c.id
  WHERE s.id = learning_course_assessments.section_id 
  AND c.provider_id = auth.uid()::text
));

-- student_assessment_submissions (Faculty View)
CREATE POLICY "Faculty can view submissions" ON student_assessment_submissions
FOR ALL USING (EXISTS ( 
  SELECT 1 FROM learning_course_assessments a
  JOIN learning_course_sections s ON a.section_id = s.id
  JOIN learning_courses c ON s.course_id = c.id
  WHERE a.id = student_assessment_submissions.assessment_id 
  AND c.provider_id = auth.uid()::text
));

-- student_assessment_submissions (Faculty Grade)
CREATE POLICY "Faculty can grade submissions" ON student_assessment_submissions
FOR ALL USING (EXISTS ( 
  SELECT 1 FROM learning_course_assessments a
  JOIN learning_course_sections s ON a.section_id = s.id
  JOIN learning_courses c ON s.course_id = c.id
  WHERE a.id = student_assessment_submissions.assessment_id 
  AND c.provider_id = auth.uid()::text
));

COMMIT;
