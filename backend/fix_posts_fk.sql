-- Fix Foreign Key for Posts to allow frontend joins with public.profiles

DO $$
BEGIN
    -- 1. Drop existing FK constraint if it exists (name might vary, so we try standard names or rely on internal logic)
    -- Typically Supabase/Postgres names it "posts_author_id_fkey"
    IF EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'posts_author_id_fkey' 
        AND table_name = 'posts'
    ) THEN
        ALTER TABLE public.posts DROP CONSTRAINT posts_author_id_fkey;
    END IF;

    -- 2. Add new FK constraint pointing to public.profiles
    -- ensuring that we only delete the post if the PROFILE is deleted (which cascades from auth.users anyway)
    ALTER TABLE public.posts
    ADD CONSTRAINT posts_author_id_fkey
    FOREIGN KEY (author_id)
    REFERENCES public.profiles(id)
    ON DELETE CASCADE;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error changing constraint: %', SQLERRM;
END $$;
