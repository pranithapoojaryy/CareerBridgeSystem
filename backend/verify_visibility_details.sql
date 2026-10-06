-- Check details that affect frontend visibility
SELECT 
    id, 
    assignment_type, 
    assigned_by_role, -- Frontend filters by 'recruiter' or 'college'
    deadline, -- Frontend filters expired
    start_date,
    created_at
FROM public.test_assignments
WHERE assignment_type = 'all_students';
