-- Function to check if student has completed all modules
CREATE OR REPLACE FUNCTION has_completed_all_modules(
  p_student_id UUID,
  p_course_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_total_modules INT;
  v_completed_modules INT;
BEGIN
  -- Count total modules in course
  SELECT COUNT(*) INTO v_total_modules
  FROM learning_course_sections
  WHERE course_id = p_course_id;
  
  -- Count completed modules
  SELECT COUNT(*) INTO v_completed_modules
  FROM student_module_progress
  WHERE student_id = p_student_id
    AND section_id IN (
      SELECT id FROM learning_course_sections WHERE course_id = p_course_id
    )
    AND status = 'Completed';
  
  -- Return true if all modules completed
  RETURN v_total_modules > 0 AND v_total_modules = v_completed_modules;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if final exam is unlocked
CREATE OR REPLACE FUNCTION is_final_exam_unlocked(
  p_student_id UUID,
  p_assessment_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_course_id UUID;
  v_is_final_exam BOOLEAN;
BEGIN
  -- Get course ID and check if it's a final exam
  SELECT 
    s.course_id,
    (a.title ILIKE '%final%exam%' OR a.title ILIKE '%final%assessment%')
  INTO v_course_id, v_is_final_exam
  FROM learning_course_assessments a
  JOIN learning_course_sections s ON a.section_id = s.id
  WHERE a.id = p_assessment_id;
  
  -- If not a final exam, it's always unlocked
  IF NOT v_is_final_exam THEN
    RETURN TRUE;
  END IF;
  
  -- For final exams, check if all modules are completed
  RETURN has_completed_all_modules(p_student_id, v_course_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add RLS policy to prevent taking final exam before modules completed
CREATE POLICY "Students can only take unlocked assessments" ON student_assessment_submissions
  FOR INSERT WITH CHECK (
    is_final_exam_unlocked(student_id, assessment_id) = TRUE
  );
