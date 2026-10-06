-- Fix Foreign Key for Post Comments to allow frontend joins with public.profiles

DO $$
BEGIN
    -- 1. Drop existing FK constraint if it exists
    -- Typically Supabase/Postgres names it "post_comments_user_id_fkey"
    IF EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'post_comments_user_id_fkey' 
        AND table_name = 'post_comments'
    ) THEN
        ALTER TABLE public.post_comments DROP CONSTRAINT post_comments_user_id_fkey;
    END IF;

    -- 2. Add new FK constraint pointing to public.profiles
    -- ensuring that we only delete the comment if the PROFILE is deleted (which cascades from auth.users anyway)
    ALTER TABLE public.post_comments
    ADD CONSTRAINT post_comments_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.profiles(id)
    ON DELETE CASCADE;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error changing constraint: %', SQLERRM;
END $$;
