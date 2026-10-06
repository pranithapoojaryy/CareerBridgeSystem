-- FORCE ALIGN DATA SCRIPT
-- This script manually updates the user profile using the IDs found in your database.
-- It bypasses 'auth.uid()' which can be null in the SQL Editor.

-- 1. Update the known user 'd2cd...' to be the Admin of Organization '6984...'
UPDATE profiles
SET 
  organization_id = '6984606b-f491-40cb-9984-696ee22ef86d', -- The ID from your "CareerBridge" course
  role = 'college'
WHERE id = 'd2cd996e-9ead-40d4-8465-13f39e706633'; -- The Student ID from your enrollment table

-- 2. Grant permissions directly (Redundant but safe)
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON learning_courses TO authenticated;
GRANT ALL ON student_course_enrollments TO authenticated;

-- 3. Verify the Update
SELECT * FROM profiles WHERE id = 'd2cd996e-9ead-40d4-8465-13f39e706633';

-- 4. Re-add the missing popup function just in case
CREATE OR REPLACE FUNCTION get_course_enrollment_count(course_id_param UUID)
RETURNS INTEGER
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT COUNT(*)::INTEGER
  FROM student_course_enrollments
  WHERE course_id = course_id_param;
$$;
GRANT EXECUTE ON FUNCTION get_course_enrollment_count TO authenticated;
