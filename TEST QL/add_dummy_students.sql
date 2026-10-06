-- ADD DUMMY STUDENTS
-- The "Total Students" count is 0 because YOU are a "College Admin", not a "Student".
-- This script adds fake students so you can see data in the dashboard.

DO $$
DECLARE
    active_org_id UUID := 'eb302e28-12cf-4737-87f6-f69bff28f865';
    course_id UUID;
    student1_id UUID := gen_random_uuid();
    student2_id UUID := gen_random_uuid();
BEGIN
    -- Get the course ID (CareerBridge)
    SELECT id INTO course_id FROM learning_courses WHERE provider_id = active_org_id LIMIT 1;

    -- 1. Create Dummy Student 1 (Rahul)
    INSERT INTO auth.users (id, email) VALUES (student1_id, 'rahul.demo@test.com') ON CONFLICT DO NOTHING;
    INSERT INTO public.profiles (id, email, role, full_name, organization_id, profile_completion)
    VALUES (
        student1_id,
        'rahul.demo@test.com',
        'student',
        'Rahul Sharma',
        active_org_id,
        80
    ) ON CONFLICT (id) DO NOTHING;

    -- 2. Create Dummy Student 2 (Priya)
    INSERT INTO auth.users (id, email) VALUES (student2_id, 'priya.demo@test.com') ON CONFLICT DO NOTHING;
    INSERT INTO public.profiles (id, email, role, full_name, organization_id, profile_completion)
    VALUES (
        student2_id,
        'priya.demo@test.com',
        'student',
        'Priya Patel',
        active_org_id,
        95
    ) ON CONFLICT (id) DO NOTHING;

    -- 3. Enroll them in the course
    IF course_id IS NOT NULL THEN
        INSERT INTO student_course_enrollments (student_id, course_id) VALUES
        (student1_id, course_id),
        (student2_id, course_id)
        ON CONFLICT DO NOTHING;
        
        -- 4. Add some activity data (so "Active Students" count goes up)
        -- Rahul watched a lecture just now
        INSERT INTO student_lecture_progress (student_id, lecture_id, last_accessed_at)
        SELECT student1_id, id, NOW() 
        FROM learning_course_lectures 
        WHERE course_id = course_id 
        LIMIT 1
        ON CONFLICT DO NOTHING;
        
        -- Priya watched one yesterday
        INSERT INTO student_lecture_progress (student_id, lecture_id, last_accessed_at)
        SELECT student2_id, id, NOW() - INTERVAL '1 day'
        FROM learning_course_lectures 
        WHERE course_id = course_id 
        LIMIT 1
        ON CONFLICT DO NOTHING;
    END IF;

END $$;

-- Verify
SELECT count(*) as total_students FROM profiles WHERE organization_id = 'eb302e28-12cf-4737-87f6-f69bff28f865' AND role = 'student';
