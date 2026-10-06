
-- Fix typo in learning_course_lectures
UPDATE public.learning_course_lectures 
SET content_url = REPLACE(content_url, 'assemets', 'assets') 
WHERE content_url LIKE '%assemets%';

UPDATE public.learning_course_lectures 
SET description = REPLACE(description, 'assemets', 'assets') 
WHERE description LIKE '%assemets%';
