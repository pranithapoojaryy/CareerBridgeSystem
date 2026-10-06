-- Migration to fix deletion cascade for learning courses
-- The constraint on student_course_enrollments.current_section_id prevents section deletion
-- We need to change it to ON DELETE SET NULL

BEGIN;

-- 1. Drop existing constraint
ALTER TABLE student_course_enrollments 
DROP CONSTRAINT IF EXISTS student_course_enrollments_current_section_id_fkey;

-- 2. Add new constraint with ON DELETE SET NULL
ALTER TABLE student_course_enrollments
ADD CONSTRAINT student_course_enrollments_current_section_id_fkey
FOREIGN KEY (current_section_id)
REFERENCES learning_course_sections(id)
ON DELETE SET NULL;

COMMIT;
