-- FINAL DATA CHECK
-- 1. Simulate "Activity" so 'Active Students' is not 0.
-- 2. Run the Analytics functions to prove they work.

-- Step 1: Insert dummy activity for your user
INSERT INTO student_lecture_progress (student_id, lecture_id, last_accessed_at)
SELECT 
  'd2cd996e-9ead-40d4-8465-13f39e706633', -- Your User ID
  id,
  NOW()
FROM learning_course_lectures
LIMIT 1
ON CONFLICT DO NOTHING;

-- Step 2: Test the dashboard numbers
SELECT '--- Enrollments (Should be 1) ---' as check_1;
SELECT * FROM get_course_enrollment_stats('6984606b-f491-40cb-9984-696ee22ef86d');

SELECT '--- Active Students (Should be 1) ---' as check_2;
SELECT * FROM get_active_students_count('6984606b-f491-40cb-9984-696ee22ef86d', 7);

SELECT '--- Top Courses (Should show your course) ---' as check_3;
SELECT * FROM get_top_courses('6984606b-f491-40cb-9984-696ee22ef86d');
