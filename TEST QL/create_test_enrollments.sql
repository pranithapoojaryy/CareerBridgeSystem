-- Create Test Enrollments for Demo/Testing
-- Run this ONLY if you confirmed you have 0 enrollments

-- First, verify you have courses and students
-- Check courses:
SELECT id, title, provider_id FROM learning_courses LIMIT 5;

-- Check students in your org:
SELECT id, full_name, email 
FROM profiles 
WHERE organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
  AND role = 'student'
LIMIT 5;

-- After verifying both exist, create test enrollments
-- Replace the UUIDs with actual values from above queries

-- Example: Enroll student in course (REPLACE THESE IDs)
INSERT INTO student_course_enrollments (student_id, course_id, enrolled_at)
VALUES 
  (
    (SELECT id FROM profiles WHERE role = 'student' LIMIT 1), -- First student
    (SELECT id FROM learning_courses LIMIT 1), -- First course
    NOW()
  )
ON CONFLICT DO NOTHING;

-- Or enroll multiple students in the Digital Marketing course
INSERT INTO student_course_enrollments (student_id, course_id, enrolled_at)
SELECT 
  p.id as student_id,
  c.id as course_id,
  NOW() as enrolled_at
FROM profiles p
CROSS JOIN learning_courses c
WHERE p.role = 'student'
  AND c.title LIKE '%Digital Marketing%'
  AND p.organization_id = c.provider_id
LIMIT 5 -- Enroll first 5 students
ON CONFLICT DO NOTHING;

-- Verify enrollments were created
SELECT 
  c.title as course,
  p.full_name as student,
  e.enrolled_at
FROM student_course_enrollments e
JOIN learning_courses c ON e.course_id = c.id
JOIN profiles p ON e.student_id = p.id
ORDER BY e.enrolled_at DESC
LIMIT 20;

-- Test the analytics function again
SELECT * FROM get_course_enrollment_stats(
  (SELECT organization_id FROM profiles WHERE id = auth.uid())
);
