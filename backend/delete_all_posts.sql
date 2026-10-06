-- =====================================================
-- DELETE ALL POSTS IN THE APPLICATION
-- =====================================================
-- Running this SQL in your Supabase SQL Editor will delete
-- all posts, comments, likes, and clean up post storage.

BEGIN;

-- 1. Delete all likes on posts
DELETE FROM public.post_likes;

-- 2. Delete all comments on posts
DELETE FROM public.post_comments;

-- 3. Delete all posts
DELETE FROM public.posts;

COMMIT;

-- Verification query
SELECT COUNT(*) AS remaining_posts FROM public.posts;
