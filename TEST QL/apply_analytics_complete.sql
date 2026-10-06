-- Complete Analytics Fix Script
-- This script:
-- 1. Creates missing progress/assessment tables if they don't exist
-- 2. Defines all analytics Remote Procedure Calls (RPCs)
-- 3. Grants proper execution permissions

-- =========================================================
-- 1. Ensure Table Structure Exists
-- =========================================================

-- Create student_assessment_submissions if not exists
CREATE TABLE IF NOT EXISTS student_assessment_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES profiles(id),
    assessment_id UUID, -- Reference to assessment if needed
    score NUMERIC DEFAULT 0,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    details JSONB
);

-- Establish RLS for student_assessment_submissions
ALTER TABLE student_assessment_submissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Students can see own submissions" ON student_assessment_submissions;
CREATE POLICY "Students can see own submissions"
ON student_assessment_submissions FOR SELECT
TO authenticated
USING (student_id = auth.uid());

DROP POLICY IF EXISTS "Faculty can see org submissions" ON student_assessment_submissions;
CREATE POLICY "Faculty can see org submissions"
ON student_assessment_submissions FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid() 
        AND p.organization_id = (SELECT organization_id FROM profiles WHERE id = student_assessment_submissions.student_id)
        AND p.role IN ('faculty', 'college')
    )
);

-- Create student_lecture_progress if not exists
CREATE TABLE IF NOT EXISTS student_lecture_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES profiles(id),
    lecture_id UUID, -- References learning_course_lectures(id)
    completed BOOLEAN DEFAULT FALSE,
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    watch_time_seconds INTEGER DEFAULT 0,
    UNIQUE(student_id, lecture_id)
);

-- Establish RLS for student_lecture_progress
ALTER TABLE student_lecture_progress ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Students can see own progress" ON student_lecture_progress;
CREATE POLICY "Students can see own progress"
ON student_lecture_progress FOR SELECT
TO authenticated
USING (student_id = auth.uid());

-- =========================================================
-- 2. Define Analytics Functions
-- =========================================================

