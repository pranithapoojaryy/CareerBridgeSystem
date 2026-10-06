-- Debug: Check if questions exist in the assessment

-- 1. Check the specific assessment that's failing
SELECT 
  id,
  title,
  assessment_type,
  section_id,
  jsonb_array_length(questions) as question_count,
  questions
FROM learning_course_assessments
WHERE title LIKE '%Digital Marketing%'
ORDER BY created_at DESC
LIMIT 3;

-- 2. Check if questions field is properly formatted
SELECT 
  id,
  title,
  CASE 
    WHEN questions IS NULL THEN 'NULL'
    WHEN jsonb_typeof(questions) != 'array' THEN 'NOT AN ARRAY'
    WHEN jsonb_array_length(questions) = 0 THEN 'EMPTY ARRAY'
    ELSE 'HAS QUESTIONS'
  END as questions_status,
  jsonb_array_length(questions) as count,
  questions->0 as first_question_sample
FROM learning_course_assessments
WHERE id IN (
  SELECT content_url::uuid 
  FROM learning_course_lectures 
  WHERE content_type = 'quiz'
    AND section_id IN (
      SELECT id FROM learning_course_sections 
      WHERE course_id = '6dc5dea9-5bc0-45c6-ad8f-9e41e1304006'
    )
)
ORDER BY created_at DESC;

-- 3. Validate question structure
SELECT 
  a.title as assessment_title,
  q.value->>'question' as question_text,
  q.value->>'type' as question_type,
  q.value->'options' as options
FROM learning_course_assessments a,
  jsonb_array_elements(a.questions) WITH ORDINALITY AS q(value, position)
WHERE a.id IN (
  SELECT content_url::uuid 
  FROM learning_course_lectures 
  WHERE content_type = 'quiz'
    AND section_id IN (
      SELECT id FROM learning_course_sections 
      WHERE course_id = '6dc5dea9-5bc0-45c6-ad8f-9e41e1304006'
    )
)
ORDER BY a.created_at DESC, q.position
LIMIT 20;
