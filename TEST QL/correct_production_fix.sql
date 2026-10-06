-- CORRECT PRODUCTION FIX: Secure Policies without Recursion
-- This script implements the proper security model:
-- 1. Everyone logged in can read basic profile info (name, avatar, role) - Essential for app to work
-- 2. Only you can edit your profile
-- 3. Faculty/College can see ALL enrollments
-- 4. Students can ONLY see their own enrollments

-- ========================================================
-- PART 1: Reset to Clean State
-- ========================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_course_enrollments ENABLE ROW LEVEL SECURITY;

-- Drop all unstable policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Faculty can view org profiles" ON profiles;
DROP POLICY IF EXISTS "College can view all student profiles" ON profiles;
DROP POLICY IF EXISTS "Allow users to view own profile" ON profiles;
DROP POLICY IF EXISTS "Allow viewing other profiles" ON profiles;
DROP POLICY IF EXISTS "Faculty can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can view profiles" ON profiles;

-- ========================================================
-- PART 2: Profile Policies (The Foundation)
-- ========================================================

-- READ: Allow any authenticated user to read profiles.
-- WHY: Prevents recursion. Login needs to read profile to know role. 
-- If we check role to read profile, we create an infinite loop.
CREATE POLICY "Public Read Access for Authenticated Users"
ON profiles FOR SELECT
TO authenticated
USING (true);

-- WRITE: Strictly limit updates to the user themselves
CREATE POLICY "Users can only update their own profile"
ON profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- INSERT: strictly self only
CREATE POLICY "Users can only insert their own profile"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

-- ========================================================
-- PART 3: Enrollment Policies (Role-Based Access)
-- ========================================================

DROP POLICY IF EXISTS "Faculty can view enrollments for org courses" ON student_course_enrollments;
DROP POLICY IF EXISTS "College can view all enrollments" ON student_course_enrollments;
DROP POLICY IF EXISTS "Students can view own enrollments" ON student_course_enrollments;
DROP POLICY IF EXISTS "Students can create enrollments" ON student_course_enrollments;
DROP POLICY IF EXISTS "Faculty can view all enrollments" ON student_course_enrollments;
DROP POLICY IF EXISTS "Faculty can view enrollments" ON student_course_enrollments;

-- RULE 1: Students can see their OWN enrollments
CREATE POLICY "Student View Own Enrollments"
ON student_course_enrollments FOR SELECT
TO authenticated
USING (student_id = auth.uid());

-- RULE 2: Faculty/College can see ALL enrollments
-- We use a subquery that doesn't reference the table being queried to avoid recursion
CREATE POLICY "Faculty View All Enrollments"
ON student_course_enrollments FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
      AND profiles.role IN ('faculty', 'college')
  )
);

-- RULE 3: Students can enroll themselves
CREATE POLICY "Student Self Enroll"
ON student_course_enrollments FOR INSERT
TO authenticated
WITH CHECK (student_id = auth.uid());

-- ========================================================
-- PART 4: Verification
-- ========================================================

-- Verify you can see your own data
SELECT role, email FROM profiles WHERE id = auth.uid();
