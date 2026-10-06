-- Check for duplicate TEST courses
SELECT id, title, created_at, is_published, provider_id
FROM learning_courses
WHERE title = 'TEST';