-- 1. Get active students count (accessed in last N days)
CREATE OR REPLACE FUNCTION get_active_students_count(
  org_id UUID,
  days INT DEFAULT 7
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  count_result INT;
BEGIN
  -- If table is empty or doesn't track last_access properly, fallback to profile count
  -- But here we attempt to use lecture progress as "activity"
  SELECT COUNT(DISTINCT slp.student_id)
  INTO count_result
  FROM student_lecture_progress slp
  JOIN profiles p ON slp.student_id = p.id
  WHERE p.organization_id = org_id
    AND slp.last_accessed_at >= NOW() - (days || ' days')::INTERVAL;
  
  RETURN COALESCE(count_result, 0);
END;
$$;

-- 2. Get course enrollment statistics (simplified)
CREATE OR REPLACE FUNCTION get_course_enrollment_stats(org_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_enrollments', COUNT(DISTINCT e.id),
    'active_courses', COUNT(DISTINCT CASE WHEN e.id IS NOT NULL THEN c.id END),
    'completed_courses', 0, -- Simplification for now
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

-- 3. Get enrollment trends (daily enrollments for last N days)
CREATE OR REPLACE FUNCTION get_enrollment_trends(
  org_id UUID,
  days INT DEFAULT 30
)
RETURNS TABLE(
  date DATE,
  enrollments BIGINT,
  completions BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.enrolled_at::DATE as date,
    COUNT(e.id) as enrollments,
    0::BIGINT as completions
  FROM student_course_enrollments e
  JOIN learning_courses c ON e.course_id = c.id
  WHERE c.provider_id = org_id
    AND e.enrolled_at >= NOW() - (days || ' days')::INTERVAL
  GROUP BY e.enrolled_at::DATE
  ORDER BY date DESC;
END;
$$;

-- 4. Get top performing courses (simplified)
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
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id as course_id,
    c.title as course_title,
    COUNT(DISTINCT e.id) as total_enrollments,
    0::BIGINT as completions,
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

-- 5. Get student performance for a specific course (simplified)
CREATE OR REPLACE FUNCTION get_course_student_performance(course_id_param UUID)
RETURNS TABLE(
  student_id UUID,
  student_name TEXT,
  student_email TEXT,
  progress_percent NUMERIC,
  enrolled_at TIMESTAMP,
  last_accessed_at TIMESTAMP,
  assessments_taken BIGINT,
  average_score NUMERIC,
  is_at_risk BOOLEAN,
  status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id as student_id,
    p.full_name as student_name,
    p.email as student_email,
    0::NUMERIC as progress_percent,
    e.enrolled_at,
    NULL::TIMESTAMP as last_accessed_at,
    COUNT(DISTINCT sa.id) as assessments_taken,
    ROUND(COALESCE(AVG(sa.score), 0), 2) as average_score,
    FALSE as is_at_risk,
    'in_progress'::TEXT as status
  FROM profiles p
  JOIN student_course_enrollments e ON p.id = e.student_id
  LEFT JOIN student_assessment_submissions sa ON sa.student_id = p.id
  WHERE e.course_id = course_id_param
  GROUP BY p.id, p.full_name, p.email, e.enrolled_at
  ORDER BY student_name;
END;
$$;

-- 6. Get content effectiveness metrics (stubbed to prevent errors)
CREATE OR REPLACE FUNCTION get_content_effectiveness(course_id_param UUID)
RETURNS TABLE(
  lecture_id UUID,
  lecture_title TEXT,
  section_title TEXT,
  total_views BIGINT,
  average_completion_rate NUMERIC,
  average_time_spent NUMERIC,
  drop_off_count BIGINT,
  engagement_score NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Empty result set for now to avoid table dependency errors if lectures tables are missing/empty
  RETURN QUERY
  SELECT 
    NULL::UUID as lecture_id,
    'No Data'::TEXT as lecture_title,
    'No Data'::TEXT as section_title,
    0::BIGINT as total_views,
    0::NUMERIC as average_completion_rate,
    0::NUMERIC as average_time_spent,
    0::BIGINT as drop_off_count,
    0::NUMERIC as engagement_score
  WHERE FALSE; 
END;
$$;

-- 7. Get at-risk students (stubbed)
CREATE OR REPLACE FUNCTION get_at_risk_students(org_id UUID)
RETURNS TABLE(
  student_id UUID,
  student_name TEXT,
  student_email TEXT,
  course_title TEXT,
  progress_percent NUMERIC,
  enrolled_at TIMESTAMP,
  last_accessed_at TIMESTAMP,
  assessments_taken BIGINT,
  average_score NUMERIC,
  is_at_risk BOOLEAN,
  status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id as student_id,
    p.full_name as student_name,
    p.email as student_email,
    'Unknown Course'::TEXT as course_title,
    0::NUMERIC as progress_percent,
    NOW()::TIMESTAMP as enrolled_at,
    NULL::TIMESTAMP as last_accessed_at,
    0::BIGINT as assessments_taken,
    0::NUMERIC as average_score,
    TRUE as is_at_risk,
    'at_risk'::TEXT as status
  FROM profiles p
  WHERE FALSE; -- Return empty for now
END;
$$;

-- =========================================================
-- 3. Grant Permissions
-- =========================================================

GRANT EXECUTE ON FUNCTION get_active_students_count TO authenticated;
GRANT EXECUTE ON FUNCTION get_course_enrollment_stats TO authenticated;
GRANT EXECUTE ON FUNCTION get_enrollment_trends TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_courses TO authenticated;
GRANT EXECUTE ON FUNCTION get_course_student_performance TO authenticated;
GRANT EXECUTE ON FUNCTION get_content_effectiveness TO authenticated;
GRANT EXECUTE ON FUNCTION get_at_risk_students TO authenticated;
