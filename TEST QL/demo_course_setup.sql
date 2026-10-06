-- Demo Course Setup for Poornaprajna Institute of Management
-- This creates a complete course with modules, lectures, and assessments

-- Step 1: Get the organization ID for Poornaprajna Institute of Management
-- (Replace 'YOUR_ORG_ID' with actual org ID from organizations table)

-- Step 2: Get a faculty user ID
-- (Replace 'YOUR_FACULTY_ID' with actual faculty user ID)

-- Variables you need to set:
-- ORG_ID: SELECT id FROM organizations WHERE name LIKE '%Poornaprajna%';
-- FACULTY_ID: SELECT id FROM profiles WHERE organization_id = 'ORG_ID' AND role = 'faculty' LIMIT 1;

-- ==================================================================
-- COURSE CREATION
-- ==================================================================

INSERT INTO learning_courses (
  title,
  description,
  provider_id,
  provider_name,
  category,
  difficulty,
  price,
  thumbnail_url,
  has_certificate,
  skill_points,
  tags,
  is_published,
  prerequisites,
  target_role,
  estimated_duration_weeks,
  placement_relevance,
  skills_gained,
  learning_outcomes,
  domain_type
) VALUES (
  'Digital Marketing Fundamentals',
  'Master the essentials of digital marketing including SEO, social media marketing, content marketing, and analytics. Perfect for MBA students and marketing professionals.',
  'YOUR_FACULTY_ID',  -- Replace with actual faculty ID
  'Poornaprajna Institute of Management',
  'Marketing',
  'Intermediate',
  0,
  'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400',
  true,
  100,
  ARRAY['Marketing', 'Digital Marketing', 'SEO', 'Social Media', 'Analytics'],
  true,
  'Basic understanding of marketing principles',
  'Digital Marketing Specialist',
  8,
  'High',
  ARRAY['SEO Optimization', 'Social Media Strategy', 'Content Marketing', 'Google Analytics', 'Email Marketing'],
  'Students will learn to create comprehensive digital marketing strategies, analyze campaign performance, and optimize marketing ROI using modern tools and platforms.',
  'Management'
)
RETURNING id;

-- Save the returned course_id and use it below
-- Let's call it 'COURSE_ID'

-- ==================================================================
-- MODULE 1: Introduction to Digital Marketing
-- ==================================================================

INSERT INTO learning_course_sections (
  course_id,
  title,
  order_index,
  description,
  module_type,
  estimated_hours,
  is_mandatory,
  skills_covered,
  assessment_required
) VALUES (
  'COURSE_ID',  -- Replace with actual course ID
  'Introduction to Digital Marketing',
  1,
  'Understanding the digital marketing landscape, key concepts, and strategies',
  'Theory',
  4,
  true,
  ARRAY['Digital Marketing Basics', 'Marketing Channels'],
  true
)
RETURNING id;

-- Save as 'MODULE1_ID'

-- Add lectures to Module 1
INSERT INTO learning_course_lectures (section_id, title, content_type, content_url, duration_minutes, order_index, description) VALUES
('MODULE1_ID', 'What is Digital Marketing?', 'video', 'https://www.youtube.com/watch?v=bixR-KIJKYM', 15, 1, 'Introduction to digital marketing concepts'),
('MODULE1_ID', 'Digital Marketing vs Traditional Marketing', 'video', 'https://www.youtube.com/watch?v=YXvD7KJxsEQ', 20, 2, 'Comparing digital and traditional marketing approaches'),
('MODULE1_ID', 'Understanding Your Target Audience', 'article', '', 30, 3, 'Learn how to identify and segment your target audience');

-- ==================================================================
-- MODULE 2: SEO & Content Marketing  
-- ==================================================================

INSERT INTO learning_course_sections (
  course_id,
  title,
  order_index,
  description,
  module_type,
  estimated_hours,
  skills_covered,
  assessment_required
) VALUES (
  'COURSE_ID',
  'SEO & Content Marketing',
  2,
  'Learn search engine optimization techniques and content marketing strategies',
  'Practice',
  6,
  ARRAY['SEO', 'Content Strategy', 'Keyword Research'],
  true
)
RETURNING id;

-- Save as 'MODULE2_ID'

-- Add lectures to Module 2
INSERT INTO learning_course_lectures (section_id, title, content_type, content_url, duration_minutes, order_index, description) VALUES
('MODULE2_ID', 'SEO Fundamentals', 'video', 'https://www.youtube.com/watch?v=hF515-0Tduk', 25, 1, 'Core SEO concepts and best practices'),
('MODULE2_ID', 'Keyword Research & Analysis', 'video', 'https://www.youtube.com/watch?v=oOmPG35wmGE', 30, 2, 'How to find and analyze profitable keywords'),
('MODULE2_ID', 'Content Marketing Strategy', 'video', 'https://www.youtube.com/watch?v=7Ey_RuMKhUs', 20, 3, 'Creating a winning content marketing plan');

