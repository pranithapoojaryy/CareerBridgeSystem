-- Change provider_id to TEXT to support non-UUID user IDs (e.g. timestamps used in some environments)

-- 1. Alter learning_courses
DO $$ 
BEGIN
  -- Drop foreign key constraint if it exists (it enforces UUID)
  IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'learning_courses_provider_id_fkey' AND table_name = 'learning_courses') THEN
    ALTER TABLE learning_courses DROP CONSTRAINT learning_courses_provider_id_fkey;
  END IF;

  -- Change column type
  ALTER TABLE learning_courses ALTER COLUMN provider_id TYPE text;
END $$;
