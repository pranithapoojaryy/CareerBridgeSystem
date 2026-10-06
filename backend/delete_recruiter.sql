-- =====================================================
-- DELETE RECRUITER USER
-- =====================================================
-- Recruiters are simpler - no student_stats trigger issues

-- STEP 1: First, get the recruiter's email and ID
-- Replace with the actual recruiter email you want to delete
SELECT id, email, role FROM auth.users WHERE email = 'recruiter@example.com';

-- STEP 2: Once you have the ID, delete from dependent tables
-- Replace 'RECRUITER_ID_HERE' with the actual UUID from step 1

-- Delete from recruiters table
DELETE FROM public.recruiters WHERE id = 'RECRUITER_ID_HERE';

-- Delete from test_assignments (if they created any)
DELETE FROM public.test_assignments WHERE assigned_by = 'RECRUITER_ID_HERE';

-- Delete from announcements (if they created any)
DELETE FROM public.announcements WHERE created_by = 'RECRUITER_ID_HERE';

-- Delete from events (if they created any)
DELETE FROM public.events WHERE created_by = 'RECRUITER_ID_HERE';

-- Delete from assessments (if they created any)
DELETE FROM public.assessments WHERE created_by = 'RECRUITER_ID_HERE';

-- Delete from aptitude_tests (if they created any)
DELETE FROM public.aptitude_tests WHERE created_by = 'RECRUITER_ID_HERE';

-- Delete from connections
DELETE FROM public.connections 
WHERE requester_id = 'RECRUITER_ID_HERE' OR receiver_id = 'RECRUITER_ID_HERE';

-- Delete from messages
DELETE FROM public.messages 
WHERE sender_id = 'RECRUITER_ID_HERE' OR receiver_id = 'RECRUITER_ID_HERE';

-- Delete from profiles
DELETE FROM public.profiles WHERE id = 'RECRUITER_ID_HERE';

-- Delete from auth.users (final step)
DELETE FROM auth.users WHERE id = 'RECRUITER_ID_HERE';

-- =====================================================
-- QUICK VERSION: If you just want to delete quickly
-- =====================================================
-- Just provide the email below and run this:

/*
DO $$
DECLARE
    v_user_id UUID;
    v_email TEXT := 'recruiter@example.com'; -- CHANGE THIS
BEGIN
    SELECT id INTO v_user_id FROM auth.users WHERE email = v_email;
    
    IF v_user_id IS NOT NULL THEN
        DELETE FROM public.recruiters WHERE id = v_user_id;
        DELETE FROM public.test_assignments WHERE assigned_by = v_user_id;
        DELETE FROM public.announcements WHERE created_by = v_user_id;
        DELETE FROM public.events WHERE created_by = v_user_id;
        DELETE FROM public.assessments WHERE created_by = v_user_id;
        DELETE FROM public.aptitude_tests WHERE created_by = v_user_id;
        DELETE FROM public.connections WHERE requester_id = v_user_id OR receiver_id = v_user_id;
        DELETE FROM public.messages WHERE sender_id = v_user_id OR receiver_id = v_user_id;
        DELETE FROM public.profiles WHERE id = v_user_id;
        DELETE FROM auth.users WHERE id = v_user_id;
        
        RAISE NOTICE 'Recruiter % deleted successfully!', v_email;
    ELSE
        RAISE NOTICE 'Recruiter % not found', v_email;
    END IF;
END $$;
*/
