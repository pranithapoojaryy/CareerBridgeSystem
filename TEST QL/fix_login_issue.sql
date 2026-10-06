-- Debug Login Issues - Check Auth & RLS

-- Step 1: Check if ANY users exist
SELECT COUNT(*) as total_users FROM auth.users;

-- Step 2: Check profiles table RLS policies
SELECT 
  tablename,
  policyname,
  permissive,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Step 3: TEMPORARY FIX - Disable RLS on profiles for testing
-- (This allows login to work while we investigate)
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Step 4: Re-enable with correct policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Faculty can view org profiles" ON profiles;
DROP POLICY IF EXISTS "College can view all student profiles" ON profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- Create simple, working policies
CREATE POLICY "Allow users to view own profile"
ON profiles FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "Allow users to insert own profile"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

CREATE POLICY "Allow users to update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Allow authenticated users to view other profiles
CREATE POLICY "Allow viewing other profiles"
ON profiles FOR SELECT
TO authenticated
USING (true);

-- Step 5: Verify you can see your profile
SELECT 
  id,
  email,
  full_name,
  role,
  organization_id
FROM profiles
WHERE email = 'YOUR_EMAIL_HERE'; -- Replace with your actual email

-- Step 6: Test auth
SELECT auth.uid() as my_user_id;

-- Step 7: If still can't login, check auth.users
SELECT 
  id,
  email,
  created_at,
  confirmed_at,
  email_confirmed_at,
  banned_until,
  deleted_at
FROM auth.users
WHERE email = 'YOUR_EMAIL_HERE'; -- Replace with your actual email
