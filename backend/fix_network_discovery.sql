-- ================================================================
-- FIX: Recruiter Network - Cannot see Students, Colleges, Recruiters
-- ================================================================
-- Problems:
-- 1. get_suggested_connections only shows 2nd-degree connections
--    → new recruiter with 0 connections sees nothing
-- 2. search_profiles uses profile_photo_url (may not exist) instead of avatar_url
-- 3. No way to browse profiles by role without searching
--
-- Run this in Supabase SQL Editor.
-- ================================================================

-- Fix 1: Update get_suggested_connections to also show random users
-- when there are no 2nd-degree connections (fallback discovery)
CREATE OR REPLACE FUNCTION get_suggested_connections(
  limit_count INT DEFAULT 15
)
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT,
  headline TEXT,
  mutual_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id UUID;
  suggestion_count INT;
BEGIN
  current_user_id := auth.uid();

  -- First try 2nd-degree connections
  RETURN QUERY
  WITH my_connections AS (
    SELECT receiver_id AS friend_id FROM connections WHERE requester_id = current_user_id AND status = 'accepted'
    UNION
    SELECT requester_id AS friend_id FROM connections WHERE receiver_id = current_user_id AND status = 'accepted'
  ),
  suggested_pool AS (
    SELECT
      CASE
        WHEN c.requester_id = mc.friend_id THEN c.receiver_id
        ELSE c.requester_id
      END AS suggested_id
    FROM connections c
    JOIN my_connections mc ON (c.requester_id = mc.friend_id OR c.receiver_id = mc.friend_id)
    WHERE c.status = 'accepted'
  ),
  filtered_suggestions AS (
    SELECT s.suggested_id, COUNT(*) as mutuals
    FROM suggested_pool s
    WHERE s.suggested_id != current_user_id
    AND s.suggested_id NOT IN (SELECT friend_id FROM my_connections)
    AND s.suggested_id NOT IN (
      SELECT receiver_id FROM connections WHERE requester_id = current_user_id AND status IN ('pending','accepted')
      UNION
      SELECT requester_id FROM connections WHERE receiver_id = current_user_id AND status IN ('pending','accepted')
    )
    GROUP BY s.suggested_id
  )
  SELECT
    p.id as user_id,
    p.full_name,
    COALESCE(p.profile_photo_url, p.avatar_url) as avatar_url,
    p.role,
    p.headline,
    fs.mutuals
  FROM filtered_suggestions fs
  JOIN profiles p ON p.id = fs.suggested_id
  ORDER BY fs.mutuals DESC, p.created_at DESC
  LIMIT limit_count;

  -- Check how many we returned
  GET DIAGNOSTICS suggestion_count = ROW_COUNT;

  -- If we got fewer than limit, fill with random profiles (discovery fallback)
  IF suggestion_count < limit_count THEN
    RETURN QUERY
    SELECT
      p.id as user_id,
      p.full_name,
      COALESCE(p.profile_photo_url, p.avatar_url) as avatar_url,
      p.role,
      p.headline,
      0::BIGINT as mutual_count
    FROM profiles p
    WHERE p.id != current_user_id
    AND p.role IN ('student', 'recruiter', 'college', 'college_admin')
    AND p.full_name IS NOT NULL
    AND p.id NOT IN (
      -- Exclude already connected or pending
      SELECT receiver_id FROM connections WHERE requester_id = current_user_id AND status IN ('pending','accepted')
      UNION
      SELECT requester_id FROM connections WHERE receiver_id = current_user_id AND status IN ('pending','accepted')
    )
    ORDER BY p.created_at DESC
    LIMIT (limit_count - suggestion_count);
  END IF;
END;
$$;

