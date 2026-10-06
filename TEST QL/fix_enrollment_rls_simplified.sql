-- Simplified Fix for Enrollment Visibility (No student_course_progress table)
-- This version works with existing tables only

-- ============================================
-- PART 1: Fix RLS Policies for Enrollments
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Faculty can view all enrollments for their org courses" ON student_course_enrollments;
DROP POLICY IF EXISTS "Students can view their own enrollments" ON student_course_enrollments;
DROP POLICY IF EXISTS "Students can enroll in courses" ON student_course_enrollments;

-- Create comprehensive RLS policies
CREATE POLICY "Faculty can view enrollments for org courses"
ON student_course_enrollments FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM learning_courses c
    JOIN profiles p ON c.provider_id = p.organization_id
    WHERE c.id = student_course_enrollments.course_id
      AND p.id = auth.uid()
      AND p.role IN ('faculty', 'college')
  )
);

CREATE POLICY "Students can view own enrollments"
ON student_course_enrollments FOR SELECT
TO authenticated
USING (student_id = auth.uid());

CREATE POLICY "Students can create enrollments"
ON student_course_enrollments FOR INSERT
TO authenticated
WITH CHECK (student_id = auth.uid());

-- ==========================================
-- PART 2: Add Function to Get Enrollment Count
-- ==========================================

CREATE OR REPLACE FUNCTION get_course_enrollment_count(course_id_param UUID)
RETURNS INTEGER
LANGUAGE SQL
STABLE
AS $$
  SELECT COUNT(*)::INTEGER
  FROM student_course_enrollments
  WHERE course_id = course_id_param;
$$;

GRANT EXECUTE ON FUNCTION get_course_enrollment_count TO authenticated;

-- ==========================================
-- PART 3: Fix Analytics RLS
-- ==========================================

-- Ensure profiles table is readable by authenticated users
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view profiles in same org" ON profiles;

CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "Faculty can view org profiles"
ON profiles FOR SELECT
TO authenticated
USING (
  organization_id = (
    SELECT organization_id FROM profiles WHERE id = auth.uid()
  )
  AND (SELECT role FROM profiles WHERE id = auth.uid()) IN ('faculty', 'college')
);

-- ==========================================
-- PART 4: Simple Enrollment Count View
-- ==========================================

-- Create a simple view for enrollment counts (no progress data)
CREATE OR REPLACE VIEW course_enrollment_summary AS
SELECT 
  c.id as course_id,
  c.title as course_title,
  c.provider_id,
  COUNT(e.id) as enrollment_count,
  MIN(e.enrolled_at) as first_enrollment,
  MAX(e.enrolled_at) as latest_enrollment
FROM learning_courses c
LEFT JOIN student_course_enrollments e ON c.id = e.course_id
GROUP BY c.id, c.title, c.provider_id;

-- Grant access
GRANT SELECT ON course_enrollment_summary TO authenticated;

-- ==========================================
-- PART 5: Update Analytics Functions (Simplified)
-- ==========================================

-- Simplified get_course_enrollment_stats without progress table
CREATE OR REPLACE FUNCTION get_course_enrollment_stats(org_id UUID)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_enrollments', COUNT(DISTINCT e.id),
    'active_courses', COUNT(DISTINCT CASE WHEN e.id IS NOT NULL THEN c.id END),
    'completed_courses', 0, -- Will need progress table for this
    'avg_completion_rate', 0,
    'avg_progress', 0,
    'assessments_taken', COUNT(DISTINCT sa.id),
    'avg_assessment_score', COALESCE(AVG(sa.score), 0)
  )
  INTO result
  FROM learning_courses c
  LEFT JOIN student_course_enrollments e ON c.id = e.course_id
  LEFT JOIN student_assessment_submissions sa ON sa.student_id = e.student_id
  WHERE c.provider_id = org_id;
  
  RETURN result;
END;
$$;

-- Simplified get_top_courses without progress
CREATE OR REPLACE FUNCTION get_top_courses(
  org_id UUID,
  limit_count INT DEFAULT 10
)
RETURNS TABLE(
  course_id UUID,
  course_title TEXT,
  total_enrollments BIGINT,
  completions BIGINT,
  completion_rate NUMERIC,
  average_progress NUMERIC,
  average_score NUMERIC,
  at_risk_students BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id as course_id,
    c.title as course_title,
    COUNT(DISTINCT e.id) as total_enrollments,
    0::BIGINT as completions, -- Need progress table
    0::NUMERIC as completion_rate,
    0::NUMERIC as average_progress,
    ROUND(COALESCE(AVG(sa.score), 0), 2) as average_score,
    0::BIGINT as at_risk_students
  FROM learning_courses c
  LEFT JOIN student_course_enrollments e ON c.id = e.course_id
  LEFT JOIN student_assessment_submissions sa ON sa.student_id = e.student_id
  WHERE c.provider_id = org_id
  GROUP BY c.id, c.title
  ORDER BY total_enrollments DESC, average_score DESC
  LIMIT limit_count;
END;
$$;

GRANT EXECUTE ON FUNCTION get_course_enrollment_stats TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_courses TO authenticated;

-- ==========================================
-- VERIFICATION QUERIES
-- ==========================================

-- 1. Check enrollment counts per course
SELECT 
  c.title as course_name,
  COUNT(e.id) as enrolled_students
FROM learning_courses c
LEFT JOIN student_course_enrollments e ON c.id = e.course_id
WHERE c.provider_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
GROUP BY c.id, c.title
ORDER BY enrolled_students DESC;

-- 2. Verify RLS is working
SELECT 
  tablename,
  policyname,
  permissive,
  cmd
FROM pg_policies
WHERE tablename IN ('student_course_enrollments', 'profiles', 'learning_courses')
ORDER BY tablename, policyname;

-- 3. Test enrollment view
SELECT * FROM course_enrollment_summary
WHERE provider_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
ORDER BY enrollment_count DESC;

-- 4. Test simple analytics
SELECT * FROM get_course_enrollment_stats(
  (SELECT organization_id FROM profiles WHERE id = auth.uid())
);
