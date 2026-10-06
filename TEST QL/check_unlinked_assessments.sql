-- Diagnostic: Find assessments without lecture links
-- This helps identify if we need to link assessments or just delete empty lectures

-- Check for assessments that don't have lecture entries
SELECT 
  a.id as assessment_id,
  a.title as assessment_title,
  a.section_id,
  a.assessment_type,
  'Missing lecture link' as status
FROM learning_course_assessments a
WHERE NOT EXISTS (
  SELECT 1 FROM learning_course_lectures l
  WHERE l.content_url = a.id::text
)
ORDER BY a.created_at DESC;

-- If the above query returns results, run this to create lecture links:
-- (Copy the INSERT from fix_orphaned_assessments.sql)

-- If no results, then delete the empty lecture entries:
/*
DELETE FROM learning_course_lectures
WHERE content_type IN ('quiz', 'assignment')
  AND (content_url IS NULL OR content_url = '');
*/
