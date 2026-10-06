-- Add metadata column to learning_courses for domain-specific data
ALTER TABLE learning_courses 
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- Create course_enrollments table
CREATE TABLE IF NOT EXISTS course_enrollments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  course_id UUID REFERENCES learning_courses(id) ON DELETE CASCADE,
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  enrolled_at TIMESTAMPTZ DEFAULT now(),
  progress NUMERIC DEFAULT 0,
  is_completed BOOLEAN DEFAULT false,
  certificate_url TEXT,
  completed_at TIMESTAMPTZ,
  last_accessed_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(course_id, student_id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_course_enrollments_student_id ON course_enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_course_enrollments_course_id ON course_enrollments(course_id);

-- Add RLS policies for enrollments
ALTER TABLE course_enrollments ENABLE ROW LEVEL SECURITY;

-- Students can view their own enrollments
CREATE POLICY "Students can view their own enrollments" 
ON course_enrollments FOR SELECT 
USING (auth.uid() = student_id);

-- Students can enroll themselves
CREATE POLICY "Students can enroll themselves" 
ON course_enrollments FOR INSERT 
WITH CHECK (auth.uid() = student_id);

-- Students can update their progress
CREATE POLICY "Students can update their progress" 
ON course_enrollments FOR UPDATE 
USING (auth.uid() = student_id);

-- Colleges can view enrollments for their courses
CREATE POLICY "Colleges can view enrollments for their courses" 
ON course_enrollments FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM learning_courses lc
    WHERE lc.id = course_enrollments.course_id
    AND lc.provider_id = auth.uid()
  )
);
