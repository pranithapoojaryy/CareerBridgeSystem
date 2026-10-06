-- Simplified Analytics Functions (Without student_course_progress table)
-- Run these in Supabase SQL Editor

-- 1. Get active students count (accessed in last N days)
CREATE OR REPLACE FUNCTION get_active_students_count(
  org_id UUID,
  days INT DEFAULT 7
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  count_result INT;
BEGIN
  SELECT COUNT(DISTINCT slp.student_id)
  INTO count_result
  FROM student_lecture_progress slp
  JOIN profiles p ON slp.student_id = p.id
  WHERE p.organization_id = org_id
    AND slp.last_accessed_at >= NOW() - (days || ' days')::INTERVAL;
  
  RETURN COALESCE(count_result, 0);
END;
$$;

-- 2. Get course enrollment statistics (simplified without progress)
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
    'completed_courses', 0,
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
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.enrolled_at::DATE as date,
    COUNT(e.id) as enrollments,
    0::BIGINT as completions -- No progress table available
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
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id as student_id,
    p.full_name as student_name,
    p.email as student_email,
    0::NUMERIC as progress_percent,
    e.enrolled_at,
    (SELECT MAX(slp.last_accessed_at) 
     FROM student_lecture_progress slp 
     WHERE slp.student_id = p.id) as last_accessed_at,
    COUNT(DISTINCT sa.id) as assessments_taken,
    ROUND(COALESCE(AVG(sa.score), 0), 2) as average_score,
    (SELECT MAX(slp.last_accessed_at) 
     FROM student_lecture_progress slp 
     WHERE slp.student_id = p.id) < NOW() - INTERVAL '7 days' as is_at_risk,
    'in_progress'::TEXT as status
  FROM profiles p
  JOIN student_course_enrollments e ON p.id = e.student_id
  LEFT JOIN student_assessment_submissions sa ON sa.student_id = p.id
  WHERE e.course_id = course_id_param
  GROUP BY p.id, p.full_name, p.email, e.enrolled_at
  ORDER BY student_name;
END;
$$;

-- 6. Get content effectiveness metrics
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
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    l.id as lecture_id,
    l.title as lecture_title,
    s.title as section_title,
    COUNT(DISTINCT slp.student_id) as total_views,
    ROUND(
      COALESCE(
        COUNT(DISTINCT CASE WHEN slp.completed THEN slp.student_id END)::NUMERIC / 
        NULLIF(COUNT(DISTINCT slp.student_id), 0) * 100,
        0
      ),
      2
    ) as average_completion_rate,
    0::NUMERIC as average_time_spent,
    COUNT(DISTINCT CASE WHEN NOT slp.completed THEN slp.student_id END) as drop_off_count,
    ROUND(
      COALESCE(
        COUNT(DISTINCT CASE WHEN slp.completed THEN slp.student_id END)::NUMERIC / 
        NULLIF(COUNT(DISTINCT slp.student_id), 0) * 100,
        0
      ),
      2
    ) as engagement_score
  FROM learning_course_lectures l
  JOIN learning_course_sections s ON l.section_id = s.id
  LEFT JOIN student_lecture_progress slp ON l.id = slp.lecture_id
  WHERE s.course_id = course_id_param
  GROUP BY l.id, l.title, s.title
  ORDER BY engagement_score DESC;
END;
$$;

-- 7. Get at-risk students across all courses (simplified)
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
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id as student_id,
    p.full_name as student_name,
    p.email as student_email,
    c.title as course_title,
    0::NUMERIC as progress_percent,
    e.enrolled_at,
    (SELECT MAX(slp.last_accessed_at) 
     FROM student_lecture_progress slp 
     WHERE slp.student_id = p.id) as last_accessed_at,
    COUNT(DISTINCT sa.id) as assessments_taken,
    ROUND(COALESCE(AVG(sa.score), 0), 2) as average_score,
    TRUE as is_at_risk,
    'in_progress'::TEXT as status
  FROM profiles p
  JOIN student_course_enrollments e ON p.id = e.student_id
  JOIN learning_courses c ON e.course_id = c.id
  LEFT JOIN student_assessment_submissions sa ON sa.student_id = p.id
  WHERE c.provider_id = org_id
    AND (
      (SELECT MAX(slp.last_accessed_at) 
       FROM student_lecture_progress slp 
       WHERE slp.student_id = p.id) < NOW() - INTERVAL '7 days'
      OR (SELECT MAX(slp.last_accessed_at) 
          FROM student_lecture_progress slp 
          WHERE slp.student_id = p.id) IS NULL
    )
  GROUP BY p.id, p.full_name, p.email, c.title, e.enrolled_at
  ORDER BY last_accessed_at ASC NULLS FIRST;
END;
$$;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_active_students_count TO authenticated;
GRANT EXECUTE ON FUNCTION get_course_enrollment_stats TO authenticated;
GRANT EXECUTE ON FUNCTION get_enrollment_trends TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_courses TO authenticated;
GRANT EXECUTE ON FUNCTION get_course_student_performance TO authenticated;
GRANT EXECUTE ON FUNCTION get_content_effectiveness TO authenticated;
GRANT EXECUTE ON FUNCTION get_at_risk_students TO authenticated;

-- Verification: Test the functions
SELECT * FROM get_course_enrollment_stats(
  (SELECT organization_id FROM profiles WHERE id = auth.uid())
);
