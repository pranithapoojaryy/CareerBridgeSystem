-- CRITICAL FIX: Login Issues & RLS Recursion (Refined)
-- This script fixes the "Unable to login" error caused by infinite recursion in RLS policies

-- ========================================================
-- PART 1: Helper Function to Avoid Recursion
-- ========================================================

-- Create a SECURITY DEFINER function to check role
-- This runs with admin privileges and bypasses RLS, avoiding recursion
CREATE OR REPLACE FUNCTION is_faculty_or_college()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
      AND role IN ('faculty', 'college')
  );
$$;

-- Function to check if user is student
CREATE OR REPLACE FUNCTION is_student()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
      AND role = 'student'
  );
$$;

-- Grant access to these functions
GRANT EXECUTE ON FUNCTION is_faculty_or_college TO authenticated;
GRANT EXECUTE ON FUNCTION is_student TO authenticated;

-- ========================================================
-- PART 2: Fix Profiles RLS (The Cause of Login Failure)
-- ========================================================

-- Enable RLS just in case
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop all problematic policies (Check existence before dropping/creating)
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Faculty can view org profiles" ON profiles;
DROP POLICY IF EXISTS "College can view all student profiles" ON profiles;
DROP POLICY IF EXISTS "Allow users to view own profile" ON profiles;
DROP POLICY IF EXISTS "Allow viewing other profiles" ON profiles;
DROP POLICY IF EXISTS "Faculty can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- 1. Essential Policy: Users MUST be able to view their own profile for login
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
TO authenticated
USING (id = auth.uid());

-- 2. Essential Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- 3. College/Faculty View Policy (No Recursion)
CREATE POLICY "Faculty can view all profiles"
ON profiles FOR SELECT
TO authenticated
USING (
  is_faculty_or_college() = true
);

-- ========================================================
-- PART 3: Fix Enrollments RLS
-- ========================================================

-- Drop existing enrollment policies first
DROP POLICY IF EXISTS "Faculty can view enrollments for org courses" ON student_course_enrollments;
DROP POLICY IF EXISTS "College can view all enrollments" ON student_course_enrollments;
DROP POLICY IF EXISTS "Students can view own enrollments" ON student_course_enrollments;
DROP POLICY IF EXISTS "Students can create enrollments" ON student_course_enrollments;

-- Simple policy for students
CREATE POLICY "Students can view own enrollments"
ON student_course_enrollments FOR SELECT
TO authenticated
USING (student_id = auth.uid());

-- Allow students to enroll
CREATE POLICY "Students can create enrollments"
ON student_course_enrollments FOR INSERT
TO authenticated
WITH CHECK (student_id = auth.uid());

-- Fix for Faculty/College: View ALL enrollments if you are faculty
CREATE POLICY "Faculty can view all enrollments"
ON student_course_enrollments FOR SELECT
TO authenticated
USING (
  is_faculty_or_college() = true
);

-- ========================================================
-- PART 4: Verification
-- ========================================================

-- Check if you can see your own profile (simulated)
SELECT * FROM profiles WHERE id = auth.uid();
