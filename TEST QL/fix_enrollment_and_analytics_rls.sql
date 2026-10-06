-- Comprehensive Fix for Enrollment Visibility and Analytics

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
-- PART 4: Ensure Analytics Functions Work
-- ==========================================

-- Make sure the analytics functions have proper permissions
GRANT EXECUTE ON FUNCTION get_active_students_count TO authenticated;
GRANT EXECUTE ON FUNCTION get_course_enrollment_stats TO authenticated;
GRANT EXECUTE ON FUNCTION get_enrollment_trends TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_courses TO authenticated;
GRANT EXECUTE ON FUNCTION get_course_student_performance TO authenticated;
GRANT EXECUTE ON FUNCTION get_content_effectiveness TO authenticated;
GRANT EXECUTE ON FUNCTION get_at_risk_students TO authenticated;

-- ==========================================
-- PART 5: Add Enrollment Count View (Optional)
-- ==========================================

-- Create a materialized view for faster enrollment counts
CREATE MATERIALIZED VIEW IF NOT EXISTS course_enrollment_counts AS
SELECT 
  course_id,
  COUNT(*) as enrollment_count,
  COUNT(DISTINCT CASE WHEN p.progress_percent >= 100 THEN e.student_id END) as completed_count,
  AVG(COALESCE(p.progress_percent, 0)) as avg_progress
FROM student_course_enrollments e
LEFT JOIN student_course_progress p ON e.course_id = p.course_id AND e.student_id = p.student_id
GROUP BY course_id;

-- Create index for performance
CREATE UNIQUE INDEX IF NOT EXISTS course_enrollment_counts_course_id_idx 
ON course_enrollment_counts(course_id);

-- Refresh the view
REFRESH MATERIALIZED VIEW course_enrollment_counts;

-- Grant access
GRANT SELECT ON course_enrollment_counts TO authenticated;

-- Function to refresh the materialized view (call periodically)
CREATE OR REPLACE FUNCTION refresh_enrollment_counts()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW course_enrollment_counts;
END;
$$;

GRANT EXECUTE ON FUNCTION refresh_enrollment_counts TO authenticated;

-- ==========================================
-- VERIFICATION QUERIES
-- ==========================================

-- 1. Check enrollment counts per course
SELECT 
  c.title as course_name,
  COUNT(e.id) as enrolled_students,
  AVG(COALESCE(p.progress_percent, 0)) as avg_progress
FROM learning_courses c
LEFT JOIN student_course_enrollments e ON c.id = e.course_id
LEFT JOIN student_course_progress p ON c.id = p.course_id AND e.student_id = p.student_id
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

-- 3. Test analytics function
SELECT * FROM get_top_courses(
  (SELECT organization_id FROM profiles WHERE id = auth.uid()),
  5
);
