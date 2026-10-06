-- =====================================================
-- MIGRATION 010: APTITUDE TEST CREATOR FUNCTION
-- =====================================================

-- Function to create a full aptitude test with questions and assignment in one transaction
CREATE OR REPLACE FUNCTION public.create_full_aptitude_test(
    p_test_data JSONB,
    p_questions_data JSONB, -- Array of question objects
    p_assignment_data JSONB -- Assignment details
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with privileges of creator (to bypass some RLS if needed, but handled carefully)
AS $$
DECLARE
    v_test_id UUID;
    v_module_id UUID;
    v_question JSONB;
    v_question_id UUID;
    v_assignment_id UUID;
    v_user_id UUID;
    v_org_id UUID;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    -- validate organization_id
    v_org_id := (p_test_data->>'organization_id')::UUID;
    
    -- 1. Create the Test
    INSERT INTO public.aptitude_tests (
        module_id,
        test_type,
        title,
        description,
        difficulty,
        duration_minutes,
        total_questions,
        passing_score,
        instructions,
        is_active,
        created_by,
        organization_id
    ) VALUES (
        (p_test_data->>'module_id')::UUID,
        p_test_data->>'test_type',
        p_test_data->>'title',
        p_test_data->>'description',
        p_test_data->>'difficulty',
        (p_test_data->>'duration_minutes')::INTEGER,
        jsonb_array_length(p_questions_data), -- Auto-calculate total questions
        (p_test_data->>'passing_score')::INTEGER,
        p_test_data->>'instructions',
        true,
        v_user_id,
        v_org_id
    )
    RETURNING id INTO v_test_id;

    -- 2. Insert Questions
    FOR v_question IN SELECT * FROM jsonb_array_elements(p_questions_data)
    LOOP
        INSERT INTO public.aptitude_questions (
            module_id,
            question_text,
            options,
            correct_answer,
            explanation,
            difficulty,
            tags,
            created_by
        ) VALUES (
            (p_test_data->>'module_id')::UUID, -- Use same module as test
            v_question->>'question_text',
            v_question->'options',
            (v_question->>'correct_answer')::INTEGER,
            v_question->>'explanation',
            p_test_data->>'difficulty', -- inherit difficulty from test for now
            v_question->'tags',
            v_user_id
        )
        RETURNING id INTO v_question_id;
        
        -- NOTE: In a more complex system, we might link questions to tests strictly via a many-to-many table. 
        -- For now, we assume tests dynamically pull questions or we will implement a linking table later if needed.
        -- BUT, the current schema `aptitude_attempts` stores the `questions` array.
        -- The `aptitude_tests` table definition implies it's a "blueprint". 
        -- However, `aptitude_questions` are linked to `module_id`, not `test_id`.
        -- So essentially, a "Test" is a configuration that draws questions from a module? 
        -- OR, does this specific test need these specific questions?
        
        -- REVIEWING EXISTING SCHEMA:
        -- aptitude_questions has module_id.
        -- aptitude_tests has module_id.
        -- There is NO direct link table `test_questions`.
        -- This implies tests either:
        -- A) Randomly select questions from the module (Practice mode)
        -- B) Need a specific set of questions (Assignment mode)
        
        -- If it's an assignment (College/Recruiter), we usually want Fixed Questions.
        -- BUT the schema doesn't seem to have a `test_questions` table.
        -- Looking at `aptitude_attempts`, it stores `questions JSONB` (array of IDs).
        
        -- DECISION: To support "Custom Tests" where a recruiter adds specific questions, 
        -- we should probably ensure these questions are identifiable for this test.
        -- We can use `tags` in `aptitude_questions` to tag them with `test_id:{v_test_id}` 
        -- so we can fetch them later for this specific test.
        
        -- Updating the question we just inserted to add the test_id tag if needed, 
        -- or just relying on the fact they were added now.
        -- A better approach for the future: Add a `test_id` column to `aptitude_questions` (nullable) 
        -- or a `test_questions` link table. 
        -- For this migration, to avoid altering schema too aggressively, I will TAG the questions.
        
        UPDATE public.aptitude_questions 
        SET tags = tags || jsonb_build_array('test_id:' || v_test_id::text)
        WHERE id = v_question_id;
        
    END LOOP;

    -- 3. Create the Assignment (if it's not just a draft)
    IF p_assignment_data IS NOT NULL THEN
        INSERT INTO public.test_assignments (
            test_id,
            assigned_by,
            assigned_by_role,
            organization_id,
            assignment_type,
            assigned_to_user,
            assigned_to_department,
            assigned_to_batch,
            assigned_to_job_id,
            start_date,
            deadline,
            max_attempts,
            is_mandatory,
            weightage,
            send_notification 
        ) VALUES (
            v_test_id,
            v_user_id,
            p_assignment_data->>'assigned_by_role',
            v_org_id,
            p_assignment_data->>'assignment_type',
            (p_assignment_data->>'assigned_to_user')::UUID,
            p_assignment_data->>'assigned_to_department',
            p_assignment_data->>'assigned_to_batch',
            (p_assignment_data->>'assigned_to_job_id')::UUID,
            COALESCE((p_assignment_data->>'start_date')::TIMESTAMPTZ, now()),
            (p_assignment_data->>'deadline')::TIMESTAMPTZ,
            COALESCE((p_assignment_data->>'max_attempts')::INTEGER, 1),
            COALESCE((p_assignment_data->>'is_mandatory')::BOOLEAN, false),
            COALESCE((p_assignment_data->>'weightage')::DECIMAL, 15.0),
            COALESCE((p_assignment_data->>'send_notification')::BOOLEAN, true)
        )
        RETURNING id INTO v_assignment_id;
    END IF;

    -- Return the result
    RETURN jsonb_build_object(
        'test_id', v_test_id,
        'assignment_id', v_assignment_id,
        'message', 'Test and assignment created successfully'
    );

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to create aptitude test: %', SQLERRM;
END;
$$;

SELECT 'Function create_full_aptitude_test created successfully' as status;
