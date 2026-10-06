-- View All Enrolled Students (For College Portal)
-- This shows ALL students enrolled in ANY course (global courses)

-- Step 1: Create a view for college to see all enrolled students
CREATE OR REPLACE VIEW college_enrollment_view AS
SELECT 
  e.id as enrollment_id,
  e.enrolled_at,
  e.progress_percent,
  e.is_completed,
  
  -- Student Details
  s.id as student_id,
  s.full_name as student_name,
  s.email as student_email,
  s.phone as student_mobile,
  
  -- Student's College Details
  student_org.name as student_college_name,
  student_org.short_code as college_code,
  
  -- Student Profile Details
  sp.usn,
  sp.department,
  sp.semester,
  sp.cgpa,
  
  -- Course Details
  c.id as course_id,
  c.title as course_name,
  c.category as course_category,
  c.difficulty as course_difficulty,
  c.domain_type,
  
  -- Progress Tracking
  e.current_section_id,
  cs.title as current_section_name,
  
  -- Assessments
  (SELECT COUNT(*) 
   FROM student_assessment_submissions sas 
   WHERE sas.student_id = s.id 
     AND sas.assessment_id IN (
       SELECT id FROM learning_course_assessments 
       WHERE section_id IN (
         SELECT id FROM learning_course_sections WHERE course_id = c.id
       )
     )
  ) as assessments_completed,
  
  (SELECT AVG(score) 
   FROM student_assessment_submissions sas 
   WHERE sas.student_id = s.id 
     AND sas.assessment_id IN (
       SELECT id FROM learning_course_assessments 
       WHERE section_id IN (
         SELECT id FROM learning_course_sections WHERE course_id = c.id
       )
     )
  ) as average_assessment_score

FROM student_course_enrollments e
JOIN profiles s ON e.student_id = s.id
LEFT JOIN organizations student_org ON s.organization_id = student_org.id
LEFT JOIN student_profiles sp ON s.id = sp.id
JOIN learning_courses c ON e.course_id = c.id
LEFT JOIN learning_course_sections cs ON e.current_section_id = cs.id
WHERE s.role = 'student'
ORDER BY e.enrolled_at DESC;

-- Grant access to authenticated users
GRANT SELECT ON college_enrollment_view TO authenticated;

-- Step 2: Update RLS Policy to allow college users to see all enrollments
DROP POLICY IF EXISTS "College can view all enrollments" ON student_course_enrollments;

CREATE POLICY "College can view all enrollments"
ON student_course_enrollments FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
      AND profiles.role IN ('faculty', 'college')
  )
);

-- Step 3: Ensure college can see all student profiles
DROP POLICY IF EXISTS "College can view all student profiles" ON profiles;

CREATE POLICY "College can view all student profiles"
ON profiles FOR SELECT
TO authenticated
USING (
  role = 'student' 
  OR id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM profiles viewer
    WHERE viewer.id = auth.uid()
      AND viewer.role IN ('faculty', 'college')
  )
);

-- Step 4: Test Query - All Enrolled Students
SELECT 
  student_name,
  student_college_name,
  student_mobile,
  course_name,
  progress_percent,
  enrolled_at,
  assessments_completed,
  average_assessment_score
FROM college_enrollment_view
ORDER BY enrolled_at DESC
LIMIT 50;

-- Step 5: Filter by specific course
SELECT 
  student_name,
  student_college_name,
  student_mobile,
  course_name,
  progress_percent,
  usn,
  department
FROM college_enrollment_view
WHERE course_name LIKE '%Digital Marketing%'
ORDER BY progress_percent DESC;

-- Step 6: Get enrollment summary statistics
SELECT 
  course_name,
  COUNT(*) as total_enrolled,
  COUNT(CASE WHEN is_completed THEN 1 END) as completed_count,
  AVG(progress_percent) as avg_progress,
  COUNT(DISTINCT student_college_name) as colleges_count
FROM college_enrollment_view
GROUP BY course_id, course_name
ORDER BY total_enrolled DESC;

-- Step 7: Get college-wise enrollment breakdown
SELECT 
  student_college_name,
  COUNT(DISTINCT student_id) as unique_students,
  COUNT(*) as total_enrollments,
  AVG(progress_percent) as avg_progress
FROM college_enrollment_view
WHERE student_college_name IS NOT NULL
GROUP BY student_college_name
ORDER BY total_enrollments DESC;

-- Step 8: Function to get detailed enrollment report
CREATE OR REPLACE FUNCTION get_enrollment_report(course_id_filter UUID DEFAULT NULL)
RETURNS TABLE(
  student_name TEXT,
  student_email TEXT,
  student_mobile TEXT,
  student_college TEXT,
  usn TEXT,
  department TEXT,
  course_title TEXT,
  progress_percent NUMERIC,
  enrolled_date TIMESTAMPTZ,
  is_completed BOOLEAN,
  assessments_done BIGINT,
  avg_score NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
  SELECT 
    student_name,
    student_email,
    student_mobile,
    student_college_name,
    usn,
    department,
    course_name,
    progress_percent,
    enrolled_at,
    is_completed,
    assessments_completed,
    average_assessment_score
  FROM college_enrollment_view
  WHERE (course_id_filter IS NULL OR course_id = course_id_filter)
  ORDER BY enrolled_at DESC;
$$;

GRANT EXECUTE ON FUNCTION get_enrollment_report TO authenticated;

-- Step 9: Verify everything works
SELECT * FROM get_enrollment_report() LIMIT 10;
