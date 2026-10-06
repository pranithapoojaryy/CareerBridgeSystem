-- Function to get conversations (users you've messaged with)
CREATE OR REPLACE FUNCTION get_my_conversations()
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT,
  last_message TEXT,
  last_message_time TIMESTAMPTZ,
  is_last_message_mine BOOLEAN,
  unread_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();

  RETURN QUERY
  WITH recent_messages AS (
    SELECT 
      CASE 
        WHEN m.sender_id = current_user_id THEN m.receiver_id
        ELSE m.sender_id
      END as conversation_user_id,
      m.content as last_message,
      m.created_at as last_message_time,
      m.sender_id = current_user_id as is_mine,
      ROW_NUMBER() OVER (
        PARTITION BY 
          CASE 
            WHEN m.sender_id = current_user_id THEN m.receiver_id
            ELSE m.sender_id
          END
        ORDER BY m.created_at DESC
      ) as rn
    FROM messages m
    WHERE m.sender_id = current_user_id OR m.receiver_id = current_user_id
  ),
  unread_counts AS (
    SELECT 
      sender_id as from_user_id,
      COUNT(*) as unread_count
    FROM messages
    WHERE receiver_id = current_user_id 
      AND is_read = FALSE
    GROUP BY sender_id
  )
  SELECT 
    p.id as user_id,
    p.full_name,
    p.profile_photo_url as avatar_url,
    p.role,
    rm.last_message,
    rm.last_message_time,
    rm.is_mine as is_last_message_mine,
    COALESCE(uc.unread_count, 0) as unread_count
  FROM recent_messages rm
  JOIN profiles p ON p.id = rm.conversation_user_id
  LEFT JOIN unread_counts uc ON uc.from_user_id = p.id
  WHERE rm.rn = 1
  ORDER BY rm.last_message_time DESC;
END;
$$;
