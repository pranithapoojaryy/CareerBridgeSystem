-- =====================================================
-- MIGRATION 015: FIX AVATAR URL IN NETWORKING RPCs
-- =====================================================

-- 1. Fix get_my_connections
-- Was using p.avatar_url, should use p.profile_photo_url as primary source
CREATE OR REPLACE FUNCTION get_my_connections()
RETURNS TABLE (
    connection_id UUID,
    user_id UUID,
    full_name TEXT,
    avatar_url TEXT,
    role TEXT,
    college_name TEXT,
    status TEXT,
    initiated_by_me BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as connection_id,
        CASE 
            WHEN c.requester_id = auth.uid() THEN c.receiver_id 
            ELSE c.requester_id 
        END as user_id,
        p.full_name,
        COALESCE(p.profile_photo_url, p.avatar_url) as avatar_url, -- FIX: Prioritize profile_photo_url
        p.role,
        o.name as college_name,
        c.status,
        (c.requester_id = auth.uid()) as initiated_by_me
    FROM public.connections c
    JOIN public.profiles p ON p.id = (
        CASE 
            WHEN c.requester_id = auth.uid() THEN c.receiver_id 
            ELSE c.requester_id 
        END
    )
    LEFT JOIN public.organizations o ON p.organization_id = o.id
    WHERE (c.requester_id = auth.uid() OR c.receiver_id = auth.uid())
    AND c.status = 'accepted';
END;
$$;

-- 2. Fix get_pending_requests
-- Was using p.avatar_url, should use p.profile_photo_url
CREATE OR REPLACE FUNCTION get_pending_requests()
RETURNS TABLE (
    connection_id UUID,
    user_id UUID,
    full_name TEXT,
    avatar_url TEXT,
    role TEXT,
    college_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as connection_id,
        c.requester_id as user_id,
        p.full_name,
        COALESCE(p.profile_photo_url, p.avatar_url) as avatar_url, -- FIX: Prioritize profile_photo_url
        p.role,
        o.name as college_name,
        c.created_at
    FROM public.connections c
    JOIN public.profiles p ON p.id = c.requester_id
    LEFT JOIN public.organizations o ON p.organization_id = o.id
    WHERE c.receiver_id = auth.uid()
    AND c.status = 'pending';
END;
$$;

SELECT 'Migration 015: Networking avatar URLs fixed' as status;
