-- Enhance posts table for tagging, hashtags, and multi-image support
-- Note: 'image_urls' already exists as JSONB, which supports multiple images.

-- 1. Add Hashtags Support
ALTER TABLE public.posts 
ADD COLUMN IF NOT EXISTS hashtags TEXT[] DEFAULT '{}';

-- 2. Add Mentions Support (tagging users)
ALTER TABLE public.posts 
ADD COLUMN IF NOT EXISTS mentions UUID[] DEFAULT '{}';

-- 3. Add Media Type (future proofing for video/carousel)
ALTER TABLE public.posts 
ADD COLUMN IF NOT EXISTS media_type TEXT DEFAULT 'image' CHECK (media_type IN ('image', 'video', 'carousel', 'none'));

-- 4. Create Index for searching hashtags (GIN index is best for arrays)
CREATE INDEX IF NOT EXISTS idx_posts_hashtags ON public.posts USING GIN (hashtags);

-- 5. Create Index for mentions lookup
CREATE INDEX IF NOT EXISTS idx_posts_mentions ON public.posts USING GIN (mentions);
