-- =====================================================
-- UPDATE SKILL ENGINE FOR APTITUDE SCORES
-- =====================================================
-- Run this after migration_009_aptitude_system.sql

-- 1. Add aptitude_assignment weight to skill_weights table
INSERT INTO public.skill_weights (type, weight) VALUES
('aptitude_assignment', 15)  -- 15 points per completed assignment test
ON CONFLICT (type) DO NOTHING;

-- 2. Update the calculate_student_skill_score function to include aptitude scores
CREATE OR REPLACE FUNCTION calculate_student_skill_score(p_student_id UUID) 
RETURNS INTEGER AS $$
DECLARE
    v_score INTEGER := 0;
    v_cert_a_score INTEGER;
    v_cert_b_score INTEGER;
    v_cert_c_score INTEGER;
    v_project_score INTEGER;
    v_assessment_score INTEGER;
    v_aptitude_score INTEGER;
    v_event_score INTEGER;
BEGIN
    -- 1. Certificates Score
    SELECT COALESCE(COUNT(*), 0) * (SELECT weight FROM public.skill_weights WHERE type='certificate_A')
    INTO v_cert_a_score
    FROM public.student_certifications sc
    JOIN public.certification_providers cp ON sc.provider_id = cp.id
    WHERE sc.student_id = p_student_id AND sc.validation_status = 'verified' AND cp.provider_category = 'A';

    SELECT COALESCE(COUNT(*), 0) * (SELECT weight FROM public.skill_weights WHERE type='certificate_B')
    INTO v_cert_b_score
    FROM public.student_certifications sc
    JOIN public.certification_providers cp ON sc.provider_id = cp.id
    WHERE sc.student_id = p_student_id AND sc.validation_status = 'verified' AND cp.provider_category = 'B';
    
    -- 2. Projects Score
    SELECT COALESCE(COUNT(*), 0) * (SELECT weight FROM public.skill_weights WHERE type='project')
    INTO v_project_score
    FROM public.posts
    WHERE author_id = p_student_id AND reference_type = 'project';

    -- 3. Events Attended
    SELECT COALESCE(COUNT(*), 0) * (SELECT weight FROM public.skill_weights WHERE type='event')
    INTO v_event_score
    FROM public.student_activity_logs
    WHERE student_id = p_student_id AND activity_type = 'event_attended';

    -- 4. Aptitude Assignments Score (NEW)
    -- Get average percentage of completed assignment tests and multiply by weight
    SELECT COALESCE(
        (AVG(percentage) / 100.0) * (SELECT weight FROM public.skill_weights WHERE type='aptitude_assignment'),
        0
    )::INTEGER
    INTO v_aptitude_score
    FROM public.aptitude_attempts
    WHERE student_id = p_student_id 
    AND test_type = 'assignment' 
    AND status = 'completed';

    -- 5. Old Assessment Score (from existing assessments table)
    v_assessment_score := 0;  -- Placeholder, can be computed if needed

    -- Total Calculation
    v_score := v_cert_a_score + v_cert_b_score + COALESCE(v_cert_c_score, 0) + 
               v_project_score + v_assessment_score + v_aptitude_score + v_event_score;
    
    -- Cap at 100
    IF v_score > 100 THEN
        v_score := 100;
    END IF;

    RETURN v_score;
END;
$$ LANGUAGE plpgsql;

