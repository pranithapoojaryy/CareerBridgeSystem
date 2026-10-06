-- Migration to change provider_id to TEXT in learning_courses
-- Handles all dependent policies and constraints

BEGIN;

-- 1. Drop Policies dependent on provider_id
DROP POLICY IF EXISTS "Creators can manage IT metadata" ON learning_course_it_metadata;
DROP POLICY IF EXISTS "Creators can manage mgmt metadata" ON learning_course_mgmt_metadata;
DROP POLICY IF EXISTS "Authenticated users can create courses" ON learning_courses;
DROP POLICY IF EXISTS "Creators can manage their courses" ON learning_courses;
DROP POLICY IF EXISTS "Users can delete their own courses" ON learning_courses;
DROP POLICY IF EXISTS "Users can update their own courses" ON learning_courses;

-- 2. Drop Foreign Key
ALTER TABLE learning_courses DROP CONSTRAINT IF EXISTS learning_courses_provider_id_fkey;

-- 3. Alter Column Type
ALTER TABLE learning_courses ALTER COLUMN provider_id TYPE text;

-- 4. Re-create Policies with Type Casting (auth.uid()::text)

-- Policy: Authenticated users can create courses
CREATE POLICY "Authenticated users can create courses" ON learning_courses
FOR INSERT
WITH CHECK (auth.uid()::text = provider_id);

-- Policy: Creators can manage their courses
CREATE POLICY "Creators can manage their courses" ON learning_courses
FOR ALL
USING (auth.uid()::text = provider_id);

-- Policy: Users can delete their own courses (Redundant if "ALL" exists, but re-creating as found)
CREATE POLICY "Users can delete their own courses" ON learning_courses
FOR DELETE
USING (auth.uid()::text = provider_id);

-- Policy: Users can update their own courses (Redundant if "ALL" exists, but re-creating as found)
CREATE POLICY "Users can update their own courses" ON learning_courses
FOR UPDATE
USING (auth.uid()::text = provider_id);

-- Policy: Creators can manage IT metadata
CREATE POLICY "Creators can manage IT metadata" ON learning_course_it_metadata
FOR ALL
USING (EXISTS ( 
  SELECT 1 FROM learning_courses
  WHERE learning_courses.id = learning_course_it_metadata.course_id 
  AND learning_courses.provider_id = auth.uid()::text
));

-- Policy: Creators can manage mgmt metadata
CREATE POLICY "Creators can manage mgmt metadata" ON learning_course_mgmt_metadata
FOR ALL
USING (EXISTS ( 
  SELECT 1 FROM learning_courses
  WHERE learning_courses.id = learning_course_mgmt_metadata.course_id 
  AND learning_courses.provider_id = auth.uid()::text
));

COMMIT;
