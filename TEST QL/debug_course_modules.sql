-- Check if modules exist for courses
-- Run this in your Supabase SQL Editor to see if modules are actually saved

SELECT 
  c.id as course_id,
  c.title as course_title,
  COUNT(DISTINCT s.id) as module_count,
  COUNT(DISTINCT l.id) as lecture_count
FROM learning_courses c
LEFT JOIN learning_course_sections s ON s.course_id = c.id
LEFT JOIN learning_course_lectures l ON l.section_id = s.id
WHERE c.is_published = true
GROUP BY c.id, c.title
ORDER BY c.created_at DESC;

-- Also check the sections table structure
SELECT 
  s.id,
  s.course_id,
  s.title,
  s.description,
  s.order_index,
  COUNT(l.id) as lecture_count
FROM learning_course_sections s
LEFT JOIN learning_course_lectures l ON l.section_id = s.id
GROUP BY s.id, s.course_id, s.title, s.description, s.order_index
ORDER BY s.course_id, s.order_index;
