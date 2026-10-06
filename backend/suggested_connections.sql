-- Function to get suggested connections (friends of friends)
CREATE OR REPLACE FUNCTION get_suggested_connections(
  limit_count INT DEFAULT 10
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
AS $$
DECLARE
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();

  RETURN QUERY
  WITH my_connections AS (
    -- Get all accepted connections of the current user
    SELECT receiver_id AS friend_id FROM connections WHERE requester_id = current_user_id AND status = 'accepted'
    UNION
    SELECT requester_id AS friend_id FROM connections WHERE receiver_id = current_user_id AND status = 'accepted'
  ),
  suggested_pool AS (
    -- Find connections of my connections (2nd degree)
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
    -- Filter out myself, existing connections, and pending requests
    SELECT s.suggested_id, COUNT(*) as mutuals
    FROM suggested_pool s
    WHERE s.suggested_id != current_user_id
    AND s.suggested_id NOT IN (SELECT friend_id FROM my_connections) -- Not already connected
    AND s.suggested_id NOT IN (
      -- Exclude if there's a pending request sent by me or to me
      SELECT receiver_id FROM connections WHERE requester_id = current_user_id AND status = 'pending'
      UNION
      SELECT requester_id FROM connections WHERE receiver_id = current_user_id AND status = 'pending'
    )
    GROUP BY s.suggested_id
  )
  SELECT
    p.id as user_id,
    p.full_name,
    p.profile_photo_url as avatar_url,
    p.role,
    p.headline,
    fs.mutuals
  FROM filtered_suggestions fs
  JOIN profiles p ON p.id = fs.suggested_id
  ORDER BY fs.mutuals DESC, p.created_at DESC
  LIMIT limit_count;
END;
$$;
