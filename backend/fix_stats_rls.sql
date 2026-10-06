-- Fix: Allow triggers to update student_stats by using SECURITY DEFINER

-- 1. Redefine the trigger function with SECURITY DEFINER
-- This allows the function to bypass RLS on student_stats when called by a user
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
    -- We can call the calculation function here. 
    -- Note: If calculate_student_skill_score relies on RLS to filter data, 
    -- SECURITY DEFINER might expose more data if not careful, 
    -- but here we are just summing up counts for a specific student_id, so it's safe.
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Explicitly grant permissions if needed (though SECURITY DEFINER should handle it if owner has access)
GRANT ALL ON public.student_stats TO postgres;
GRANT ALL ON public.student_stats TO service_role;
GRANT SELECT ON public.student_stats TO authenticated; -- Keep RLS for users, only SELECT

-- 3. Ensure the Policy for SELECT still holds
DROP POLICY IF EXISTS "Everyone view stats" ON public.student_stats;
CREATE POLICY "Everyone view stats" ON public.student_stats FOR SELECT USING (true);
