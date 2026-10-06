-- FIX RLS ERROR (42501) & JSON ERROR (22P02)
-- Run this in Supabase SQL Editor

-- Create a secure function to create organizations without requiring an active session
CREATE OR REPLACE FUNCTION public.create_new_organization(
  p_name text,
  p_short_code text,
  p_type text,
  p_website text,
  p_city text,
  p_state text,
  p_country text,
  p_config jsonb,
  p_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id uuid;
BEGIN
  -- Insert the organization
  INSERT INTO public.organizations (
    name, short_code, type, website, 
    address_city, address_state, address_country, 
    config, status, created_by
  )
  VALUES (
    p_name, p_short_code, p_type, p_website,
    p_city, p_state, p_country,
    p_config, 'pending_approval', p_user_id
  )
  RETURNING id INTO v_org_id; -- ONLY capture the ID

  -- Return the ID as a JSON object
  RETURN jsonb_build_object('id', v_org_id);
END;
$$;

-- Grant permissions again just in case
GRANT EXECUTE ON FUNCTION public.create_new_organization TO anon;
GRANT EXECUTE ON FUNCTION public.create_new_organization TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_new_organization TO service_role;
