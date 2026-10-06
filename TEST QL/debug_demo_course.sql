-- Fix: Allow students to retake assessments and verify content links

-- 1. Clear existing submissions to allow retaking
DELETE FROM student_assessment_submissions
WHERE assessment_id IN (
  SELECT id FROM learning_course_assessments 
  WHERE title LIKE '%Digital Marketing%'
);

-- 2. Verify lectures are properly linked
SELECT 
  l.id as lecture_id,
  l.title,
  l.content_type,
  l.content_url,
  l.section_id,
  s.title as module_title
FROM learning_course_lectures l
JOIN learning_course_sections s ON l.section_id = s.id
WHERE s.course_id = '6dc5dea9-5bc0-45c6-ad8f-9e41e1304006'
ORDER BY s.order_index, l.order_index;

-- 3. Verify assessments have questions
SELECT 
  a.id,
  a.title,
  a.assessment_type,
  jsonb_array_length(a.questions) as question_count,
  a.questions
FROM learning_course_assessments a
WHERE a.section_id IN (
  SELECT id FROM learning_course_sections 
  WHERE course_id = '6dc5dea9-5bc0-45c6-ad8f-9e41e1304006'
);

-- 4. Check if lectures link to valid assessments
SELECT 
  l.title as lecture_title,
  l.content_type,
  l.content_url as assessment_id,
  a.title as assessment_title,
  CASE 
    WHEN a.id IS NULL THEN 'BROKEN LINK'
    ELSE 'OK'
  END as status
FROM learning_course_lectures l
LEFT JOIN learning_course_assessments a ON l.content_url = a.id::text
WHERE l.content_type IN ('quiz', 'assignment')
  AND l.section_id IN (
    SELECT id FROM learning_course_sections 
    WHERE course_id = '6dc5dea9-5bc0-45c6-ad8f-9e41e1304006'
  );
