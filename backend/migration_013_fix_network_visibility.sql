-- =====================================================
-- MIGRATION 013: FIX NETWORK VISIBILITY & CHAT FEATURES
-- =====================================================

-- 1. Fix Project Visibility
-- Allow all authenticated users to view ANY student project (public portfolio concept)
-- Or we could restrict to connections, but open portfolio is better for networking.
DROP POLICY IF EXISTS "Authenticated users can view projects" ON public.student_projects;
CREATE POLICY "Authenticated users can view projects" ON public.student_projects
    FOR SELECT USING (auth.role() = 'authenticated');

-- 2. Fix Certificate Visibility
-- Allow all authenticated users to view ANY student certificate
DROP POLICY IF EXISTS "Authenticated users can view certifications" ON public.student_certifications;
CREATE POLICY "Authenticated users can view certifications" ON public.student_certifications
    FOR SELECT USING (auth.role() = 'authenticated');

-- 3. Clear Chat History RPC
-- Function to delete messages between two users (for both) OR just hide?
-- Current request: "clear chat also". Simple implementation: Delete messages.
CREATE OR REPLACE FUNCTION clear_chat_history(target_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    DELETE FROM public.messages
    WHERE (sender_id = auth.uid() AND receiver_id = target_user_id)
       OR (sender_id = target_user_id AND receiver_id = auth.uid());
END;
$$;

SELECT 'Migration 013: Network visibility fixed and chat features added' as status;
