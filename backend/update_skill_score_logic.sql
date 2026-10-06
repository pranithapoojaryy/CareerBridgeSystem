-- 1. Create a scalar function to calculate the total skill score (Reusable)
CREATE OR REPLACE FUNCTION public.calculate_total_skill_score(p_student_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_cert_a_score INTEGER;
    v_cert_b_score INTEGER;
    v_project_score INTEGER;
    v_aptitude_score INTEGER;
    v_assessment_score INTEGER;
    v_event_score INTEGER;
    v_interview_score INTEGER;
    v_total_score INTEGER;
BEGIN
    -- A. Certificates (30%)
    -- Tier A: 15 pts (Max 15)
    SELECT COALESCE(COUNT(*) * 15, 0) INTO v_cert_a_score
    FROM public.student_certifications sc
    JOIN public.certification_providers cp ON sc.provider_id = cp.id
    WHERE sc.student_id = p_student_id AND sc.validation_status = 'verified' AND cp.provider_category = 'A';
    IF v_cert_a_score > 15 THEN v_cert_a_score := 15; END IF;

    -- Tier B: 5 pts (Max 10)
    SELECT COALESCE(COUNT(*) * 5, 0) INTO v_cert_b_score
    FROM public.student_certifications sc
    JOIN public.certification_providers cp ON sc.provider_id = cp.id
    WHERE sc.student_id = p_student_id AND sc.validation_status = 'verified' AND cp.provider_category = 'B';
    IF v_cert_b_score > 10 THEN v_cert_b_score := 10; END IF;
    
    -- College Verified: 5 pts (Max 5) - assuming 'college_verified' status or specific criteria
    -- For simplicity, adding to Tier B logic or handling separately. Let's strictly follow plan:
    -- Plan said: "College Verified: 5 pts/cert (Max 5)". 
    -- We can check validation_status = 'college_verified'
    DECLARE 
        v_cert_c_score INTEGER;
    BEGIN
        SELECT COALESCE(COUNT(*) * 5, 0) INTO v_cert_c_score
        FROM public.student_certifications
        WHERE student_id = p_student_id AND validation_status = 'college_verified';
        IF v_cert_c_score > 5 THEN v_cert_c_score := 5; END IF;
        
        -- Combine Cert Scores
        v_cert_a_score := v_cert_a_score + v_cert_b_score + v_cert_c_score;
    END;

    -- B. Projects (20%)
    -- 10 pts per project (Max 20)
    SELECT COALESCE(COUNT(*) * 10, 0) INTO v_project_score
    FROM public.student_projects
    WHERE student_id = p_student_id;
    -- Also include posts referenced as projects if any
    DECLARE
        v_post_projects INTEGER;
    BEGIN
         SELECT COALESCE(COUNT(*) * 10, 0) INTO v_post_projects
         FROM public.posts
         WHERE author_id = p_student_id AND reference_type = 'project';
         v_project_score := v_project_score + v_post_projects;
    END;
    IF v_project_score > 20 THEN v_project_score := 20; END IF;

    -- C. Aptitude & Assessments (25%)
    -- Aptitude: Avg % * 0.15 (Max 15)
    SELECT COALESCE(
        (AVG(percentage) * 0.15)::INTEGER,
        0
    ) INTO v_aptitude_score
    FROM public.aptitude_attempts
    WHERE student_id = p_student_id AND test_type = 'assignment' AND status = 'completed';
    IF v_aptitude_score > 15 THEN v_aptitude_score := 15; END IF;

    -- Assessments: 5 pts per passed (Max 10)
    SELECT COALESCE(COUNT(*) * 5, 0) INTO v_assessment_score
    FROM public.student_assessment_submissions
    WHERE student_id = p_student_id AND is_passed = true;
    IF v_assessment_score > 10 THEN v_assessment_score := 10; END IF;

    -- D. Events (15%)
    -- 5 pts per attended (Max 15)
    SELECT COALESCE(COUNT(*) * 5, 0) INTO v_event_score
    FROM public.event_registrations
    WHERE student_id = p_student_id AND attended = true;
    IF v_event_score > 15 THEN v_event_score := 15; END IF;

    -- E. Interviews (10%)
    -- Mock Interviews Avg Score (normalized to 10)
    -- Assuming mock total_score is out of 100.
    SELECT COALESCE(
        (AVG(total_score) * 0.1)::INTEGER,
        0
    ) INTO v_interview_score
    FROM public.mock_attempts
    WHERE student_id = p_student_id AND status = 'graded';
    IF v_interview_score > 10 THEN v_interview_score := 10; END IF;

    -- Total
    v_total_score := v_cert_a_score + v_project_score + v_aptitude_score + v_assessment_score + v_event_score + v_interview_score;
    IF v_total_score > 100 THEN v_total_score := 100; END IF;

    RETURN v_total_score;
END;
$function$;

-- 2. Update the Breakdown Function (Frontend Details)
CREATE OR REPLACE FUNCTION public.get_skill_score_breakdown(p_student_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_cert_score INTEGER := 0;
    v_project_score INTEGER := 0;
    v_aptitude_score INTEGER := 0;
    v_assessment_score INTEGER := 0;
    v_event_score INTEGER := 0;
    v_interview_score INTEGER := 0;
    
    -- Sub-calcs for details
    v_cert_a_count INTEGER;
    v_cert_total_calc INTEGER;
    
    v_total_score INTEGER;
BEGIN
    -- Re-calculating components for breakdown (similar logic to scalar func)
    
    -- Certs
    SELECT COALESCE(SUM(CASE 
        WHEN cp.provider_category = 'A' THEN 15 
        WHEN cp.provider_category = 'B' THEN 5 
        ELSE 0 END), 0)
    INTO v_cert_score
    FROM public.student_certifications sc
    JOIN public.certification_providers cp ON sc.provider_id = cp.id
    WHERE sc.student_id = p_student_id AND sc.validation_status = 'verified';
    
    -- Add College Verified
    v_cert_score := v_cert_score + (SELECT COALESCE(COUNT(*) * 5, 0) FROM public.student_certifications WHERE student_id = p_student_id AND validation_status = 'college_verified');
    
    -- Cap Certs conceptually for breakdown display (Max 30)
    IF v_cert_score > 30 THEN v_cert_score := 30; END IF;

    -- Projects
    v_project_score := (SELECT COALESCE(COUNT(*) * 10, 0) FROM public.student_projects WHERE student_id = p_student_id);
    v_project_score := v_project_score + (SELECT COALESCE(COUNT(*) * 10, 0) FROM public.posts WHERE author_id = p_student_id AND reference_type = 'project');
    IF v_project_score > 20 THEN v_project_score := 20; END IF;

    -- Aptitude
    SELECT COALESCE((AVG(percentage) * 0.15)::INTEGER, 0) INTO v_aptitude_score
    FROM public.aptitude_attempts WHERE student_id = p_student_id AND test_type = 'assignment' AND status = 'completed';
    IF v_aptitude_score > 15 THEN v_aptitude_score := 15; END IF;

    -- Assessments
    SELECT COALESCE(COUNT(*) * 5, 0) INTO v_assessment_score
    FROM public.student_assessment_submissions WHERE student_id = p_student_id AND is_passed = true;
    IF v_assessment_score > 10 THEN v_assessment_score := 10; END IF;

    -- Events
    SELECT COALESCE(COUNT(*) * 5, 0) INTO v_event_score
    FROM public.event_registrations WHERE student_id = p_student_id AND attended = true;
    IF v_event_score > 15 THEN v_event_score := 15; END IF;

    -- Interviews
    SELECT COALESCE((AVG(total_score) * 0.1)::INTEGER, 0) INTO v_interview_score
    FROM public.mock_attempts WHERE student_id = p_student_id AND status = 'graded';
    IF v_interview_score > 10 THEN v_interview_score := 10; END IF;

    -- Total
    v_total_score := v_cert_score + v_project_score + v_aptitude_score + v_assessment_score + v_event_score + v_interview_score;
    IF v_total_score > 100 THEN v_total_score := 100; END IF;

    RETURN jsonb_build_object(
        'total_score', v_total_score,
        'breakdown', jsonb_build_array(
            jsonb_build_object('label', 'Certifications (Max 30)', 'score', v_cert_score, 'color', '0xFF4CAF50'),
            jsonb_build_object('label', 'Projects (Max 20)', 'score', v_project_score, 'color', '0xFF2196F3'),
            jsonb_build_object('label', 'Aptitude (Max 15)', 'score', v_aptitude_score, 'color', '0xFFFF5722'),
            jsonb_build_object('label', 'Tech Assessments (Max 10)', 'score', v_assessment_score, 'color', '0xFFFF9800'),
            jsonb_build_object('label', 'Events (Max 15)', 'score', v_event_score, 'color', '0xFF9C27B0'),
            jsonb_build_object('label', 'Mock Interviews (Max 10)', 'score', v_interview_score, 'color', '0xFF607D8B')
        ),
        'tips', jsonb_build_array(
            'Upload Verified Certificates to boost your score significantly.',
            'Add projects to your profile to showcase hands-on skills.',
            'Maintain high accuracy in Aptitude Assignments.',
            'Participate in College Events and get your attendance marked.',
            'Take Mock Interviews to improve your readiness score.'
        )
    );
END;
$function$;

-- 3. Transition student_stats to View
-- Rename old table if it exists (Idempotent check)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'student_stats') THEN
        ALTER TABLE public.student_stats RENAME TO student_stats_legacy;
    END IF;
END $$;

-- Create dynamic View matching the expected schema
CREATE OR REPLACE VIEW public.student_stats AS
SELECT 
    p.id as student_id,
    public.calculate_total_skill_score(p.id) as skill_score,
    (SELECT COUNT(*) FROM public.job_applications ja WHERE ja.student_id = p.id) as applications_sent,
    (SELECT COUNT(*) FROM public.student_assessment_submissions sas WHERE sas.student_id = p.id AND sas.is_passed = true) as assessments_completed,
    (SELECT COUNT(*) FROM public.event_registrations er WHERE er.student_id = p.id AND er.attended = true) as events_attended,
    (SELECT COUNT(*) FROM public.student_course_enrollments sce WHERE sce.student_id = p.id) as courses_enrolled,
    now() as last_updated
FROM public.profiles p
WHERE p.role = 'student';
