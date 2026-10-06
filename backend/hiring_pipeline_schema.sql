-- CareerBridge Hiring Pipeline Schema
-- This migration enhances the existing jobs/applications system with multi-round interview support

-- ============================================
-- PHASE 1: Enhance existing tables
-- ============================================

-- Add eligibility and package fields to jobs table
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS eligibility_cgpa DECIMAL(3,2);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS eligibility_batch TEXT[];
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS eligibility_departments TEXT[];
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS application_deadline TIMESTAMPTZ;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS package_lpa DECIMAL(5,2);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS stipend_monthly INT;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS is_remote BOOLEAN DEFAULT false;

-- Enhance job_applications table
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS current_round INT DEFAULT 0;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS resume_snapshot JSONB;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS profile_snapshot JSONB;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS cover_note TEXT;
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS overall_score DECIMAL(5,2);
ALTER TABLE job_applications ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMPTZ DEFAULT NOW();

-- ============================================
-- PHASE 2: Create new tables
-- ============================================

-- Job Rounds Configuration
CREATE TABLE IF NOT EXISTS job_rounds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE NOT NULL,
  round_number INT NOT NULL,
  round_type TEXT NOT NULL CHECK (round_type IN ('resume_screening', 'video_intro', 'technical', 'hr', 'coding', 'group_discussion', 'final')),
  title TEXT NOT NULL,
  instructions TEXT,
  submission_type TEXT CHECK (submission_type IN ('text', 'video', 'file', 'coding', 'none')),
  deadline_days INT DEFAULT 7,
  evaluation_criteria JSONB,
  is_active BOOLEAN DEFAULT false,
  is_mandatory BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(job_id, round_number)
);

-- Round Submissions by candidates
CREATE TABLE IF NOT EXISTS application_round_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES job_applications(id) ON DELETE CASCADE NOT NULL,
  round_id UUID REFERENCES job_rounds(id) ON DELETE CASCADE NOT NULL,
  submission_type TEXT NOT NULL,
  text_response TEXT,
  video_url TEXT,
  file_urls TEXT[],
  coding_response JSONB,
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'passed', 'failed')),
  UNIQUE(application_id, round_id)
);

-- Round Evaluations by recruiters
CREATE TABLE IF NOT EXISTS round_evaluations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id UUID REFERENCES application_round_submissions(id) ON DELETE CASCADE NOT NULL,
  evaluator_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  score DECIMAL(5,2),
  feedback TEXT,
  remarks JSONB,
  decision TEXT CHECK (decision IN ('pass', 'fail', 'hold')),
  evaluated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Offers extended to students
CREATE TABLE IF NOT EXISTS offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES job_applications(id) ON DELETE CASCADE UNIQUE NOT NULL,
  offer_type TEXT CHECK (offer_type IN ('internship', 'full_time', 'ppo', 'contract')),
  package_amount DECIMAL(12,2),
  currency TEXT DEFAULT 'INR',
  joining_date DATE,
  location TEXT,
  offer_letter_url TEXT,
  additional_benefits TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired', 'revoked')),
  extended_at TIMESTAMPTZ DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  expiry_date DATE
);

-- Hiring-specific notifications
CREATE TABLE IF NOT EXISTS hiring_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('application_received', 'status_update', 'shortlisted', 'round_task', 'round_result', 'selected', 'rejected', 'offer_extended', 'offer_response')),
  title TEXT NOT NULL,
  message TEXT,
  data JSONB,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PHASE 3: Indexes for performance
-- ============================================

CREATE INDEX IF NOT EXISTS idx_job_rounds_job ON job_rounds(job_id);
CREATE INDEX IF NOT EXISTS idx_job_rounds_active ON job_rounds(job_id, is_active);
CREATE INDEX IF NOT EXISTS idx_submissions_application ON application_round_submissions(application_id);
CREATE INDEX IF NOT EXISTS idx_submissions_round ON application_round_submissions(round_id);
CREATE INDEX IF NOT EXISTS idx_submissions_status ON application_round_submissions(status);
CREATE INDEX IF NOT EXISTS idx_evaluations_submission ON round_evaluations(submission_id);
CREATE INDEX IF NOT EXISTS idx_offers_application ON offers(application_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON hiring_notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON hiring_notifications(user_id) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_applications_status ON job_applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_job ON job_applications(job_id);

-- ============================================
-- PHASE 4: RLS Policies
-- ============================================

-- Enable RLS
ALTER TABLE job_rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE application_round_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE round_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE hiring_notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if re-running
DROP POLICY IF EXISTS "job_rounds_read" ON job_rounds;
DROP POLICY IF EXISTS "job_rounds_insert" ON job_rounds;
DROP POLICY IF EXISTS "job_rounds_update" ON job_rounds;
DROP POLICY IF EXISTS "submissions_read" ON application_round_submissions;
DROP POLICY IF EXISTS "submissions_insert" ON application_round_submissions;
DROP POLICY IF EXISTS "submissions_update" ON application_round_submissions;
DROP POLICY IF EXISTS "evaluations_read" ON round_evaluations;
DROP POLICY IF EXISTS "evaluations_insert" ON round_evaluations;
DROP POLICY IF EXISTS "offers_read" ON offers;
DROP POLICY IF EXISTS "offers_insert" ON offers;
DROP POLICY IF EXISTS "offers_update" ON offers;
DROP POLICY IF EXISTS "notifications_read" ON hiring_notifications;
DROP POLICY IF EXISTS "notifications_update" ON hiring_notifications;

-- Job Rounds Policies
CREATE POLICY "job_rounds_read" ON job_rounds FOR SELECT USING (true);
CREATE POLICY "job_rounds_insert" ON job_rounds FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM jobs WHERE jobs.id = job_id AND jobs.posted_by = auth.uid())
);
CREATE POLICY "job_rounds_update" ON job_rounds FOR UPDATE USING (
  EXISTS (SELECT 1 FROM jobs WHERE jobs.id = job_id AND jobs.posted_by = auth.uid())
);