-- ==================================================================
-- MODULE 3: Social Media Marketing
-- ==================================================================

INSERT INTO learning_course_sections (
  course_id,
  title,
  order_index,
  description,
  module_type,
  estimated_hours,
  skills_covered,
  assessment_required
) VALUES (
  'COURSE_ID',
  'Social Media Marketing',
  3,
  'Master social media platforms, content creation, and engagement strategies',
  'Practice',
  5,
  ARRAY['Social Media Strategy', 'Content Creation', 'Community Management'],
  true
)
RETURNING id;

-- Save as 'MODULE3_ID'

-- Add lectures to Module 3
INSERT INTO learning_course_lectures (section_id, title, content_type, content_url, duration_minutes, order_index, description) VALUES
('MODULE3_ID', 'Social Media Platforms Overview', 'video', 'https://www.youtube.com/watch?v=mQoMK3RWKLc', 20, 1, 'Understanding different social media platforms'),
('MODULE3_ID', 'Creating Engaging Social Content', 'video', 'https://www.youtube.com/watch?v=0d8HvMz3tSY', 25, 2, 'Tips for creating viral social media content'),
('MODULE3_ID', 'Social Media Advertising', 'video', 'https://www.youtube.com/watch?v=M1z6YJR9AAQ', 30, 3, 'Paid advertising on social platforms');

-- ==================================================================
-- ASSESSMENT 1: Digital Marketing Basics Quiz (with image question)
-- ==================================================================

INSERT INTO learning_course_assessments (
  section_id,
  title,
  assessment_type,
  description,
  passing_criteria,
  weightage,
  attempts_allowed,
  is_auto_evaluated,
  questions
) VALUES (
  'MODULE1_ID',
  'Digital Marketing Basics Quiz',
  'Quiz',
  'Test your understanding of digital marketing fundamentals',
  70.0,
  15.0,
  3,
  true,
  jsonb_build_array(
    jsonb_build_object(
      'id', gen_random_uuid()::text,
      'question', 'What is the primary goal of digital marketing?',
      'type', 'multiple_choice',
      'options', jsonb_build_array(
        'To increase website traffic only',
        'To build brand awareness and drive conversions',
        'To replace traditional marketing completely',
        'To reduce marketing costs'
      ),
      'correctAnswer', 1,
      'points', 2,
      'explanation', 'Digital marketing aims to build brand awareness while driving measurable conversions and ROI.'
    ),
    jsonb_build_object(
      'id', gen_random_uuid()::text,
      'question', 'Which digital marketing channel is shown in the image below?',
      'type', 'multiple_choice',
      'imageUrl', 'https://images.unsplash.com/photo-1611162617474-5b21e879e113?w=600',
      'options', jsonb_build_array(
        'Email Marketing',
        'Social Media Marketing',
        'Search Engine Marketing',
        'Content Marketing'
      ),
      'correctAnswer', 1,
      'points', 2,
      'explanation', 'The image shows social media platforms, indicating social media marketing.'
    ),
    jsonb_build_object(
      'id', gen_random_uuid()::text,
      'question', 'True or False: SEO stands for Social Engine Optimization',
      'type', 'true_false',
      'options', jsonb_build_array('True', 'False'),
      'correctAnswer', 1,
      'points', 1,
      'explanation', 'SEO stands for Search Engine Optimization, not Social Engine Optimization.'
    )
  )
)
RETURNING id;

-- Save as 'ASSESSMENT1_ID', then create lecture link:
INSERT INTO learning_course_lectures (section_id, title, content_type, content_url, duration_minutes, order_index, description)
VALUES ('MODULE1_ID', 'Digital Marketing Basics Quiz', 'quiz', 'ASSESSMENT1_ID', 20, 999, 'Test your knowledge');

-- ==================================================================
-- ASSESSMENT 2: SEO Strategy Assignment
-- ==================================================================

INSERT INTO learning_course_assessments (
  section_id,
  title,
  assessment_type,
  description,
  passing_criteria,
  weightage,
  attempts_allowed,
  is_auto_evaluated,
  questions
) VALUES (
  'MODULE2_ID',
  'SEO Keyword Research Assignment',
  'Assignment',
  'Conduct keyword research for a sample business and create an SEO strategy',
  60.0,
  20.0,
  2,
  false,
  jsonb_build_array(
    jsonb_build_object(
      'id', gen_random_uuid()::text,
      'question', 'Choose a local business in your area and identify 10 relevant keywords with search volume data. Use tools like Google Keyword Planner or Ubersuggest.',
      'type', 'descriptive',
      'points', 5,
      'explanation', 'This exercise helps you practice real-world keyword research.'
    ),
    jsonb_build_object(
      'id', gen_random_uuid()::text,
      'question', 'Create a content calendar for 1 month with blog topics based on your keyword research.',
      'type', 'descriptive',
      'points', 5,
      'explanation', 'Planning content around keywords is crucial for SEO success.'
    )
  )
)
RETURNING id;

