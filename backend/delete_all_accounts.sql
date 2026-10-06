-- =====================================================
-- DELETE ALL ACCOUNTS (COMPLETELY SAFE & UNRESTRICTED)
-- =====================================================
-- Temporarily disables session replication role (triggers & FK constraints)
-- so all account tables and auth users can be wiped cleanly.

-- 1. Temporarily disable foreign key constraints and triggers for this session
SET session_replication_role = 'replica';

-- 2. Delete all records from existing public tables
DO $$
DECLARE
    t text;
    target_tables text[] := ARRAY[
        'post_likes', 'post_comments', 'posts', 'messages', 'conversations', 
        'connections', 'student_stats', 'student_activity_logs', 
        'student_certifications', 'student_skills', 'student_skill_validations', 
        'resumes', 'resume_feedback', 'aptitude_attempts', 'assessment_attempts', 
        'test_assignments', 'event_registrations', 'job_applications', 
        'mock_interviews', 'announcements', 'events', 'assessments', 
        'aptitude_tests', 'jobs', 'hiring_pipelines', 'recruiters', 
        'companies', 'college_students', 'college_admins', 'colleges', 
        'student_profiles', 'profiles'
    ];
BEGIN
    FOREACH t IN ARRAY target_tables
    LOOP
        IF EXISTS (
            SELECT 1 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
              AND table_name = t
        ) THEN
            EXECUTE format('DELETE FROM public.%I', t);
            RAISE NOTICE 'Wiped table public.%', t;
        END IF;
    END LOOP;
END $$;

-- 3. Delete all auth users from Supabase Auth
DELETE FROM auth.users;

-- 4. Re-enable foreign key constraints and triggers
SET session_replication_role = 'origin';

-- Verification output
SELECT COUNT(*) AS remaining_auth_users FROM auth.users;
SELECT COUNT(*) AS remaining_profiles FROM public.profiles;
