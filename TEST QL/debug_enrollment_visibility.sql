-- Quick Debug: Check if enrollment data exists and RLS is working

-- 1. Check total enrollments
SELECT COUNT(*) as total_enrollments
FROM student_course_enrollments;

-- 2. Check enrollments for specific course (replace with your course ID)
SELECT 
  e.id,
  e.course_id,
  c.title as course_title,
  e.student_id,
  p.full_name as student_name,
  p.email as student_email,
  e.enrolled_at
FROM student_course_enrollments e
JOIN learning_courses c ON e.course_id = c.id
LEFT JOIN profiles p ON e.student_id = p.id
WHERE c.title LIKE '%Digital Marketing%'
ORDER BY e.enrolled_at DESC;

-- 3. Check if RLS is blocking the queries
SELECT 
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'student_course_enrollments';

-- 4. Test if current user can see enrollments
SELECT 
  COUNT(*) as enrollments_visible,
  c.title as course_title
FROM student_course_enrollments e
JOIN learning_courses c ON e.course_id = c.id
WHERE c.provider_id = (
  SELECT organization_id 
  FROM profiles 
  WHERE id = auth.uid()
)
GROUP BY c.title;

-- 5. If no data, check if analytics functions can access it
SELECT * FROM get_top_courses(
  (SELECT organization_id FROM profiles WHERE id = auth.uid()),
  10
);
