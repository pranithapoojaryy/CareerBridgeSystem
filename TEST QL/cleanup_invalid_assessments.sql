-- Cleanup script for lectures with invalid assessment contentUrl values
-- This fixes the "invalid input syntax for type uuid" error

-- Step 1: Find and clear lectures with non-UUID contentUrl (timestamp strings)
-- These are broken links that can't be fixed
UPDATE learning_course_lectures
SET content_url = ''
WHERE content_type IN ('quiz', 'assignment')
  AND content_url IS NOT NULL
  AND content_url != ''
  AND content_url !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- Step 2: Optionally delete lectures that have no valid assessment link
-- Uncomment the next block if you want to remove these broken entries completely:

/*
DELETE FROM learning_course_lectures
WHERE content_type IN ('quiz', 'assignment')
  AND (content_url IS NULL OR content_url = '');
*/

-- Step 3: Verify the cleanup
SELECT 
  id,
  title,
  content_type,
  content_url,
  section_id
FROM learning_course_lectures
WHERE content_type IN ('quiz', 'assignment')
ORDER BY created_at DESC;
