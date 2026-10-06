-- =====================================================
-- PERMANENT FIX: Fix the buggy trigger function
-- =====================================================
-- The trigger is firing for ALL users, not just students
-- This fixes it to only fire for student role updates

CREATE OR REPLACE FUNCTION update_student_stats_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_student_id UUID;
    v_new_score INTEGER;
BEGIN
    -- Only process for UPDATE operations on profiles table
    IF TG_OP = 'UPDATE' AND TG_TABLE_NAME = 'profiles' THEN
        -- Only process if this is a student profile
        IF NEW.role = 'student' THEN
            v_student_id := NEW.id;
            
            -- Check if student_id is not null before inserting
            IF v_student_id IS NOT NULL THEN
                -- Calculate skill score (example logic)
                v_new_score := COALESCE(NEW.profile_completion, 0);
                
                INSERT INTO public.student_stats (student_id, skill_score, last_updated)
                VALUES (v_student_id, v_new_score, now())
                ON CONFLICT (student_id) 
                DO UPDATE SET 
                    skill_score = EXCLUDED.skill_score,
                    last_updated = now();
            END IF;
        END IF;
    END IF;
    
    -- For DELETE operations, just return OLD
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Now you can delete ANY user (student or recruiter)
-- =====================================================

-- Delete a user by email (works for any role now)
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT := 'neelanjan.mca.2024@pim.ac.in'; -- CHANGE THIS
BEGIN
    SELECT id INTO v_user_id FROM auth.users WHERE email = v_email;
    
    IF v_user_id IS NOT NULL THEN
        -- Delete from all possible tables
        DELETE FROM public.student_stats WHERE student_id = v_user_id;
        DELETE FROM public.student_activity_logs WHERE student_id = v_user_id;
        DELETE FROM public.student_certifications WHERE student_id = v_user_id;
        DELETE FROM public.student_skills WHERE student_id = v_user_id;
        DELETE FROM public.student_skill_validations WHERE student_id = v_user_id;
        DELETE FROM public.aptitude_attempts WHERE student_id = v_user_id;
        DELETE FROM public.assessment_attempts WHERE student_id = v_user_id;
        DELETE FROM public.event_registrations WHERE student_id = v_user_id;
        DELETE FROM public.resumes WHERE user_id = v_user_id;
        DELETE FROM public.recruiters WHERE id = v_user_id;
        DELETE FROM public.companies WHERE created_by = v_user_id;
        DELETE FROM public.test_assignments WHERE assigned_by = v_user_id OR assigned_to_user = v_user_id;
        DELETE FROM public.announcements WHERE created_by = v_user_id;
        DELETE FROM public.events WHERE created_by = v_user_id;
        DELETE FROM public.assessments WHERE created_by = v_user_id;
        DELETE FROM public.aptitude_tests WHERE created_by = v_user_id;
        DELETE FROM public.connections WHERE requester_id = v_user_id OR receiver_id = v_user_id;
        DELETE FROM public.messages WHERE sender_id = v_user_id OR receiver_id = v_user_id;
        DELETE FROM public.post_likes WHERE user_id = v_user_id;
        DELETE FROM public.post_comments WHERE user_id = v_user_id;
        DELETE FROM public.posts WHERE author_id = v_user_id;
        DELETE FROM public.student_profiles WHERE id = v_user_id;
        DELETE FROM public.profiles WHERE id = v_user_id;
        DELETE FROM auth.users WHERE id = v_user_id;
        
        RAISE NOTICE 'User % deleted successfully!', v_email;
    ELSE
        RAISE NOTICE 'User % not found', v_email;
    END IF;
END $$;
