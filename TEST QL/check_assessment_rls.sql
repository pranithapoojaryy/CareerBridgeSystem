
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM
    pg_policies
WHERE
    tablename = 'learning_course_assessments';

-- Also check if table exists
SELECT to_regclass('public.learning_course_assessments');
