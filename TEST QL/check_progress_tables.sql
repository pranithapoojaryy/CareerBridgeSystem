-- Check what progress tracking tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE '%progress%'
ORDER BY table_name;

-- Check what enrollment-related tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND (table_name LIKE '%student%' OR table_name LIKE '%enroll%')
ORDER BY table_name;

-- Check student_lecture_progress structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'student_lecture_progress'
ORDER BY ordinal_position;
