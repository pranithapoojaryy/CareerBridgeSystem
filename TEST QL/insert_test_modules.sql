-- Insert sample modules/sections for the TEST course
-- Run this in Supabase SQL Editor

-- First, let's insert 2 modules for the TEST course
INSERT INTO public.learning_course_sections (course_id, title, description, order_index, estimated_hours, module_type)
VALUES 
  (
    'f9c2112b-1058-4ecf-ab93-634e039409f2',  -- TEST course ID from debug
    'Module 1: Introduction to Software Engineering',
    'Learn the fundamentals of software engineering, including SDLC, design patterns, and best practices. This module will help you understand the core concepts needed for a software engineering career.',
    1,
    4,
    'Theory'
  ),
  (
    'f9c2112b-1058-4ecf-ab93-634e039409f2',
    'Module 2: Practical Coding & Projects',
    'Hands-on coding exercises and mini-projects to apply what you learned. Build real-world applications and strengthen your programming skills through practice.',
    2,
    6,
    'Practice'
  );

-- Get the section IDs (they'll be auto-generated)
-- Then insert lectures for each section

-- For Module 1:
INSERT INTO public.learning_course_lectures (section_id, title, description, content_type, content_url, duration_minutes, order_index, source_type)
SELECT 
  s.id as section_id,
  'Introduction Video' as title,
  'Overview of software engineering principles' as description,
  'video' as content_type,
  'https://www.youtube.com/watch?v=zOjov-2OZ0E' as content_url,
  15 as duration_minutes,
  1 as order_index,
  'youtube' as source_type
FROM public.learning_course_sections s
WHERE s.course_id = 'f9c2112b-1058-4ecf-ab93-634e039409f2'
  AND s.order_index = 1;

INSERT INTO public.learning_course_lectures (section_id, title, description, content_type, content_url, duration_minutes, order_index, source_type)
SELECT 
  s.id,
  'SDLC Explained' as title,
  'Understanding Software Development Life Cycle' as description,
  'video' as content_type,
  'https://www.youtube.com/watch?v=i-QyW8D3ei0' as content_url,
  20 as duration_minutes,
  2 as order_index,
  'youtube' as source_type
FROM public.learning_course_sections s
WHERE s.course_id = 'f9c2112b-1058-4ecf-ab93-634e039409f2'
  AND s.order_index = 1;

-- For Module 2:
INSERT INTO public.learning_course_lectures (section_id, title, description, content_type, content_url, duration_minutes, order_index, source_type)
SELECT 
  s.id,
  'Building Your First Project' as title,
  'Step-by-step guide to creating a simple application' as description,
  'video' as content_type,
  'https://www.youtube.com/watch?v=cBZr6EKl9uE' as content_url,
  30 as duration_minutes,
  1 as order_index,
  'youtube' as source_type
FROM public.learning_course_sections s
WHERE s.course_id = 'f9c2112b-1058-4ecf-ab93-634e039409f2'
  AND s.order_index = 2;

INSERT INTO public.learning_course_lectures (section_id, title, description, content_type, content_url, duration_minutes, order_index, source_type)
SELECT 
  s.id,
  'Code Review Best Practices' as title,
  'Learn how to review code like a professional' as description,
  'video' as content_type,
  'https://www.youtube.com/watch?v=cBZr6EKl9uE' as content_url,
  25 as duration_minutes,
  2 as order_index,
  'youtube' as source_type
FROM public.learning_course_sections s
WHERE s.course_id = 'f9c2112b-1058-4ecf-ab93-634e039409f2'
  AND s.order_index = 2;

-- Verify the data was inserted
SELECT 
  c.title as course,
  s.title as module,
  s.description as module_description,
  COUNT(l.id) as lecture_count
FROM learning_courses c
JOIN learning_course_sections s ON s.course_id = c.id
LEFT JOIN learning_course_lectures l ON l.section_id = s.id
WHERE c.id = 'f9c2112b-1058-4ecf-ab93-634e039409f2'
GROUP BY c.title, s.title, s.description, s.order_index
ORDER BY s.order_index;
