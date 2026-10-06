-- Seed a Welcome Post from "CareerBridge Team"
-- Since we don't have a dedicated system user, we will pick the first available user as the author 
-- (or you can replace 'auth.users' subquery with a specific UUID if you have one).

DO $$
DECLARE
    v_author_id UUID;
BEGIN
    -- 1. Select a candidate author (e.g., the first user created)
    SELECT id INTO v_author_id FROM auth.users ORDER BY created_at ASC LIMIT 1;

    IF v_author_id IS NOT NULL THEN
        -- 1b. Ensure this author has a profile in public.profiles to satisfy foreign key/UI constraints
        INSERT INTO public.profiles (id, full_name, role, avatar_url)
        VALUES (
            v_author_id, 
            'CareerBridge Team', 
            'admin', 
            'https://ui-avatars.com/api/?name=CAREERBRIDGE+Hire&background=0D8ABC&color=fff'
        )
        ON CONFLICT (id) DO NOTHING;

        -- 2. Insert the Welcome Post if it doesn't already exist (checking by content signature)
        IF NOT EXISTS (SELECT 1 FROM public.posts WHERE content LIKE 'Welcome to CareerBridge!%') THEN
            INSERT INTO public.posts (
                author_id,
                content,
                image_urls,
                post_type,
                likes_count,
                comments_count,
                created_at
            ) VALUES (
                v_author_id,
                'Welcome to CareerBridge! 🚀

We are thrilled to launch this platform dedicated to students and recruiters. 
Connect with peers, showcase your verified skills, and CAREERBRIDGE your career to new heights.

Stay tuned for upcoming hackathons and exclusive job drives!

#CareerBridge #Career #Welcome #Launch',
                '["assets/images/welcome_post.png"]'::jsonb, -- Local asset image
                'article',
                150, -- Artificial hype
                25,
                now()
            );
        END IF;
    END IF;
END $$;