-- 3. Update the get_skill_score_breakdown function
CREATE OR REPLACE FUNCTION get_skill_score_breakdown(p_student_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_cert_a_score INTEGER;
    v_cert_b_score INTEGER;
    v_project_score INTEGER;
    v_assessment_score INTEGER;
    v_aptitude_score INTEGER;
    v_event_score INTEGER;
    v_total_score INTEGER;
BEGIN
    -- 1. Certificates Score
    SELECT COALESCE(COUNT(*), 0) * (SELECT weight FROM public.skill_weights WHERE type='certificate_A')
    INTO v_cert_a_score
    FROM public.student_certifications sc
    JOIN public.certification_providers cp ON sc.provider_id = cp.id
    WHERE sc.student_id = p_student_id AND sc.validation_status = 'verified' AND cp.provider_category = 'A';

    SELECT COALESCE(COUNT(*), 0) * (SELECT weight FROM public.skill_weights WHERE type='certificate_B')
    INTO v_cert_b_score
    FROM public.student_certifications sc
    JOIN public.certification_providers cp ON sc.provider_id = cp.id
    WHERE sc.student_id = p_student_id AND sc.validation_status = 'verified' AND cp.provider_category = 'B';
    
    -- 2. Projects Score
    SELECT COALESCE(COUNT(*), 0) * (SELECT weight FROM public.skill_weights WHERE type='project')
    INTO v_project_score
    FROM public.posts
    WHERE author_id = p_student_id AND reference_type = 'project';

    -- 3. Events
    SELECT COALESCE(COUNT(*), 0) * (SELECT weight FROM public.skill_weights WHERE type='event')
    INTO v_event_score
    FROM public.student_activity_logs
    WHERE student_id = p_student_id AND activity_type = 'event_attended';

    -- 4. Aptitude Assessments (NEW)
    SELECT COALESCE(
        (AVG(percentage) / 100.0) * (SELECT weight FROM public.skill_weights WHERE type='aptitude_assignment'),
        0
    )::INTEGER
    INTO v_aptitude_score
    FROM public.aptitude_attempts
    WHERE student_id = p_student_id 
    AND test_type = 'assignment' 
    AND status = 'completed';

    -- 5. Old Assessments (Placeholder)
    v_assessment_score := 0;

    v_total_score := v_cert_a_score + v_cert_b_score + v_project_score + v_assessment_score + v_aptitude_score + v_event_score;
    IF v_total_score > 100 THEN v_total_score := 100; END IF;

    RETURN jsonb_build_object(
        'total_score', v_total_score,
        'breakdown', jsonb_build_array(
            jsonb_build_object('label', 'Verified Certificates (Top Tier)', 'score', v_cert_a_score, 'color', '0xFF4CAF50'),
            jsonb_build_object('label', 'Standard Certificates', 'score', v_cert_b_score, 'color', '0xFF8BC34A'),
            jsonb_build_object('label', 'Projects', 'score', v_project_score, 'color', '0xFF2196F3'),
            jsonb_build_object('label', 'Aptitude Tests', 'score', v_aptitude_score, 'color', '0xFFFF5722'),
            jsonb_build_object('label', 'Assessments', 'score', v_assessment_score, 'color', '0xFFFF9800'),
            jsonb_build_object('label', 'Events & Participation', 'score', v_event_score, 'color', '0xFF9C27B0')
        ),
        'tips', jsonb_build_array(
            'Complete aptitude assignments from your college to boost your score.',
            'Practice tests help you prepare but don''t count towards skill score.',
            'Get your projects verified by mentors to increase project weightage.',
            'Attend college hackathons (Category A events) for maximum points.'
        )
    );
END;
$$ LANGUAGE plpgsql;

-- 4. Create trigger to update skill score when aptitude test is completed
CREATE OR REPLACE FUNCTION update_skill_score_on_aptitude_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger for assignment tests that are completed
    IF NEW.test_type = 'assignment' AND NEW.status = 'completed' AND 
       (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status != 'completed')) THEN
        
        -- Call the skill score calculator
        PERFORM calculate_student_skill_score(NEW.student_id);
        
        -- Update student_stats table
        INSERT INTO public.student_stats (student_id, skill_score, assessments_completed, last_updated)
        VALUES (
            NEW.student_id, 
            calculate_student_skill_score(NEW.student_id),
            1,
            now()
        )
        ON CONFLICT (student_id) 
        DO UPDATE SET 
            skill_score = calculate_student_skill_score(NEW.student_id),
            assessments_completed = student_stats.assessments_completed + 1,
            last_updated = now();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_skill_score_aptitude ON public.aptitude_attempts;
CREATE TRIGGER trg_update_skill_score_aptitude
AFTER INSERT OR UPDATE ON public.aptitude_attempts
FOR EACH ROW EXECUTE FUNCTION update_skill_score_on_aptitude_completion();

-- Success message
SELECT 'Skill engine updated to include aptitude scores' as status;
