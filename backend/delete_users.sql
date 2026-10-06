-- =====================================================
-- DELETE USER - Drop trigger, delete user, recreate trigger
-- =====================================================

-- STEP 1: Drop the problematic trigger
DROP TRIGGER IF EXISTS update_student_stats_on_profile_change ON public.profiles;

-- STEP 2: Delete from all dependent tables
DELETE FROM public.student_stats WHERE student_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.student_activity_logs WHERE student_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.student_certifications WHERE student_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.student_skills WHERE student_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.student_skill_validations WHERE student_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.aptitude_attempts WHERE student_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.assessment_attempts WHERE student_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.event_registrations WHERE student_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.test_assignments WHERE assigned_to_user = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.resumes WHERE user_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.connections WHERE requester_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a' OR receiver_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.messages WHERE sender_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a' OR receiver_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.post_likes WHERE user_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.post_comments WHERE user_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.posts WHERE author_id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.student_profiles WHERE id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM public.profiles WHERE id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';
DELETE FROM auth.users WHERE id = '4eb034c6-560f-46e8-9666-b0b20ade7c4a';

-- STEP 3: Recreate the trigger (if it exists)
-- You may need to adjust this based on your actual trigger definition
CREATE TRIGGER update_student_stats_on_profile_change
AFTER UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION update_student_stats_trigger();

-- STEP 4: Verify deletion
SELECT 'User deleted successfully!' as status;
SELECT * FROM auth.users WHERE email = 'neelanjanv08@gmail.com';
