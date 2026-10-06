# Execute in Supabase SQL Editor

## Instructions:
1. Open Supabase Dashboard > SQL Editor
2. Create a new query
3. Copy and paste the ENTIRE contents below
4. Click "Run" button
5. Verify success message

---

## Part 1: Fix Assessment Questions

```sql
${include:c:\Users\ASUS\Desktop\CareerBridge\fix_assessment_questions.sql}
```

---

## Part 2: Add Analytics Functions

```sql
${include:c:\Users\ASUS\Desktop\CareerBridge\analytics_functions.sql}
```

---

## Verification

After running both parts, verify with:

```sql
-- Check normalized questions
SELECT 
  title,
  jsonb_array_length(questions) as question_count,
  questions->0->>'question_text' as first_question
FROM learning_course_assessments 
WHERE jsonb_array_length(questions) > 0;

-- Check analytics functions exist  
SELECT routine_name 
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%analytics%' 
  OR routine_name LIKE 'get_%students%'
  OR routine_name LIKE 'get_%courses%';
```

Expected: Questions should have proper structure, 7+ analytics functions should be listed.
