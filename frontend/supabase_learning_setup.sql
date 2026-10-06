-- ============================================
-- CareerBridge - LEARNING PATH ENHANCEMENTS
-- Migration: Adds new metadata fields only
-- ============================================

-- ============================================
-- STEP 1: ADD NEW COLUMNS TO EXISTING TABLES
-- ============================================

-- Enhance learning_courses with curriculum metadata
ALTER TABLE learning_courses ADD COLUMN IF NOT EXISTS curriculum_code TEXT;
ALTER TABLE learning_courses ADD COLUMN IF NOT EXISTS prerequisites TEXT;
ALTER TABLE learning_courses ADD COLUMN IF NOT EXISTS target_role TEXT;
ALTER TABLE learning_courses ADD COLUMN IF NOT EXISTS estimated_duration_weeks INT;
ALTER TABLE learning_courses ADD COLUMN IF NOT EXISTS placement_relevance TEXT;
ALTER TABLE learning_courses ADD COLUMN IF NOT EXISTS skills_gained TEXT[];
ALTER TABLE learning_courses ADD COLUMN IF NOT EXISTS learning_outcomes TEXT;
ALTER TABLE learning_courses ADD COLUMN IF NOT EXISTS domain_type TEXT;
ALTER TABLE learning_courses ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Enhance sections with module controls
ALTER TABLE learning_course_sections ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE learning_course_sections ADD COLUMN IF NOT EXISTS module_type TEXT;
ALTER TABLE learning_course_sections ADD COLUMN IF NOT EXISTS estimated_hours NUMERIC;
ALTER TABLE learning_course_sections ADD COLUMN IF NOT EXISTS is_mandatory BOOLEAN DEFAULT TRUE;
ALTER TABLE learning_course_sections ADD COLUMN IF NOT EXISTS unlock_rule TEXT DEFAULT 'Sequential';
ALTER TABLE learning_course_sections ADD COLUMN IF NOT EXISTS skills_covered TEXT[];
ALTER TABLE learning_course_sections ADD COLUMN IF NOT EXISTS assessment_required BOOLEAN DEFAULT FALSE;
ALTER TABLE learning_course_sections ADD COLUMN IF NOT EXISTS completion_criteria TEXT;
ALTER TABLE learning_course_sections ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Enhance lectures with resource details
ALTER TABLE learning_course_lectures ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE learning_course_lectures ADD COLUMN IF NOT EXISTS source_type TEXT;
ALTER TABLE learning_course_lectures ADD COLUMN IF NOT EXISTS is_mandatory BOOLEAN DEFAULT TRUE;
ALTER TABLE learning_course_lectures ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Enhance enrollments with guide/progress tracking
ALTER TABLE student_course_enrollments ADD COLUMN IF NOT EXISTS enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE student_course_enrollments ADD COLUMN IF NOT EXISTS current_section_id UUID REFERENCES learning_course_sections(id);
ALTER TABLE student_course_enrollments ADD COLUMN IF NOT EXISTS assigned_guide_id UUID REFERENCES auth.users(id);
ALTER TABLE student_course_enrollments ADD COLUMN IF NOT EXISTS faculty_remarks TEXT;

-- Enhance lecture progress
ALTER TABLE student_lecture_progress ADD COLUMN IF NOT EXISTS student_id UUID REFERENCES auth.users(id);
ALTER TABLE student_lecture_progress ADD COLUMN IF NOT EXISTS watched_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE student_lecture_progress ADD COLUMN IF NOT EXISTS watch_duration_seconds INT;
ALTER TABLE student_lecture_progress ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- ============================================
-- STEP 2: CREATE NEW TABLES
-- ============================================