-- Fix 2: Update search_profiles to use COALESCE for avatar_url
CREATE OR REPLACE FUNCTION search_profiles(
  search_query TEXT,
  limit_count INT DEFAULT 30
)
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT,
  college_name TEXT,
  connection_status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();

  RETURN QUERY
  SELECT
    p.id as user_id,
    p.full_name,
    COALESCE(p.profile_photo_url, p.avatar_url) as avatar_url,
    p.role,
    o.name as college_name,
    CASE
      WHEN EXISTS (
        SELECT 1 FROM connections c
        WHERE (c.requester_id = current_user_id AND c.receiver_id = p.id)
          AND c.status = 'accepted'
      ) OR EXISTS (
        SELECT 1 FROM connections c
        WHERE (c.receiver_id = current_user_id AND c.requester_id = p.id)
          AND c.status = 'accepted'
      ) THEN 'connected'

      WHEN EXISTS (
        SELECT 1 FROM connections c
        WHERE c.requester_id = current_user_id AND c.receiver_id = p.id
          AND c.status = 'pending'
      ) THEN 'pending'

      WHEN EXISTS (
        SELECT 1 FROM connections c
        WHERE c.receiver_id = current_user_id AND c.requester_id = p.id
          AND c.status = 'pending'
      ) THEN 'request_received'

      ELSE 'none'
    END as connection_status
  FROM profiles p
  LEFT JOIN organizations o ON p.organization_id = o.id
  WHERE
    p.id != current_user_id
    AND p.role IN ('student', 'recruiter', 'college', 'college_admin')
    AND (
      p.full_name ILIKE '%' || search_query || '%'
      OR p.email ILIKE '%' || search_query || '%'
      OR o.name ILIKE '%' || search_query || '%'
    )
  ORDER BY
    CASE p.role
      WHEN 'student' THEN 1
      WHEN 'recruiter' THEN 2
      WHEN 'college_admin' THEN 3
      WHEN 'college' THEN 4
      ELSE 5
    END,
    p.full_name
  LIMIT limit_count;
END;
$$;

-- Fix 3: New RPC to browse profiles by role (for the network discovery tab)
CREATE OR REPLACE FUNCTION get_browse_profiles(
  role_filter TEXT DEFAULT 'all',
  limit_count INT DEFAULT 30,
  offset_count INT DEFAULT 0
)
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT,
  college_name TEXT,
  headline TEXT,
  connection_status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();

  RETURN QUERY
  SELECT
    p.id as user_id,
    p.full_name,
    COALESCE(p.profile_photo_url, p.avatar_url) as avatar_url,
    p.role,
    o.name as college_name,
    p.headline,
    CASE
      WHEN EXISTS (
        SELECT 1 FROM connections c
        WHERE ((c.requester_id = current_user_id AND c.receiver_id = p.id)
            OR (c.receiver_id = current_user_id AND c.requester_id = p.id))
          AND c.status = 'accepted'
      ) THEN 'connected'
      WHEN EXISTS (
        SELECT 1 FROM connections c
        WHERE c.requester_id = current_user_id AND c.receiver_id = p.id
          AND c.status = 'pending'
      ) THEN 'pending'
      WHEN EXISTS (
        SELECT 1 FROM connections c
        WHERE c.receiver_id = current_user_id AND c.requester_id = p.id
          AND c.status = 'pending'
      ) THEN 'request_received'
      ELSE 'none'
    END as connection_status
  FROM profiles p
  LEFT JOIN organizations o ON p.organization_id = o.id
  WHERE
    p.id != current_user_id
    AND p.full_name IS NOT NULL
    AND (
      role_filter = 'all'
      OR (role_filter = 'student' AND p.role = 'student')
      OR (role_filter = 'recruiter' AND p.role = 'recruiter')
      OR (role_filter = 'college' AND p.role IN ('college', 'college_admin'))
    )
  ORDER BY p.created_at DESC
  LIMIT limit_count
  OFFSET offset_count;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_suggested_connections(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION search_profiles(TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_browse_profiles(TEXT, INT, INT) TO authenticated;

SELECT 'Network fix applied successfully' as status;
