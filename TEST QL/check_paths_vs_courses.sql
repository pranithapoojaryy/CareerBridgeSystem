-- Check if learning_paths and learning_modules tables exist and have data
-- Run this in Supabase SQL Editor

-- 1. Check learning_paths table
SELECT 
  id,
  title,
  description,
  created_at
FROM learning_paths
ORDER BY created_at DESC
LIMIT 5;

-- 2. Check if there's a learning_modules table
SELECT COUNT(*) as module_count
FROM learning_modules;

-- 3. Check the relationship
SELECT 
  lp.title as path_title,
  COUNT(lm.id) as modules_count
FROM learning_paths lp
LEFT JOIN learning_modules lm ON lm.path_id = lp.id
GROUP BY lp.title;

-- 4. Compare with learning_courses
SELECT 'learning_courses' as table_name, COUNT(*) as count FROM learning_courses
UNION ALL
SELECT 'learning_paths' as table_name, COUNT(*) as count FROM learning_paths;