-- IT-Specific metadata
CREATE TABLE IF NOT EXISTS learning_course_it_metadata (
  course_id UUID PRIMARY KEY REFERENCES learning_courses(id) ON DELETE CASCADE,
  programming_languages TEXT[],
  tools_frameworks TEXT[],
  code_practice_required BOOLEAN DEFAULT FALSE,
  mini_projects_count INT DEFAULT 0,
  github_submission_required BOOLEAN DEFAULT FALSE,
  system_design_level TEXT,
  lab_sessions_required BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Management-Specific metadata  
CREATE TABLE IF NOT EXISTS learning_course_mgmt_metadata (
  course_id UUID PRIMARY KEY REFERENCES learning_courses(id) ON DELETE CASCADE,
  case_studies_required BOOLEAN DEFAULT FALSE,
  presentation_required BOOLEAN DEFAULT FALSE,
  group_activity_required BOOLEAN DEFAULT FALSE,
  communication_skill_weight TEXT,
  industry_examples TEXT[],
  role_play_required BOOLEAN DEFAULT FALSE,
  report_submission_required BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Assessments
CREATE TABLE IF NOT EXISTS learning_course_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id UUID REFERENCES learning_course_sections(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  assessment_type TEXT NOT NULL,
  description TEXT,
  passing_criteria NUMERIC,
  weightage NUMERIC,
  attempts_allowed INT DEFAULT 1,
  is_auto_evaluated BOOLEAN DEFAULT FALSE,
  questions JSONB,
  feedback_template TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Module Progress
CREATE TABLE IF NOT EXISTS student_module_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  section_id UUID REFERENCES learning_course_sections(id) ON DELETE CASCADE,
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  status TEXT,
  UNIQUE(student_id, section_id)
);

-- Assessment Submissions
CREATE TABLE IF NOT EXISTS student_assessment_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  assessment_id UUID REFERENCES learning_course_assessments(id) ON DELETE CASCADE,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  attempt_number INT DEFAULT 1,
  answers JSONB,
  submission_url TEXT,
  score NUMERIC,
  is_passed BOOLEAN,
  faculty_feedback TEXT,
  evaluated_at TIMESTAMP WITH TIME ZONE,
  evaluated_by UUID REFERENCES auth.users(id),
  UNIQUE(student_id, assessment_id, attempt_number)
);

-- ============================================
-- STEP 3: ADD CONSTRAINTS
-- ============================================

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'learning_courses_placement_check') THEN
    ALTER TABLE learning_courses ADD CONSTRAINT learning_courses_placement_check 
      CHECK (placement_relevance IN ('High', 'Medium', 'Low'));
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'learning_courses_domain_check') THEN
    ALTER TABLE learning_courses ADD CONSTRAINT learning_courses_domain_check 
      CHECK (domain_type IN ('IT', 'Management', 'General'));
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sections_module_type_check') THEN
    ALTER TABLE learning_course_sections ADD CONSTRAINT sections_module_type_check 
      CHECK (module_type IN ('Theory', 'Practice', 'Assessment'));
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sections_unlock_rule_check') THEN
    ALTER TABLE learning_course_sections ADD CONSTRAINT sections_unlock_rule_check 
      CHECK (unlock_rule IN ('Sequential', 'Manual', 'Free'));
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'lectures_source_type_check') THEN
    ALTER TABLE learning_course_lectures ADD CONSTRAINT lectures_source_type_check 
      CHECK (source_type IN ('youtube', 'gdrive', 'uploaded', 'external'));
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assessments_type_check') THEN
    ALTER TABLE learning_course_assessments ADD CONSTRAINT assessments_type_check 
      CHECK (assessment_type IN ('Quiz', 'Assignment', 'Video Response', 'Code Task'));
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'module_progress_status_check') THEN
    ALTER TABLE student_module_progress ADD CONSTRAINT module_progress_status_check 
      CHECK (status IN ('Not Started', 'In Progress', 'Completed'));
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'it_metadata_system_design_check') THEN
    ALTER TABLE learning_course_it_metadata ADD CONSTRAINT it_metadata_system_design_check 
      CHECK (system_design_level IN ('Basic', 'Intermediate', 'Advanced'));
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'mgmt_metadata_comm_weight_check') THEN
    ALTER TABLE learning_course_mgmt_metadata ADD CONSTRAINT mgmt_metadata_comm_weight_check 
      CHECK (communication_skill_weight IN ('High', 'Medium', 'Low'));
  END IF;
END $$;

-- ============================================
-- STEP 4: ENABLE RLS ON NEW TABLES
-- ============================================

ALTER TABLE learning_course_it_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_course_mgmt_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_course_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_module_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_assessment_submissions ENABLE ROW LEVEL SECURITY;

-- IT Metadata Policies
DROP POLICY IF EXISTS "Public can view IT metadata" ON learning_course_it_metadata;
CREATE POLICY "Public can view IT metadata" ON learning_course_it_metadata FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Creators can manage IT metadata" ON learning_course_it_metadata;
CREATE POLICY "Creators can manage IT metadata" ON learning_course_it_metadata FOR ALL USING (
  EXISTS (SELECT 1 FROM learning_courses WHERE id = course_id AND provider_id = auth.uid())
);

-- Management Metadata Policies
DROP POLICY IF EXISTS "Public can view mgmt metadata" ON learning_course_mgmt_metadata;
CREATE POLICY "Public can view mgmt metadata" ON learning_course_mgmt_metadata FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Creators can manage mgmt metadata" ON learning_course_mgmt_metadata;
CREATE POLICY "Creators can manage mgmt metadata" ON learning_course_mgmt_metadata FOR ALL USING (
  EXISTS (SELECT 1 FROM learning_courses WHERE id = course_id AND provider_id = auth.uid())
);

-- Assessment Policies
DROP POLICY IF EXISTS "Public can view assessments" ON learning_course_assessments;
CREATE POLICY "Public can view assessments" ON learning_course_assessments FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Creators can manage assessments" ON learning_course_assessments;
CREATE POLICY "Creators can manage assessments" ON learning_course_assessments FOR ALL USING (
  EXISTS (
    SELECT 1 FROM learning_course_sections s
    JOIN learning_courses c ON c.id = s.course_id
    WHERE s.id = section_id AND c.provider_id = auth.uid()
  )
);

-- Progress Policies
DROP POLICY IF EXISTS "Students manage their module progress" ON student_module_progress;
CREATE POLICY "Students manage their module progress" ON student_module_progress FOR ALL USING (auth.uid() = student_id);

DROP POLICY IF EXISTS "Students manage their submissions" ON student_assessment_submissions;
CREATE POLICY "Students manage their submissions" ON student_assessment_submissions FOR ALL USING (auth.uid() = student_id);

DROP POLICY IF EXISTS "Faculty can evaluate submissions" ON student_assessment_submissions;
CREATE POLICY "Faculty can evaluate submissions" ON student_assessment_submissions FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM student_course_enrollments e
    WHERE e.student_id = student_assessment_submissions.student_id AND e.assigned_guide_id = auth.uid()
  )
);

-- ============================================
-- STEP 5: CREATE INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_it_metadata_course ON learning_course_it_metadata(course_id);
CREATE INDEX IF NOT EXISTS idx_mgmt_metadata_course ON learning_course_mgmt_metadata(course_id);
CREATE INDEX IF NOT EXISTS idx_assessments_section ON learning_course_assessments(section_id);
CREATE INDEX IF NOT EXISTS idx_module_progress_student ON student_module_progress(student_id);
CREATE INDEX IF NOT EXISTS idx_assessment_submissions_student ON student_assessment_submissions(student_id);
