-- Enable RLS (just in case)
ALTER TABLE learning_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_course_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_course_lectures ENABLE ROW LEVEL SECURITY;

-- DROP EXISTING POLICIES TO AVOID ERRORS
DROP POLICY IF EXISTS "Public courses are viewable by everyone" ON learning_courses;
DROP POLICY IF EXISTS "Sections are viewable by everyone" ON learning_course_sections;
DROP POLICY IF EXISTS "Lectures are viewable by everyone" ON learning_course_lectures;
DROP POLICY IF EXISTS "Authenticated users can create courses" ON learning_courses;
DROP POLICY IF EXISTS "Users can update their own courses" ON learning_courses;
DROP POLICY IF EXISTS "Users can delete their own courses" ON learning_courses;
DROP POLICY IF EXISTS "Course owners can manage sections" ON learning_course_sections;
DROP POLICY IF EXISTS "Course owners can manage lectures" ON learning_course_lectures;

-- 1. Policies for COURSES
-- Allow anyone to VIEW public courses
CREATE POLICY "Public courses are viewable by everyone" 
ON learning_courses FOR SELECT 
USING ( true ); 

-- Allow anyone to VIEW sections of visible courses
CREATE POLICY "Sections are viewable by everyone" 
ON learning_course_sections FOR SELECT 
USING ( true );

-- Allow anyone to VIEW lectures of visible sections
CREATE POLICY "Lectures are viewable by everyone" 
ON learning_course_lectures FOR SELECT 
USING ( true );

-- 2. Policies for FACULTY/ADMIN (Insert/Update/Delete)
CREATE POLICY "Authenticated users can create courses" 
ON learning_courses FOR INSERT 
TO authenticated 
WITH CHECK ( auth.uid() = provider_id );

CREATE POLICY "Users can update their own courses" 
ON learning_courses FOR UPDATE
TO authenticated
USING ( auth.uid() = provider_id );

CREATE POLICY "Users can delete their own courses" 
ON learning_courses FOR DELETE
TO authenticated
USING ( auth.uid() = provider_id );

-- 3. Policies for SECTIONS (Managing)
CREATE POLICY "Course owners can manage sections" 
ON learning_course_sections FOR ALL 
TO authenticated 
USING ( 
  EXISTS ( 
    SELECT 1 FROM learning_courses 
    WHERE id = learning_course_sections.course_id 
    AND provider_id = auth.uid() 
  ) 
);

-- 4. Policies for LECTURES (Managing)
CREATE POLICY "Course owners can manage lectures" 
ON learning_course_lectures FOR ALL 
TO authenticated 
USING ( 
  EXISTS ( 
    SELECT 1 FROM learning_course_sections s
    JOIN learning_courses c ON s.course_id = c.id
    WHERE s.id = learning_course_lectures.section_id 
    AND c.provider_id = auth.uid() 
  ) 
);