-- Create lecture link for Assessment 2
INSERT INTO learning_course_lectures (section_id, title, content_type, content_url, duration_minutes, order_index, description)
VALUES ('MODULE2_ID', 'SEO Keyword Research Assignment', 'assignment', 'ASSESSMENT2_ID', 120, 999, 'Submit your keyword research');

-- ==================================================================
-- FINAL ASSESSMENT SECTION
-- ==================================================================

INSERT INTO learning_course_sections (
  course_id,
  title,
  order_index,
  description,
  module_type,
  is_mandatory
) VALUES (
  'COURSE_ID',
  'Final Assessment',
  999,
  'Comprehensive final exam covering all course topics',
  'Assessment',
  true
)
RETURNING id;

-- Save as 'FINAL_SECTION_ID'

-- ==================================================================
-- FINAL EXAM
-- ==================================================================

INSERT INTO learning_course_assessments (
  section_id,
  title,
  assessment_type,
  description,
  passing_criteria,
  weightage,
  attempts_allowed,
  is_auto_evaluated,
  questions
) VALUES (
  'FINAL_SECTION_ID',
  'Final Exam - Digital Marketing Fundamentals',
  'Quiz',
  'Comprehensive assessment covering all modules. Must score 70% to earn certificate.',
  70.0,
  50.0,
  2,
  true,
  jsonb_build_array(
    jsonb_build_object(
      'id', gen_random_uuid()::text,
      'question', 'What is the most important metric for measuring digital marketing ROI?',
      'type', 'multiple_choice',
      'options', jsonb_build_array(
        'Website traffic',
        'Social media followers',
        'Conversion rate',
        'Email open rate'
      ),
      'correctAnswer', 2,
      'points', 3
    ),
    jsonb_build_object(
      'id', gen_random_uuid()::text,
      'question', 'Which SEO factor is most important for ranking?',
      'type', 'multiple_choice',
      'options', jsonb_build_array(
        'Meta descriptions',
        'Quality backlinks',
        'Keyword density',
        'Social shares'
      ),
      'correctAnswer', 1,
      'points', 3
    ),
    jsonb_build_object(
      'id', gen_random_uuid()::text,
      'question', 'What does CTR stand for in digital marketing?',
      'type', 'multiple_choice',
      'options', jsonb_build_array(
        'Click Through Rate',
        'Cost To Revenue',
        'Customer Trust Rating',
        'Content Traffic Ratio'
      ),
      'correctAnswer', 0,
      'points', 2
    ),
    jsonb_build_object(
      'id', gen_random_uuid()::text,
      'question', 'Social media marketing is only effective for B2C businesses.',
      'type', 'true_false',
      'options', jsonb_build_array('True', 'False'),
      'correctAnswer', 1,
      'points', 2,
      'explanation', 'Social media can be very effective for both B2C and B2B marketing when done strategically.'
    )
  )
)
RETURNING id;

-- Create lecture link for Final Exam
INSERT INTO learning_course_lectures (section_id, title, content_type, content_url, duration_minutes, order_index, description)
VALUES ('FINAL_SECTION_ID', 'Final Exam - Digital Marketing Fundamentals', 'quiz', 'FINAL_EXAM_ID', 60, 1, 'Complete the final exam to earn your certificate');

-- ==================================================================
-- INSTRUCTIONS
-- ==================================================================

/*
To execute this script:

1. First, find your organization and faculty IDs:
   SELECT id, name FROM organizations WHERE name LIKE '%Poornaprajna%';
   SELECT id, full_name FROM profiles WHERE role = 'faculty' LIMIT 5;

2. Replace all instances of:
   - 'YOUR_FACULTY_ID' with actual faculty user ID
   - 'COURSE_ID' with the ID returned from the course insert
   - 'MODULE1_ID', 'MODULE2_ID', 'MODULE3_ID', 'FINAL_SECTION_ID' with respective section IDs
   - 'ASSESSMENT1_ID', 'ASSESSMENT2_ID', 'FINAL_EXAM_ID' with respective assessment IDs

3. Execute each section in order, capturing the RETURNING id values

4. After completion, students can:
   - Enroll in the course through the student portal
   - View all modules and lectures
   - Take assessments (including one with an image)
   - Complete the final exam to earn a certificate
*/
