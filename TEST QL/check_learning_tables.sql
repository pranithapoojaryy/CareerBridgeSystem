-- Check what tables actually exist for learning system
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename LIKE '%learning%'
ORDER BY tablename;

-- Check structure of any module-related tables
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name LIKE '%module%'
ORDER BY table_name, ordinal_position;
