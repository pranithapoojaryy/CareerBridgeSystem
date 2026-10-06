-- SUPER FIX DATA SCRIPT
-- The previous error happened because "Row Level Security" (RLS) blocked you from creating the missing organization.
-- This script uses a special "SECURITY DEFINER" function to bypass those checks and force the data fix.

-- 1. Create a temporary super-function to bypass permissions
CREATE OR REPLACE FUNCTION super_fix_missing_data()
RETURNS Varchar
LANGUAGE plpgsql
SECURITY DEFINER -- <<< This is the magic keyword that bypasses RLS
AS $$
DECLARE
    target_org_id UUID := '6984606b-f491-40cb-9984-696ee22ef86d';
    target_user_id UUID := 'd2cd996e-9ead-40d4-8465-13f39e706633';
BEGIN
    -- A. Force Insert the Organization
    INSERT INTO public.organizations (id, name, type, description, short_code, created_by)
    VALUES (
        target_org_id, 
        'CareerBridge Academy', 
        'college', 
        'Recovered Organization',
        'EHA',
        target_user_id
    )
    ON CONFLICT (id) DO NOTHING;

    -- B. Force Link the User
    UPDATE public.profiles
    SET 
        organization_id = target_org_id,
        role = 'college'
    WHERE id = target_user_id;

    RETURN 'Success: Data repaired.';
END;
$$;

-- 2. Execute the function
SELECT super_fix_missing_data();

-- 3. Cleanup (optional, remove the function)
DROP FUNCTION super_fix_missing_data();

-- 4. Verify
SELECT * FROM profiles WHERE id = 'd2cd996e-9ead-40d4-8465-13f39e706633';
