-- TEST ANALYTICS FUNCTIONS
-- Run this to see if the functions themselves work when given the correct ID.
-- ID from previous steps: '6984606b-f491-40cb-9984-696ee22ef86d'

SELECT '--- 1. Testing get_course_enrollment_stats ---' as check;
SELECT * FROM get_course_enrollment_stats('6984606b-f491-40cb-9984-696ee22ef86d');

SELECT '--- 2. Testing get_active_students_count ---' as check;
SELECT * FROM get_active_students_count('6984606b-f491-40cb-9984-696ee22ef86d', 30);

SELECT '--- 3. Testing get_top_courses ---' as check;
SELECT * FROM get_top_courses('6984606b-f491-40cb-9984-696ee22ef86d');

SELECT '--- 4. Raw Data Check ---' as check;
SELECT COUNT(*) as raw_enrollment_count
FROM student_course_enrollments e
JOIN learning_courses c ON e.course_id = c.id
WHERE c.provider_id = '6984606b-f491-40cb-9984-696ee22ef86d';
