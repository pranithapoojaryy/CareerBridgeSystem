-- Skill Score Engine & Student Stats Cache

-- 1. Student Stats Table (Cache for Dashboard)
CREATE TABLE IF NOT EXISTS public.student_stats (
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    skill_score INTEGER DEFAULT 0,
    applications_sent INTEGER DEFAULT 0,
    assessments_completed INTEGER DEFAULT 0,
    events_attended INTEGER DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2. Skill Weights Configuration (Admin Configurable)
CREATE TABLE IF NOT EXISTS public.skill_weights (
    type TEXT PRIMARY KEY, -- 'certificate_A', 'certificate_B', 'project', 'assessment', 'event'
    weight INTEGER NOT NULL
);

-- Seed defaults if not exist
INSERT INTO public.skill_weights (type, weight) VALUES
('certificate_A', 50), -- High trust certs (NPTEL, Coursera Verified)
('certificate_B', 30), -- Medium trust
('certificate_C', 10), -- Low trust
('project', 20),      
('assessment', 15),    
('event', 5)
ON CONFLICT (type) DO NOTHING;

-- 3. The Calculator Function (The Brain)
CREATE OR REPLACE FUNCTION calculate_student_skill_score(p_student_id UUID) 
RETURNS INTEGER AS $$
DECLARE
    v_score INTEGER := 0;
    v_cert_a_score INTEGER;
    v_cert_b_score INTEGER;
    v_cert_c_score INTEGER;
    v_project_score INTEGER;
    v_assessment_score INTEGER;
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
    
    -- 2. Projects Score (From Posts of type 'project' or 'achievement' that link to project)
    -- Simplified: Counting 'project' type posts for now
    SELECT COALESCE(COUNT(*), 0) * (SELECT weight FROM public.skill_weights WHERE type='project')
    INTO v_project_score
    FROM public.posts
    WHERE author_id = p_student_id AND reference_type = 'project';

    -- 3. Events Attended (From Activity Logs or Event Registrations)
    -- Assuming we log 'event_attended' in student_activity_logs or connection to events table
    -- For now, using activity logs count of 'event_attended'
    SELECT COALESCE(COUNT(*), 0) * (SELECT weight FROM public.skill_weights WHERE type='event')
    INTO v_event_score
    FROM public.student_activity_logs
    WHERE student_id = p_student_id AND activity_type = 'event_attended';

    -- Total Calculation
    v_score := v_cert_a_score + v_cert_b_score + COALESCE(v_cert_c_score, 0) + v_project_score + v_assessment_score + v_event_score;
    
    -- Cap at 100 or keep it open? Let's cap at 100 for percentage view, or 1000 for raw score. 
    -- Requirement says "Score out of 100".
    IF v_score > 100 THEN
        v_score := 100;
    END IF;

    RETURN v_score;
END;
$$ LANGUAGE plpgsql;


-- 4. Trigger to Update Stats
CREATE OR REPLACE FUNCTION update_student_stats_trigger() RETURNS TRIGGER AS $$
DECLARE
    v_student_id UUID;
    v_new_score INTEGER;
BEGIN
    -- Determine student_id based on table
    IF (TG_TABLE_NAME = 'student_certifications') THEN
        v_student_id := NEW.student_id;
    ELSIF (TG_TABLE_NAME = 'posts') THEN
        v_student_id := NEW.author_id;
    ELSIF (TG_TABLE_NAME = 'student_activity_logs') THEN
        v_student_id := NEW.student_id;
    END IF;

    -- Calculate New Score
    v_new_score := calculate_student_skill_score(v_student_id);

    -- Upsert Stats
    INSERT INTO public.student_stats (student_id, skill_score, last_updated)
    VALUES (v_student_id, v_new_score, now())
    ON CONFLICT (student_id) 
    DO UPDATE SET 
        skill_score = EXCLUDED.skill_score,
        last_updated = now();
        
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Attach Triggers
DROP TRIGGER IF EXISTS trg_update_stats_certs ON public.student_certifications;
CREATE TRIGGER trg_update_stats_certs
AFTER INSERT OR UPDATE OR DELETE ON public.student_certifications
FOR EACH ROW EXECUTE FUNCTION update_student_stats_trigger();

DROP TRIGGER IF EXISTS trg_update_stats_posts ON public.posts;
CREATE TRIGGER trg_update_stats_posts
AFTER INSERT OR UPDATE OR DELETE ON public.posts
FOR EACH ROW EXECUTE FUNCTION update_student_stats_trigger();

-- RLS
ALTER TABLE public.student_stats ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Everyone view stats" ON public.student_stats;
CREATE POLICY "Everyone view stats" ON public.student_stats FOR SELECT USING (true);

-- INIT: Populate for existing users
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT id FROM auth.users LOOP
        PERFORM calculate_student_skill_score(r.id);
        -- Manually insert/update initial stats
        INSERT INTO public.student_stats (student_id, skill_score)
        VALUES (r.id, calculate_student_skill_score(r.id))
        ON CONFLICT (student_id) DO UPDATE SET skill_score = EXCLUDED.skill_score;
    END LOOP;
END $$;

-- 5. Helper Function for Skill Score Breakdown
CREATE OR REPLACE FUNCTION get_skill_score_breakdown(p_student_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_cert_a_score INTEGER;
    v_cert_b_score INTEGER;
    v_project_score INTEGER;
    v_assessment_score INTEGER;
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

    -- Assessments (Placeholder)
    v_assessment_score := 0;

    v_total_score := v_cert_a_score + v_cert_b_score + v_project_score + v_assessment_score + v_event_score;
    IF v_total_score > 100 THEN v_total_score := 100; END IF;

    RETURN jsonb_build_object(
        'total_score', v_total_score,
        'breakdown', jsonb_build_array(
            jsonb_build_object('label', 'Verified Certificates (Top Tier)', 'score', v_cert_a_score, 'color', '0xFF4CAF50'),
            jsonb_build_object('label', 'Standard Certificates', 'score', v_cert_b_score, 'color', '0xFF8BC34A'),
            jsonb_build_object('label', 'Projects', 'score', v_project_score, 'color', '0xFF2196F3'),
            jsonb_build_object('label', 'Assessments', 'score', v_assessment_score, 'color', '0xFFFF9800'),
            jsonb_build_object('label', 'Events & Participation', 'score', v_event_score, 'color', '0xFF9C27B0')
        ),
        'tips', jsonb_build_array(
            'Complete assessments to boost your score by 15 points per test.',
            'Get your projects verified by mentors to increase project weightage.',
            'Attend college hackathons (Category A events) for maximum points.'
        )
    );
END;
$$ LANGUAGE plpgsql;
