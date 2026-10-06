-- Fix for "Assessment not found" error in student portal
-- This script creates lecture entries for assessments that don't have one

-- Create lecture entries for orphaned assessments
INSERT INTO learning_course_lectures (section_id, title, content_type, content_url, duration_minutes, order_index)
SELECT 
  a.section_id,
  a.title,
  CASE 
    WHEN a.assessment_type = 'Quiz' THEN 'quiz'
    WHEN a.assessment_type = 'Assignment' THEN 'assignment'
    ELSE 'quiz'
  END as content_type,
  a.id::text as content_url,  -- Cast UUID to text and link lecture to assessment via contentUrl
  30 as duration_minutes,
  999 as order_index
FROM learning_course_assessments a
WHERE NOT EXISTS (
  SELECT 1 FROM learning_course_lectures l
  WHERE l.content_url = a.id::text  -- Cast UUID to text for comparison
);
