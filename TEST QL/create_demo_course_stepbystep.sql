-- Step-by-step Demo Course Creation
-- Just execute each block one at a time and note the returned ID

-- ==================================================================
-- STEP 1: Create the Course
-- ==================================================================

INSERT INTO learning_courses (
  title,
  description,
  provider_id,
  provider_name,
  category,
  difficulty,
  price,
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
  'Master the essentials of digital marketing including SEO, social media marketing, content marketing, and analytics.',
  '6984606b-f491-40cb-9984-696ee22ef86d',  -- Dr. Bharath V
  'Poornaprajna Institute of Management',
  'Marketing',
  'Intermediate',
  0,
  true,
  100,
  ARRAY['Marketing', 'Digital Marketing', 'SEO', 'Social Media'],
  true,
  'Basic understanding of marketing principles',
  'Digital Marketing Specialist',
  8,
  'High',
  ARRAY['SEO', 'Social Media Strategy', 'Content Marketing', 'Analytics'],
  'Students will learn to create comprehensive digital marketing strategies and analyze campaign performance.',
  'Management'
)
RETURNING id;

-- ⚠️ COPY THE RETURNED ID FROM ABOVE
-- Then run this query to verify it was created:
-- SELECT id, title, provider_name FROM learning_courses ORDER BY created_at DESC LIMIT 1;

-- ==================================================================
-- STEP 2: Create Module 1 - Introduction
-- Replace 'PASTE_COURSE_ID_HERE' with the ID from Step 1
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
  'PASTE_COURSE_ID_HERE',
  'Introduction to Digital Marketing',
  1,
  'Understanding the digital marketing landscape',
  'Theory',
  4,
  true,
  ARRAY['Digital Marketing Basics'],
  true
)
RETURNING id;

-- ⚠️ COPY THE RETURNED ID AS 'MODULE1_ID'

-- ==================================================================
-- STEP 3: Add Lectures to Module 1
-- Replace 'PASTE_MODULE1_ID_HERE' with ID from Step 2
-- ==================================================================

INSERT INTO learning_course_lectures (section_id, title, content_type, content_url, duration_minutes, order_index, description) VALUES
('2e2137a4-a4a8-490e-b7d5-9b4a0db40658', 'What is Digital Marketing?', 'video', 'https://www.youtube.com/watch?v=bixR-KIJKYM', 15, 1, 'Introduction to digital marketing'),
('2e2137a4-a4a8-490e-b7d5-9b4a0db40658', 'Digital vs Traditional Marketing', 'video', 'https://www.youtube.com/watch?v=YXvD7KJxsEQ', 20, 2, 'Comparing approaches'),
('2e2137a4-a4a8-490e-b7d5-9b4a0db40658', 'Understanding Your Audience', 'article', '', 30, 3, 'Target audience segmentation');

-- ==================================================================
-- STEP 4: Create Assessment with Image Question
-- Replace 'PASTE_MODULE1_ID_HERE' with Module 1 ID
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
  '2e2137a4-a4a8-490e-b7d5-9b4a0db40658',
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
        'To replace traditional marketing',
        'To reduce marketing costs'
      ),
      'correctAnswer', 1,
      'points', 2
    ),
    jsonb_build_object(
      'id', gen_random_uuid()::text,
      'question', 'Which digital marketing channel is shown in the image?',
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
      'explanation', 'The image shows social media platforms'
    ),
    jsonb_build_object(
      'id', gen_random_uuid()::text,
      'question', 'SEO stands for Social Engine Optimization',
      'type', 'true_false',
      'options', jsonb_build_array('True', 'False'),
      'correctAnswer', 1,
      'points', 1
    )
  )
)
RETURNING id;

-- ⚠️ COPY THE RETURNED ID AS 'ASSESSMENT1_ID'

-- ==================================================================
-- STEP 5: Link Assessment to Lecture
-- Replace both IDs below
-- ==================================================================

INSERT INTO learning_course_lectures (section_id, title, content_type, content_url, duration_minutes, order_index)
VALUES ('2e2137a4-a4a8-490e-b7d5-9b4a0db40658', 'Digital Marketing Basics Quiz', 'quiz', '6539a74c-9b2e-4c38-be11-c934248e44bd', 20, 999);

-- ==================================================================
-- STEP 6: Create Final Assessment Section
-- Replace 'PASTE_COURSE_ID_HERE' with course ID from Step 1
-- ==================================================================

INSERT INTO learning_course_sections (
  course_id,
  title,
  order_index,
  description,
  module_type,
  is_mandatory
) VALUES (
  '6dc5dea9-5bc0-45c6-ad8f-9e41e1304006',
  'Final Assessment',
  999,
  'Comprehensive final exam',
  'Assessment',
  true
)
RETURNING id;

-- ⚠️ COPY THE RETURNED ID AS 'FINAL_SECTION_ID'

-- ==================================================================
-- STEP 7: Create Final Exam
-- Replace 'PASTE_FINAL_SECTION_ID_HERE' with ID from Step 6
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
  '4012e79e-4fa6-4e04-a497-174810055efd',
  'Final Exam - Digital Marketing',
  'Quiz',
  'Pass with 70% to earn certificate',
  70.0,
  50.0,
  2,
  true,
  jsonb_build_array(
    jsonb_build_object(
      'id', gen_random_uuid()::text,
      'question', 'Most important metric for measuring ROI?',
      'type', 'multiple_choice',
      'options', jsonb_build_array('Traffic', 'Followers', 'Conversion rate', 'Email opens'),
      'correctAnswer', 2,
      'points', 3
    ),
    jsonb_build_object(
      'id', gen_random_uuid()::text,
      'question', 'What does CTR stand for?',
      'type', 'multiple_choice',
      'options', jsonb_build_array('Click Through Rate', 'Cost To Revenue', 'Customer Trust', 'Content Traffic'),
      'correctAnswer', 0,
      'points', 2
    )
  )
)
RETURNING id;

-- ⚠️ COPY THE RETURNED ID AS 'FINAL_EXAM_ID'

-- ==================================================================
-- STEP 8: Link Final Exam to Lecture
-- Replace both IDs below
-- ==================================================================

INSERT INTO learning_course_lectures (section_id, title, content_type, content_url, duration_minutes, order_index)
VALUES ('98132542-f019-4f59-8f6b-c2aeeaf58c8c E', 'Final Exam - Digital Marketing', 'quiz', '98132542-f019-4f59-8f6b-c2aeeaf58c8c', 60, 1);

-- ==================================================================
-- DONE! ✅
-- Now test:
-- 1. College portal - view the course
-- 2. Student portal - enroll and take assessments
-- ==================================================================
