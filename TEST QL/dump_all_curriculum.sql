-- Check ALL sections and lectures in the database
-- To see if the user's "missing" modules exist for other courses

SELECT 
  c.title as course_title,
  c.id as course_id,
  s.title as module_title,
  s.id as section_id,
  COUNT(l.id) as lecture_count
FROM learning_courses c
JOIN learning_course_sections s ON s.course_id = c.id
LEFT JOIN learning_course_lectures l ON l.section_id = s.id
GROUP BY c.title, c.id, s.title, s.id, s.order_index
ORDER BY c.title, s.order_index;
