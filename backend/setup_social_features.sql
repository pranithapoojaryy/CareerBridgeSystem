-- Social Feed & Connections System

-- 1. Connections Table
CREATE TABLE IF NOT EXISTS public.connections (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    requester_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(requester_id, receiver_id)
);

-- 2. Posts Table (LinkedIn/Insta style)
CREATE TABLE IF NOT EXISTS public.posts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    author_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT,
    image_urls JSONB DEFAULT '[]'::jsonb, -- Array of image URLs
    post_type TEXT DEFAULT 'general' CHECK (post_type IN ('general', 'job_update', 'achievement', 'article', 'college_news')),
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Ensure columns exist if table was already created
DO $$
BEGIN
    ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS image_urls JSONB DEFAULT '[]'::jsonb;
    ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS reference_id UUID;
    ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS reference_type TEXT DEFAULT 'none' CHECK (reference_type IN ('none', 'certification', 'project', 'job'));
    ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS reference_data JSONB DEFAULT '{}'::jsonb;
EXCEPTION
    WHEN duplicate_column THEN NULL;
END $$;

-- 3. Post Likes
CREATE TABLE IF NOT EXISTS public.post_likes (
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    PRIMARY KEY (post_id, user_id)
);

-- 4. Post Comments
CREATE TABLE IF NOT EXISTS public.post_comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_connections_users ON public.connections(requester_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_posts_author ON public.posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON public.posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_comments_post ON public.post_comments(post_id);

-- RLS Policies
ALTER TABLE public.connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;

-- Connections Policies
DROP POLICY IF EXISTS "Users can view their own connections" ON public.connections;
CREATE POLICY "Users can view their own connections" ON public.connections
    FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can manage connections" ON public.connections;
CREATE POLICY "Users can manage connections" ON public.connections
    FOR ALL USING (auth.uid() = requester_id OR auth.uid() = receiver_id);

-- Posts Policies (Values openness)
DROP POLICY IF EXISTS "Everyone can view posts" ON public.posts;
CREATE POLICY "Everyone can view posts" ON public.posts
    FOR SELECT USING (true); -- Public feed for now

DROP POLICY IF EXISTS "Users can create posts" ON public.posts;
CREATE POLICY "Users can create posts" ON public.posts
    FOR INSERT WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Users can update own posts" ON public.posts;
CREATE POLICY "Users can update own posts" ON public.posts
    FOR UPDATE USING (auth.uid() = author_id);

DROP POLICY IF EXISTS "Users can delete own posts" ON public.posts;
CREATE POLICY "Users can delete own posts" ON public.posts
    FOR DELETE USING (auth.uid() = author_id);

-- Likes Policies
DROP POLICY IF EXISTS "Everyone can view likes" ON public.post_likes;
CREATE POLICY "Everyone can view likes" ON public.post_likes
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can toggle likes" ON public.post_likes;
CREATE POLICY "Users can toggle likes" ON public.post_likes
    FOR ALL USING (auth.uid() = user_id);

-- Comments Policies
DROP POLICY IF EXISTS "Everyone can view comments" ON public.post_comments;
CREATE POLICY "Everyone can view comments" ON public.post_comments
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can comment" ON public.post_comments;
CREATE POLICY "Users can comment" ON public.post_comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Triggers for Likes/Comments Count
CREATE OR REPLACE FUNCTION update_post_stats() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        IF (TG_TABLE_NAME = 'post_likes') THEN
            UPDATE public.posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
        ELSIF (TG_TABLE_NAME = 'post_comments') THEN
            UPDATE public.posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
        END IF;
    ELSIF (TG_OP = 'DELETE') THEN
        IF (TG_TABLE_NAME = 'post_likes') THEN
            UPDATE public.posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
        ELSIF (TG_TABLE_NAME = 'post_comments') THEN
            UPDATE public.posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_post_likes_count ON public.post_likes;
CREATE TRIGGER trigger_post_likes_count
AFTER INSERT OR DELETE ON public.post_likes
FOR EACH ROW EXECUTE FUNCTION update_post_stats();

DROP TRIGGER IF EXISTS trigger_post_comments_count ON public.post_comments;
CREATE TRIGGER trigger_post_comments_count
AFTER INSERT OR DELETE ON public.post_comments
FOR EACH ROW EXECUTE FUNCTION update_post_stats();


-- SEED DATA (Make sure not to duplicate too much if run multiple times)
-- We need to find some users to be authors. We will pick from existing profiles.

DO $$
DECLARE
    v_user_id UUID;
    v_recruiter_id UUID;
    v_college_id UUID;
BEGIN
    -- Get a student ID (current user or random)
    SELECT id INTO v_user_id FROM auth.users LIMIT 1;
    
    -- Insert some dummy activity logs for the student if empty
    IF NOT EXISTS (SELECT 1 FROM public.student_activity_logs WHERE student_id = v_user_id LIMIT 1) THEN
        INSERT INTO public.student_activity_logs (student_id, activity_type, activity_data, created_at)
        VALUES 
        (v_user_id, 'profile_update', '{"field": "skills", "action": "added", "value": "Flutter"}', now() - interval '2 hours'),
        (v_user_id, 'assessment_complete', '{"title": "Java Basics", "score": 85}', now() - interval '1 day'),
        (v_user_id, 'job_application', '{"job_title": "Junior Developer", "company": "TechCorp"}', now() - interval '2 days');
    END IF;

    -- Create some Posts
    -- 1. Text Post
    INSERT INTO public.posts (author_id, content, post_type, likes_count, created_at)
    VALUES (v_user_id, 'Excited to join CareerBridge! looking forward to connecting with recruiters.', 'general', 5, now() - interval '5 days');

    -- 2. Certificate Post (Rich Content)
    INSERT INTO public.posts (author_id, content, post_type, reference_type, reference_data, likes_count, created_at)
    VALUES (
        v_user_id, 
        'Thrilled to share that I have successfully completed the Java Programming Certification from NPTEL! 🎓 #java #learning #certification', 
        'achievement',
        'certification',
        '{"title": "Java Programming", "subtitle": "Issued by NPTEL", "image_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/NPTEL_logo.png/320px-NPTEL_logo.png", "verification_status": "verified"}'::jsonb,
        24, 
        now() - interval '2 days'
    );

    -- 3. Project Post (Image + Tags)
    -- Simulating images logic
    INSERT INTO public.posts (author_id, content, post_type, image_urls, likes_count, created_at)
    VALUES (
        v_user_id,
        'Just finished building a Flutter E-commerce app! Check out the UI. 📱 #flutter #coding #mobiledev @CareerBridge',
        'general',
        '["https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png"]'::jsonb,
        42,
        now() - interval '4 hours'
    );

END $$;-- Social Feed & Connections System

-- 0. Dependencies (Ensure these exist for Dashboard)
CREATE TABLE IF NOT EXISTS public.student_activity_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL,
    activity_data JSONB DEFAULT '{}'::jsonb,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    college_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    announcement_type TEXT CHECK (announcement_type IN ('general', 'placement', 'academic', 'event', 'urgent', 'celebration')),
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    target_audience JSONB DEFAULT '[]'::jsonb,
    attachments JSONB DEFAULT '[]'::jsonb,
    is_published BOOLEAN DEFAULT FALSE,
    publish_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    expires_at TIMESTAMP WITH TIME ZONE,
    views_count INTEGER DEFAULT 0,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS for Dependencies
ALTER TABLE public.student_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Students can view own activity logs" ON public.student_activity_logs;
CREATE POLICY "Students can view own activity logs" ON public.student_activity_logs
    FOR SELECT USING (auth.uid() = student_id);

DROP POLICY IF EXISTS "Students can create activity logs" ON public.student_activity_logs;
CREATE POLICY "Students can create activity logs" ON public.student_activity_logs
    FOR INSERT WITH CHECK (auth.uid() = student_id);

DROP POLICY IF EXISTS "Students can view published announcements" ON public.announcements;
CREATE POLICY "Students can view published announcements" ON public.announcements
    FOR SELECT USING (is_published = true);

-- 1. Connections Table
CREATE TABLE IF NOT EXISTS public.connections (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    requester_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(requester_id, receiver_id)
);

-- 2. Posts Table (LinkedIn/Insta style)
CREATE TABLE IF NOT EXISTS public.posts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    author_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT,
    image_urls JSONB DEFAULT '[]'::jsonb, -- Array of image URLs
    post_type TEXT DEFAULT 'general' CHECK (post_type IN ('general', 'job_update', 'achievement', 'article', 'college_news')),
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 3. Post Likes
CREATE TABLE IF NOT EXISTS public.post_likes (
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    PRIMARY KEY (post_id, user_id)
);

-- 4. Post Comments
CREATE TABLE IF NOT EXISTS public.post_comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_connections_users ON public.connections(requester_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_posts_author ON public.posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON public.posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_comments_post ON public.post_comments(post_id);

-- RLS Policies
ALTER TABLE public.connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;

-- Connections Policies
DROP POLICY IF EXISTS "Users can view their own connections" ON public.connections;
CREATE POLICY "Users can view their own connections" ON public.connections
    FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can manage connections" ON public.connections;
CREATE POLICY "Users can manage connections" ON public.connections
    FOR ALL USING (auth.uid() = requester_id OR auth.uid() = receiver_id);

-- Posts Policies (Values openness)
DROP POLICY IF EXISTS "Everyone can view posts" ON public.posts;
CREATE POLICY "Everyone can view posts" ON public.posts
    FOR SELECT USING (true); -- Public feed for now

DROP POLICY IF EXISTS "Users can create posts" ON public.posts;
CREATE POLICY "Users can create posts" ON public.posts
    FOR INSERT WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Users can update own posts" ON public.posts;
CREATE POLICY "Users can update own posts" ON public.posts
    FOR UPDATE USING (auth.uid() = author_id);

DROP POLICY IF EXISTS "Users can delete own posts" ON public.posts;
CREATE POLICY "Users can delete own posts" ON public.posts
    FOR DELETE USING (auth.uid() = author_id);

-- Likes Policies
DROP POLICY IF EXISTS "Everyone can view likes" ON public.post_likes;
CREATE POLICY "Everyone can view likes" ON public.post_likes
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can toggle likes" ON public.post_likes;
CREATE POLICY "Users can toggle likes" ON public.post_likes
    FOR ALL USING (auth.uid() = user_id);

-- Comments Policies
DROP POLICY IF EXISTS "Everyone can view comments" ON public.post_comments;
CREATE POLICY "Everyone can view comments" ON public.post_comments
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can comment" ON public.post_comments;
CREATE POLICY "Users can comment" ON public.post_comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Triggers for Likes/Comments Count
CREATE OR REPLACE FUNCTION update_post_stats() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        IF (TG_TABLE_NAME = 'post_likes') THEN
            UPDATE public.posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
        ELSIF (TG_TABLE_NAME = 'post_comments') THEN
            UPDATE public.posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
        END IF;
    ELSIF (TG_OP = 'DELETE') THEN
        IF (TG_TABLE_NAME = 'post_likes') THEN
            UPDATE public.posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
        ELSIF (TG_TABLE_NAME = 'post_comments') THEN
            UPDATE public.posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_post_likes_count ON public.post_likes;
CREATE TRIGGER trigger_post_likes_count
AFTER INSERT OR DELETE ON public.post_likes
FOR EACH ROW EXECUTE FUNCTION update_post_stats();

DROP TRIGGER IF EXISTS trigger_post_comments_count ON public.post_comments;
CREATE TRIGGER trigger_post_comments_count
AFTER INSERT OR DELETE ON public.post_comments
FOR EACH ROW EXECUTE FUNCTION update_post_stats();


-- SEED DATA (Make sure not to duplicate too much if run multiple times)
-- We need to find some users to be authors. We will pick from existing profiles.

DO $$
DECLARE
    v_user_id UUID;
    v_recruiter_id UUID;
    v_college_id UUID;
BEGIN
    -- Get a student ID (current user or random)
    SELECT id INTO v_user_id FROM auth.users LIMIT 1;
    
    -- Insert some dummy activity logs for the student if empty
    IF NOT EXISTS (SELECT 1 FROM public.student_activity_logs WHERE student_id = v_user_id LIMIT 1) THEN
        INSERT INTO public.student_activity_logs (student_id, activity_type, activity_data, created_at)
        VALUES 
        (v_user_id, 'profile_update', '{"field": "skills", "action": "added", "value": "Flutter"}', now() - interval '2 hours'),
        (v_user_id, 'assessment_complete', '{"title": "Java Basics", "score": 85}', now() - interval '1 day'),
        (v_user_id, 'job_application', '{"job_title": "Junior Developer", "company": "TechCorp"}', now() - interval '2 days');
    END IF;

    -- Create some Posts
    -- 1. Welcome Post
    INSERT INTO public.posts (author_id, content, post_type, likes_count, created_at)
    VALUES (v_user_id, 'Excited to join CareerBridge! looking forward to connecting with recruiters.', 'general', 5, now() - interval '5 days');

    -- 2. Achievement
    INSERT INTO public.posts (author_id, content, post_type, likes_count, created_at)
    VALUES (v_user_id, 'Just completed my Java Certification from NPTEL! #learning #java', 'achievement', 12, now() - interval '2 days');

END $$;

