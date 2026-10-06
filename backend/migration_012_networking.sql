-- =====================================================
-- MIGRATION 012: NETWORKING AND MESSAGING
-- =====================================================

-- 0. Cleanup (To ensure clean creation if table exists with wrong schema)
DROP TABLE IF EXISTS public.connections CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;

-- 1. Create Connections Table
CREATE TABLE IF NOT EXISTS public.connections (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    requester_id UUID REFERENCES auth.users(id) NOT NULL,
    receiver_id UUID REFERENCES auth.users(id) NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    -- Prevent duplicate connection requests between same pair
    CONSTRAINT unique_connection_pair UNIQUE (requester_id, receiver_id),
    -- Prevent self-connection
    CONSTRAINT no_self_connection CHECK (requester_id != receiver_id)
);

-- 2. Create Messages Table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id UUID REFERENCES auth.users(id) NOT NULL,
    receiver_id UUID REFERENCES auth.users(id) NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    CONSTRAINT no_self_message CHECK (sender_id != receiver_id)
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_connections_requester ON public.connections(requester_id);
CREATE INDEX IF NOT EXISTS idx_connections_receiver ON public.connections(receiver_id);
CREATE INDEX IF NOT EXISTS idx_connections_status ON public.connections(status);

CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);

-- 4. RLS Policies

-- connections
ALTER TABLE public.connections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their connections" ON public.connections;
CREATE POLICY "Users can view their connections" ON public.connections
    FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can insert connection requests" ON public.connections;
CREATE POLICY "Users can insert connection requests" ON public.connections
    FOR INSERT WITH CHECK (auth.uid() = requester_id);

DROP POLICY IF EXISTS "Users can update their connections" ON public.connections;
CREATE POLICY "Users can update their connections" ON public.connections
    FOR UPDATE USING (auth.uid() = requester_id OR auth.uid() = receiver_id);

-- messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their messages" ON public.messages;
CREATE POLICY "Users can view their messages" ON public.messages
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
CREATE POLICY "Users can send messages" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- 5. Helper Functions (RPCs)

-- Function to check connection status between two users
CREATE OR REPLACE FUNCTION get_connection_status(target_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    status_text TEXT;
BEGIN
    SELECT status INTO status_text
    FROM public.connections
    WHERE (requester_id = auth.uid() AND receiver_id = target_user_id)
       OR (requester_id = target_user_id AND receiver_id = auth.uid());
       
    RETURN status_text;
END;
$$;

-- Function to fetch my connections with profile details
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
        p.avatar_url,
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

-- Function to fetch pending connection requests
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
        p.avatar_url,
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

-- Function to send connection request safely
CREATE OR REPLACE FUNCTION send_connection_request(target_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_id UUID;
BEGIN
    -- Check if self
    IF target_user_id = auth.uid() THEN
        RAISE EXCEPTION 'Cannot connect with yourself';
    END IF;

    -- Insert or ignore if exists (using ON CONFLICT check pattern not strictly needed if we just catch error, but distinct status is better)
    -- Simplest is to try insert. The Unique Constraint will fail if exists.
    -- But we want to handle re-sending if rejected? Maybe not for now.
    
    INSERT INTO public.connections (requester_id, receiver_id, status)
    VALUES (auth.uid(), target_user_id, 'pending')
    RETURNING id INTO new_id;
    
    RETURN new_id;
END;
$$;

SELECT 'Migration 012: Networking tables created successfully' as status;
