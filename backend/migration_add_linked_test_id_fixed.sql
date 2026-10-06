-- =====================================================
-- MIGRATION: ADD LINKED TEST ID TO QUESTIONS (FIXED)
-- Purpose: Replace fragile JSONB tagging with strict foreign key.
-- Fix: Only link if Test ID actually exists to avoid FK errors.
-- =====================================================

-- 1. Add nullable column linked_test_id
ALTER TABLE public.aptitude_questions 
ADD COLUMN IF NOT EXISTS linked_test_id UUID REFERENCES public.aptitude_tests(id) ON DELETE CASCADE;

-- 2. Backfill data from tags (SAFE UPDATE)
-- Only update if the parsed UUID exists in aptitude_tests
UPDATE public.aptitude_questions q
SET linked_test_id = (
    SELECT split_part(element, ':', 2)::uuid
    FROM jsonb_array_elements_text(q.tags) AS element
    WHERE element LIKE 'test_id:%'
    LIMIT 1
)
WHERE q.tags::text LIKE '%test_id:%' 
AND q.linked_test_id IS NULL
AND EXISTS (
    SELECT 1 FROM public.aptitude_tests t 
    WHERE t.id = (
        SELECT split_part(element, ':', 2)::uuid
        FROM jsonb_array_elements_text(q.tags) AS element
        WHERE element LIKE 'test_id:%'
        LIMIT 1
    )
);

-- 3. Update Creator Function
CREATE OR REPLACE FUNCTION public.create_full_aptitude_test(
    p_test_data JSONB,
    p_questions_data JSONB,
    p_assignment_data JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_test_id UUID;
    v_question JSONB;
    v_question_id UUID;
    v_assignment_id UUID;
    v_user_id UUID;
    v_org_id UUID;
BEGIN
    v_user_id := auth.uid();
    v_org_id := (p_test_data->>'organization_id')::UUID;
    
    -- 1. Create Test
    INSERT INTO public.aptitude_tests (
        module_id, test_type, title, description,
        difficulty, duration_minutes, total_questions,
        passing_score, instructions, is_active,
        created_by, organization_id
    ) VALUES (
        (p_test_data->>'module_id')::UUID,
        p_test_data->>'test_type',
        p_test_data->>'title',
        p_test_data->>'description',
        p_test_data->>'difficulty',
        (p_test_data->>'duration_minutes')::INTEGER,
        jsonb_array_length(p_questions_data),
        (p_test_data->>'passing_score')::INTEGER,
        p_test_data->>'instructions',
        true,
        v_user_id,
        v_org_id
    )
    RETURNING id INTO v_test_id;

    -- 2. Insert Questions with linked_test_id
    FOR v_question IN SELECT * FROM jsonb_array_elements(p_questions_data)
    LOOP
        INSERT INTO public.aptitude_questions (
            module_id, question_text, options, correct_answer,
            explanation, difficulty, tags, created_by,
            linked_test_id -- <--- NEW COLUMN
        ) VALUES (
            (p_test_data->>'module_id')::UUID,
            v_question->>'question_text',
            v_question->'options',
            (v_question->>'correct_answer')::INTEGER,
            v_question->>'explanation',
            p_test_data->>'difficulty',
            COALESCE(v_question->'tags', '[]'::jsonb),
            v_user_id,
            v_test_id -- <--- LINK DIRECTLY
        );
    END LOOP;

    -- 3. Create Assignment
    IF p_assignment_data IS NOT NULL THEN
        INSERT INTO public.test_assignments (
            test_id, assigned_by, assigned_by_role, organization_id,
            assignment_type, assigned_to_user, assigned_to_department,
            assigned_to_batch, assigned_to_job_id, start_date, deadline,
            max_attempts, is_mandatory, weightage, send_notification 
        ) VALUES (
            v_test_id, v_user_id, p_assignment_data->>'assigned_by_role', v_org_id,
            p_assignment_data->>'assignment_type', (p_assignment_data->>'assigned_to_user')::UUID,
            p_assignment_data->>'assigned_to_department', p_assignment_data->>'assigned_to_batch',
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

    RETURN jsonb_build_object(
        'test_id', v_test_id,
        'assignment_id', v_assignment_id,
        'message', 'Test and assignment created successfully'
    );
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to create aptitude test: %', SQLERRM;
END;
$$;
