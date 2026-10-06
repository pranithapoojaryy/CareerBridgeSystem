-- Migration to create get_college_dashboard_stats_v2 RPC
-- Returns counts for students, events, and program distribution for the pie chart.

CREATE OR REPLACE FUNCTION get_college_dashboard_stats_v2(p_org_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_students INT;
    v_active_students INT;
    v_active_events INT;
    v_program_split JSONB;
BEGIN
    -- 1. Total Students
    SELECT count(*) INTO v_total_students
    FROM public.student_profiles sp
    JOIN public.profiles p ON p.id = sp.id
    WHERE p.organization_id = p_org_id;

    -- 2. Active Students
    v_active_students := v_total_students; 

    -- 3. Active Events
    SELECT count(*) INTO v_active_events
    FROM public.events
    WHERE college_id = p_org_id 
    AND (status = 'ongoing' OR start_date >= CURRENT_DATE);

    -- 4. Program Split (For Pie Chart) - Prioritize Department if Program is null
    SELECT jsonb_agg(t) INTO v_program_split
    FROM (
        SELECT 
            COALESCE(cp.name, cd.name, 'Unknown Program') as name,
            count(*) as value
        FROM public.student_profiles sp
        JOIN public.profiles p ON p.id = sp.id
        LEFT JOIN public.college_programs cp ON cp.id = sp.program_id
        LEFT JOIN public.college_departments cd ON cd.id = sp.department_id
        WHERE p.organization_id = p_org_id
        GROUP BY 1
    ) t;

    RETURN jsonb_build_object(
        'total_students', v_total_students,
        'active_students', v_active_students,
        'active_events', v_active_events,
        'placement_rate', 0,
        'program_split', COALESCE(v_program_split, '[]'::jsonb)
    );
END;
$$;

