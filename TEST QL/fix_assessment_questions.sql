-- Fix Assessment Question Data Structure Issues

-- Problem: Questions in database might have wrong JSON keys
-- The app expects: 'question_text', 'type', 'options', 'correct_answers'
-- But may have: 'question', 'questionType', etc.

-- Step 1: Check current question structure
SELECT 
  a.id,
  a.title,
  jsonb_array_length(a.questions) as question_count,
  a.questions->0 as sample_question,
  jsonb_object_keys(a.questions->0) as question_keys
FROM learning_course_assessments a
WHERE jsonb_array_length(a.questions) > 0
LIMIT 5;

-- Step 2: If keys are wrong, create a migration function
CREATE OR REPLACE FUNCTION normalize_assessment_questions()
RETURNS void AS $$
DECLARE
  assessment_record RECORD;
  normalized_questions JSONB;
  question JSONB;
  normalized_question JSONB;
BEGIN
  FOR assessment_record IN 
    SELECT id, questions 
    FROM learning_course_assessments 
    WHERE questions IS NOT NULL AND jsonb_array_length(questions) > 0
  LOOP
    normalized_questions := '[]'::jsonb;
    
    FOR question IN SELECT * FROM jsonb_array_elements(assessment_record.questions)
    LOOP
      -- Normalize question structure
      normalized_question := jsonb_build_object(
        'id', COALESCE(question->>'id', gen_random_uuid()::text),
        'question_text', COALESCE(question->>'question_text', question->>'question', ''),
        'type', COALESCE(question->>'type', question->>'questionType', 'mcq'),
        'options', COALESCE(question->'options', '[]'::jsonb),
        'correct_answers', COALESCE(question->'correct_answers', question->'correctAnswers', '[]'::jsonb),
        'correct_answer', question->>'correct_answer',
        'points', COALESCE((question->>'points')::int, 1),
        'explanation', question->>'explanation'
      );
      
      normalized_questions := normalized_questions || jsonb_build_array(normalized_question);
    END LOOP;
    
    -- Update the assessment with normalized questions
    UPDATE learning_course_assessments
    SET questions = normalized_questions
    WHERE id = assessment_record.id;
    
    RAISE NOTICE 'Normalized questions for assessment %', assessment_record.id;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Run the normalization
SELECT normalize_assessment_questions();

-- Step 4: Verify the fix
SELECT 
  a.id,
  a.title,
  jsonb_array_length(a.questions) as question_count,
  a.questions->0->>'question_text' as first_question_text,
  a.questions->0->>'type' as first_question_type,
  jsonb_array_length(a.questions->0->'options') as option_count
FROM learning_course_assessments a
WHERE jsonb_array_length(a.questions) > 0;

-- Step 5: If questions are completely empty/null, here's how to add sample questions
-- (Use this for the "Digital Marketing Basics Quiz" that has no questions)
UPDATE learning_course_assessments
SET questions = '[
  {
    "id": "q1",
    "question_text": "What is the primary goal of SEO?",
    "type": "mcq",
    "options": [
      "To increase website traffic through organic search",
      "To create social media content",
      "To design better websites",
      "To send emails to customers"
    ],
    "correct_answers": [0],
    "points": 10,
    "explanation": "SEO (Search Engine Optimization) aims to improve website visibility in organic search results."
  },
  {
    "id": "q2",
    "question_text": "Which platform is best for B2B marketing?",
    "type": "mcq",
    "options": [
      "TikTok",
      "LinkedIn",
      "Instagram",
      "Snapchat"
    ],
    "correct_answers": [1],
    "points": 10,
    "explanation": "LinkedIn is the leading professional networking platform, making it ideal for B2B marketing."
  },
  {
    "id": "q3",
    "question_text": "Content marketing helps build trust with your audience.",
    "type": "true_false",
    "options": ["True", "False"],
    "correct_answers": [0],
    "points": 5,
    "explanation": "Quality content establishes authority and trust with your target audience."
  }
]'::jsonb
WHERE title = 'Digital Marketing Basics Quiz' AND jsonb_array_length(questions) = 0;

-- Grant permissions
GRANT EXECUTE ON FUNCTION normalize_assessment_questions() TO authenticated;
