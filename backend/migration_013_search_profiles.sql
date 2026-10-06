-- Function to search profiles
CREATE OR REPLACE FUNCTION search_profiles(
  search_query TEXT,
  limit_count INT DEFAULT 20
)
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT,
  college_name TEXT,
  connection_status TEXT -- 'none', 'pending', 'connected', 'request_received'
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();

  RETURN QUERY
  SELECT 
    p.id as user_id,
    p.full_name,
    p.profile_photo_url as avatar_url,
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
    p.id != current_user_id -- Exclude self
    AND (
      p.full_name ILIKE '%' || search_query || '%' 
      OR p.email ILIKE '%' || search_query || '%'
    )
  LIMIT limit_count;
END;
$$;
