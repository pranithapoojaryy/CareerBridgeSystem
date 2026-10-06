-- FORCE MIGRATE DATA SCRIPT
-- This script moves the "CareerBridge" course to your Active Organization (eb30...)
-- It uses specific IDs to avoid "null" errors in the SQL Editor.

CREATE OR REPLACE FUNCTION force_migrate_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    -- Your Active Org (from Debug Banner)
    active_org_id UUID := 'eb302e28-12cf-4737-87f6-f69bff28f865';
    -- Your User ID (Sushanth)
    my_user_id UUID := 'd2cd996e-9ead-40d4-8465-13f39e706633';
    -- The "ghost" Org that currently owns the data
    old_org_id UUID := '6984606b-f491-40cb-9984-696ee22ef86d';
BEGIN
    -- 1. Create your Active Organization (if not exists)
    INSERT INTO public.organizations (id, name, type, description, short_code, created_by)
    VALUES (
        active_org_id, 
        'My College', 
        'college', 
        'Active User Organization',
        'MYCOL',
        my_user_id
    )
    ON CONFLICT (id) DO NOTHING;

    -- 2. Move the Courses to your Active Organization
    UPDATE learning_courses
    SET provider_id = active_org_id
    WHERE provider_id = old_org_id
       OR title = 'CareerBridge';

    -- 3. Ensure your User Profile is linked to this Active Org
    UPDATE profiles
    SET organization_id = active_org_id
    WHERE id = my_user_id;

    -- 4. Ensure you are Enrolled
    INSERT INTO student_course_enrollments (student_id, course_id)
    SELECT my_user_id, id FROM learning_courses WHERE provider_id = active_org_id LIMIT 1
    ON CONFLICT DO NOTHING;

    -- 5. Ensure you have Activity (for "Active Students" count)
    INSERT INTO student_lecture_progress (student_id, lecture_id, last_accessed_at)
    SELECT my_user_id, id, NOW() 
    FROM learning_course_lectures 
    LIMIT 1
    ON CONFLICT DO NOTHING;

END;
$$;

-- Run the migration
SELECT force_migrate_data();

-- Verification
SELECT title, provider_id FROM learning_courses;

-- Cleanup
DROP FUNCTION force_migrate_data();
