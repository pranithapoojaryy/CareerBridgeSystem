-- Check actual enrollment count for the course in the screenshot
-- Course Title: "Digital Marketing Fundamentals"

SELECT 
    c.id, 
    c.title, 
    COUNT(e.id) as actual_enrollment_count
FROM learning_courses c
LEFT JOIN student_course_enrollments e ON c.id = e.course_id
WHERE c.title = 'Digital Marketing Fundamentals'
GROUP BY c.id, c.title;

-- Also check if the repository query works
SELECT count(*) FROM student_course_enrollments 
WHERE course_id = (SELECT id FROM learning_courses WHERE title = 'Digital Marketing Fundamentals' LIMIT 1);
