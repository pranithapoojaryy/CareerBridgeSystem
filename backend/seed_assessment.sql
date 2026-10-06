-- Create a Real Assessment (Test + Assignment) for "Mock Tests" section users to see

DO $$
DECLARE
    module_id UUID;
    test_id UUID;
    admin_id UUID;
BEGIN
    -- 1. Get a Module (e.g. Technical Core)
    SELECT id INTO module_id FROM aptitude_modules WHERE name = 'Technical Aptitude' LIMIT 1;
    
    -- 2. Get an Admin User (just pick the first one from existing questions or users)
    -- Fallback: Use auth.uid() if running in context, but script runs as postgres usually.
    -- We'll just set it to NULL if not found, as constraints are usually loose for seeding.
    SELECT id INTO admin_id FROM auth.users LIMIT 1;

    -- 3. Create an Assessment Test (not practice)
    IF module_id IS NOT NULL THEN
        INSERT INTO aptitude_tests (
            module_id, 
            test_type, 
            title, 
            description, 
            difficulty, 
            duration_minutes, 
            total_questions, 
            is_active
        )
        VALUES (
            module_id,
            'assignment',
            'Full Stack Developer Assessment',
            'Comprehensive technical assessment covering frontend, backend, and database concepts.',
            'hard',
            60,
            20,
            true
        )
        RETURNING id INTO test_id;
        
        -- 4. Assign it to 'all_students' (so the current user sees it)
        INSERT INTO test_assignments (
            test_id,
            assigned_by,
            assigned_by_role,
            assignment_type,
            start_date,
            deadline,
            max_attempts,
            is_mandatory,
            weightage
        )
        VALUES (
            test_id,
            admin_id, -- Can be null
            'recruiter',
            'all_students',
            NOW(),
            NOW() + INTERVAL '7 days',
            1,
            true,
            20.0
        );
        
    END IF;
END $$;