-- Round Submissions Policies
CREATE POLICY "submissions_read" ON application_round_submissions FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM job_applications ja
    WHERE ja.id = application_id AND (
      ja.student_id = auth.uid() OR
      EXISTS (SELECT 1 FROM jobs j WHERE j.id = ja.job_id AND j.posted_by = auth.uid())
    )
  )
);
CREATE POLICY "submissions_insert" ON application_round_submissions FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM job_applications ja
    WHERE ja.id = application_id AND ja.student_id = auth.uid()
  )
);
CREATE POLICY "submissions_update" ON application_round_submissions FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM job_applications ja
    JOIN jobs j ON j.id = ja.job_id
    WHERE ja.id = application_id AND j.posted_by = auth.uid()
  )
);

-- Round Evaluations Policies
CREATE POLICY "evaluations_read" ON round_evaluations FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM application_round_submissions s
    JOIN job_applications ja ON ja.id = s.application_id
    JOIN jobs j ON j.id = ja.job_id
    WHERE s.id = submission_id AND (ja.student_id = auth.uid() OR j.posted_by = auth.uid())
  )
);
CREATE POLICY "evaluations_insert" ON round_evaluations FOR INSERT WITH CHECK (
  evaluator_id = auth.uid()
);

-- Offers Policies
CREATE POLICY "offers_read" ON offers FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM job_applications ja
    WHERE ja.id = application_id AND (
      ja.student_id = auth.uid() OR
      EXISTS (SELECT 1 FROM jobs j WHERE j.id = ja.job_id AND j.posted_by = auth.uid())
    )
  )
);
CREATE POLICY "offers_insert" ON offers FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM job_applications ja
    JOIN jobs j ON j.id = ja.job_id
    WHERE ja.id = application_id AND j.posted_by = auth.uid()
  )
);
CREATE POLICY "offers_update" ON offers FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM job_applications ja
    WHERE ja.id = application_id AND (
      ja.student_id = auth.uid() OR
      EXISTS (SELECT 1 FROM jobs j WHERE j.id = ja.job_id AND j.posted_by = auth.uid())
    )
  )
);

-- Notifications Policies
CREATE POLICY "notifications_read" ON hiring_notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "notifications_update" ON hiring_notifications FOR UPDATE USING (user_id = auth.uid());

-- ============================================
-- PHASE 5: Helper Functions
-- ============================================

-- Function to get application progress percentage
CREATE OR REPLACE FUNCTION get_application_progress(app_id UUID)
RETURNS INT AS $$
DECLARE
  total_rounds INT;
  completed_rounds INT;
BEGIN
  SELECT COUNT(*) INTO total_rounds
  FROM job_rounds jr
  JOIN job_applications ja ON ja.job_id = jr.job_id
  WHERE ja.id = app_id;
  
  IF total_rounds = 0 THEN RETURN 0; END IF;
  
  SELECT COUNT(*) INTO completed_rounds
  FROM application_round_submissions s
  WHERE s.application_id = app_id AND s.status IN ('passed', 'reviewed');
  
  RETURN (completed_rounds * 100 / total_rounds);
END;
$$ LANGUAGE plpgsql;

-- Function to automatically create default rounds when job is posted
CREATE OR REPLACE FUNCTION create_default_job_rounds()
RETURNS TRIGGER AS $$
BEGIN
  -- Always create resume screening as first round
  INSERT INTO job_rounds (job_id, round_number, round_type, title, submission_type, is_active)
  VALUES (NEW.id, 1, 'resume_screening', 'Resume Screening', 'none', true);
  
  -- If screening questions exist, create video intro round
  IF NEW.screening_questions IS NOT NULL AND array_length(NEW.screening_questions, 1) > 0 THEN
    INSERT INTO job_rounds (job_id, round_number, round_type, title, submission_type, is_active, instructions)
    VALUES (NEW.id, 2, 'video_intro', 'Video Introduction', 'video', false, 
            'Please record your video responses to the screening questions.');
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger (drop first if exists)
DROP TRIGGER IF EXISTS job_create_default_rounds ON jobs;
CREATE TRIGGER job_create_default_rounds
  AFTER INSERT ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION create_default_job_rounds();

-- ============================================
-- SUCCESS
-- ============================================
SELECT 'Hiring Pipeline Schema created successfully!' AS result;
