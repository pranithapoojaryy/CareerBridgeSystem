-- Check Aptitude and Assessment Data

-- 1. Check Aptitude Modules and Tests (Separate Feature)
SELECT 
  'Aptitude Feature' as source,
  m.name as module_name, 
  t.title as test_title,
  t.test_type
FROM aptitude_modules m
JOIN aptitude_tests t ON t.module_id = m.id;

-- 2. Check Learning Course Assessments (Integrated Key)
SELECT 
  'Course Assessment' as source,
  c.title as course_title,
  s.title as section_title,
  a.title as assessment_title,
  a.assessment_type
FROM learning_course_assessments a
JOIN learning_course_sections s ON a.section_id = s.id
JOIN learning_courses c ON s.course_id = c.id;

-- 3. Check what's currently in Course Lectures (Visible on Screen)
SELECT 
  'Course Lecture' as source,
  c.title as course_title,
  s.title as section_title,
  l.title as lecture_title,
  l.content_type
FROM learning_course_lectures l
JOIN learning_course_sections s ON l.section_id = s.id
JOIN learning_courses c ON s.course_id = c.id
WHERE l.content_type IN ('quiz', 'assignment', 'assessment');
