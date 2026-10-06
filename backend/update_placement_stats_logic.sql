-- Fix for Placement Stats Logic
-- Update get_public_stats, get_college_dashboard_stats_v2, and add student placement trigger.

-- 1. Update Landing Page Stats (get_public_stats)
CREATE OR REPLACE FUNCTION get_public_stats()
RETURNS TABLE (
    total_students BIGINT,
    total_colleges BIGINT,
    total_recruiters BIGINT,
    total_placements BIGINT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM profiles WHERE role = 'student') as total_students,
        (SELECT COUNT(*) FROM organizations WHERE type = 'Affiliated') as total_colleges,
        (SELECT COUNT(*) FROM profiles WHERE role = 'recruiter') as total_recruiters,
        -- Placements: Count applications with status 'selected', 'hired', or 'placed'
        -- Treating 'selected' as the key status for placement
        (SELECT COUNT(*) FROM job_applications WHERE status IN ('hired', 'placed', 'selected')) as total_placements;
END;
$$;

-- Grant execute to anon (public)
GRANT EXECUTE ON FUNCTION get_public_stats() TO anon, authenticated;


-- 2. Update College Dashboard Stats (get_college_dashboard_stats_v2)
CREATE OR REPLACE FUNCTION get_college_dashboard_stats_v2(org_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_students INT;
    v_active_students INT;
    v_active_events INT;
    v_program_split JSONB;
    v_placed_students INT;
    v_placement_rate INT;
BEGIN
    -- 1. Total Students
    SELECT count(*) INTO v_total_students
    FROM public.student_profiles sp
    JOIN public.profiles p ON p.id = sp.id
    WHERE p.organization_id = org_id;

    -- 2. Active Students (Placeholder logic for now)
    v_active_students := v_total_students; 

    -- 3. Active Events
    SELECT count(*) INTO v_active_events
    FROM public.events
    WHERE college_id = org_id 
    AND (start_date >= CURRENT_DATE);

    -- 4. Calculate Placement Rate
    -- Count unique students from this college who have a 'selected' application
    SELECT COUNT(DISTINCT ja.student_id) INTO v_placed_students
    FROM job_applications ja
    JOIN profiles p ON p.id = ja.student_id
    WHERE p.organization_id = org_id
    AND ja.status IN ('hired', 'placed', 'selected');

    IF v_total_students > 0 THEN
        v_placement_rate := (v_placed_students::FLOAT / v_total_students::FLOAT * 100)::INT;
    ELSE
        v_placement_rate := 0;
    END IF;

    -- 5. Program Split
    SELECT jsonb_agg(t) INTO v_program_split
    FROM (
        SELECT 
            COALESCE(cp.name, 'Unknown Program') as name,
            count(*) as value
        FROM public.student_profiles sp
        JOIN public.profiles p ON p.id = sp.id
        LEFT JOIN public.college_programs cp ON cp.id = sp.program_id
        WHERE p.organization_id = org_id
        GROUP BY cp.name
    ) t;

    RETURN jsonb_build_object(
        'total_students', v_total_students,
        'active_students', v_active_students,
        'active_events', v_active_events,
        'placement_rate', v_placement_rate,
        'program_split', v_program_split
    );
END;
$$;


-- 3. Trigger to Update Student Profile Placement Status
CREATE OR REPLACE FUNCTION update_student_placement_status()
RETURNS TRIGGER AS $$
BEGIN
    -- If status changed to 'selected', mark student as placed
    IF NEW.status = 'selected' AND (OLD.status IS NULL OR OLD.status != 'selected') THEN
        UPDATE student_profiles
        SET 
            placement_status = 'placed',
            -- We could also capture company name/package here if we joined jobs table, 
            -- but let's keep it simple for now or do a separate update if needed.
            placement_date = NOW()
        WHERE id = NEW.student_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS trigger_update_student_placement ON job_applications;
CREATE TRIGGER trigger_update_student_placement
AFTER UPDATE OF status ON job_applications
FOR EACH ROW
EXECUTE FUNCTION update_student_placement_status();

-- Ensure insert also triggers it (e.g. direct insert as selected)
DROP TRIGGER IF EXISTS trigger_insert_student_placement ON job_applications;
CREATE TRIGGER trigger_insert_student_placement
AFTER INSERT ON job_applications
FOR EACH ROW
EXECUTE FUNCTION update_student_placement_status();
