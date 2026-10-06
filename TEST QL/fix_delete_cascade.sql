-- Enable ON DELETE CASCADE for all learning module related tables
-- This ensures that when a course is deleted, all related sections, lectures, enrollments, and progress are also deleted automatically.

-- 1. Student Course Enrollments
ALTER TABLE student_course_enrollments
DROP CONSTRAINT IF EXISTS student_course_enrollments_course_id_fkey;

ALTER TABLE student_course_enrollments
ADD CONSTRAINT student_course_enrollments_course_id_fkey
FOREIGN KEY (course_id) REFERENCES learning_courses(id)
ON DELETE CASCADE;

-- 2. Learning Course Sections
ALTER TABLE learning_course_sections
DROP CONSTRAINT IF EXISTS learning_course_sections_course_id_fkey;

ALTER TABLE learning_course_sections
ADD CONSTRAINT learning_course_sections_course_id_fkey
FOREIGN KEY (course_id) REFERENCES learning_courses(id)
ON DELETE CASCADE;

-- 3. Learning Course Lectures
ALTER TABLE learning_course_lectures
DROP CONSTRAINT IF EXISTS learning_course_lectures_section_id_fkey;

ALTER TABLE learning_course_lectures
ADD CONSTRAINT learning_course_lectures_section_id_fkey
FOREIGN KEY (section_id) REFERENCES learning_course_sections(id)
ON DELETE CASCADE;

-- 4. Learning Course Assessments (if linked to sections)
ALTER TABLE learning_course_assessments
DROP CONSTRAINT IF EXISTS learning_course_assessments_section_id_fkey;

ALTER TABLE learning_course_assessments
ADD CONSTRAINT learning_course_assessments_section_id_fkey
FOREIGN KEY (section_id) REFERENCES learning_course_sections(id)
ON DELETE CASCADE;

-- 5. Student Module Progress
-- Note: student_module_progress relies on section_id for cascading delete (Course -> Section -> Progress)
ALTER TABLE student_module_progress
DROP CONSTRAINT IF EXISTS student_module_progress_section_id_fkey;

ALTER TABLE student_module_progress
ADD CONSTRAINT student_module_progress_section_id_fkey
FOREIGN KEY (section_id) REFERENCES learning_course_sections(id)
ON DELETE CASCADE;

-- 6. Student Lecture Progress
-- Note: student_lecture_progress relies on lecture_id for cascading delete (Course -> Section -> Lecture -> Progress)
ALTER TABLE student_lecture_progress
DROP CONSTRAINT IF EXISTS student_lecture_progress_lecture_id_fkey;

ALTER TABLE student_lecture_progress
ADD CONSTRAINT student_lecture_progress_lecture_id_fkey
FOREIGN KEY (lecture_id) REFERENCES learning_course_lectures(id)
ON DELETE CASCADE;

-- 7. Student Assessment Submissions
ALTER TABLE student_assessment_submissions
DROP CONSTRAINT IF EXISTS student_assessment_submissions_assessment_id_fkey;

ALTER TABLE student_assessment_submissions
ADD CONSTRAINT student_assessment_submissions_assessment_id_fkey
FOREIGN KEY (assessment_id) REFERENCES learning_course_assessments(id)
ON DELETE CASCADE;

-- 8. Metadata Tables
ALTER TABLE learning_course_it_metadata
DROP CONSTRAINT IF EXISTS learning_course_it_metadata_course_id_fkey;

ALTER TABLE learning_course_it_metadata
ADD CONSTRAINT learning_course_it_metadata_course_id_fkey
FOREIGN KEY (course_id) REFERENCES learning_courses(id)
ON DELETE CASCADE;

ALTER TABLE learning_course_mgmt_metadata
DROP CONSTRAINT IF EXISTS learning_course_mgmt_metadata_course_id_fkey;

ALTER TABLE learning_course_mgmt_metadata
ADD CONSTRAINT learning_course_mgmt_metadata_course_id_fkey
FOREIGN KEY (course_id) REFERENCES learning_courses(id)
ON DELETE CASCADE;
