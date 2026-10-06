-- 1. Check RLS Policies
SELECT tablename, policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename IN ('learning_courses', 'learning_course_sections', 'learning_course_lectures');

-- 2. Verify Data Linkage matches EXACT Course ID
SELECT 
    s.id as section_id, 
    s.title as section_title, 
    s.course_id as section_course_id,
    c.id as course_id
FROM learning_course_sections s
JOIN learning_courses c ON s.course_id = c.id
WHERE c.title = 'TEST';

-- 3. Check Foreign Key Constraints (to ensure relationship name 'sections' works)
SELECT
    tc.table_schema, 
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_schema AS foreign_table_schema,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_name = 'learning_course_sections';
