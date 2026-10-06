-- ============================================
-- CareerBridge - CERTIFICATES & SKILL SCORING
-- Adds certificate generation and skill tracking
-- ============================================

-- ============================================
-- STEP 1: CREATE CERTIFICATE TABLES
-- ============================================

-- Course Certificates
CREATE TABLE IF NOT EXISTS student_course_certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  course_id UUID REFERENCES learning_courses(id) ON DELETE CASCADE,
  certificate_number TEXT UNIQUE NOT NULL,
  issued_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  course_score NUMERIC NOT NULL,
  final_grade TEXT NOT NULL,
  provider_name TEXT NOT NULL,
  course_title TEXT NOT NULL,
  student_name TEXT NOT NULL,
  skills_acquired TEXT[],
  is_verified BOOLEAN DEFAULT TRUE,
  verification_url TEXT,
  certificate_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(student_id, course_id)
);

-- Certificate Verification Log
CREATE TABLE IF NOT EXISTS certificate_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  certificate_id UUID REFERENCES student_course_certificates(id) ON DELETE CASCADE,
  verified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  verified_by UUID REFERENCES auth.users(id),
  verification_method TEXT,
  ip_address TEXT
);

-- ============================================
-- STEP 2: CREATE SKILL SCORING TABLES
-- ============================================

-- Course-Skill Mapping (defines which skills a course teaches)
CREATE TABLE IF NOT EXISTS course_skill_mapping (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID REFERENCES learning_courses(id) ON DELETE CASCADE,
  skill_name TEXT NOT NULL,
  skill_category TEXT, -- Technical, Soft, Domain
  weightage NUMERIC DEFAULT 1.0, -- How important this skill is in the course
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(course_id, skill_name)
);

-- Assessment-Skill Mapping (defines which skills an assessment evaluates)
CREATE TABLE IF NOT EXISTS assessment_skill_mapping (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id UUID REFERENCES learning_course_assessments(id) ON DELETE CASCADE,
  skill_name TEXT NOT NULL,
  weightage NUMERIC DEFAULT 1.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(assessment_id, skill_name)
);

-- Student Skill Scores (aggregated skill proficiency)
CREATE TABLE IF NOT EXISTS student_skill_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  skill_name TEXT NOT NULL,
  skill_category TEXT,
  current_score NUMERIC DEFAULT 0, -- 0-100 scale
  assessment_count INT DEFAULT 0,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  acquired_from_courses TEXT[], -- List of course IDs
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(student_id, skill_name)
);

-- Skill Score History (track skill progression over time)
CREATE TABLE IF NOT EXISTS student_skill_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  skill_name TEXT NOT NULL,
  score_change NUMERIC,
  new_score NUMERIC,
  source_type TEXT, -- 'assessment', 'course_completion', 'manual'
  source_id UUID,
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- STEP 3: ADD INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_certificates_student ON student_course_certificates(student_id);
CREATE INDEX IF NOT EXISTS idx_certificates_course ON student_course_certificates(course_id);
CREATE INDEX IF NOT EXISTS idx_certificates_number ON student_course_certificates(certificate_number);

CREATE INDEX IF NOT EXISTS idx_course_skills ON course_skill_mapping(course_id);
CREATE INDEX IF NOT EXISTS idx_assessment_skills ON assessment_skill_mapping(assessment_id);

CREATE INDEX IF NOT EXISTS idx_student_skills ON student_skill_scores(student_id);
CREATE INDEX IF NOT EXISTS idx_skill_name ON student_skill_scores(skill_name);

CREATE INDEX IF NOT EXISTS idx_skill_history_student ON student_skill_history(student_id);
CREATE INDEX IF NOT EXISTS idx_skill_history_skill ON student_skill_history(skill_name);

-- ============================================
-- STEP 4: ADD RLS POLICIES
-- ============================================

-- Certificates: Students can view their own, recruiters can view all verified
ALTER TABLE student_course_certificates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students can view own certificates" ON student_course_certificates
  FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Recruiters can view verified certificates" ON student_course_certificates
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'recruiter'
    ) AND is_verified = TRUE
  );

CREATE POLICY "System can insert certificates" ON student_course_certificates
  FOR INSERT WITH CHECK (TRUE);

-- Skill Scores: Students can view own, system can update
ALTER TABLE student_skill_scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students can view own skills" ON student_skill_scores
  FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Students can view skill history" ON student_skill_history
  FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "System can manage skills" ON student_skill_scores
  FOR ALL USING (TRUE);

CREATE POLICY "System can manage skill history" ON student_skill_history
  FOR ALL USING (TRUE);

-- Course-Skill Mapping: Public read, faculty can manage
ALTER TABLE course_skill_mapping ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view course skills" ON course_skill_mapping
  FOR SELECT USING (TRUE);

CREATE POLICY "Faculty can manage course skills" ON course_skill_mapping
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role IN ('college', 'recruiter')
    )
  );

-- Assessment-Skill Mapping: Similar to course mapping
ALTER TABLE assessment_skill_mapping ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view assessment skills" ON assessment_skill_mapping
  FOR SELECT USING (TRUE);

CREATE POLICY "Faculty can manage assessment skills" ON assessment_skill_mapping
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role IN ('college', 'recruiter')
    )
  );

-- ============================================
-- STEP 5: CREATE CERTIFICATE GENERATION FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION generate_course_certificate(
  p_student_id UUID,
  p_course_id UUID,
  p_final_score NUMERIC
)
RETURNS UUID AS $$
DECLARE
  v_certificate_id UUID;
  v_cert_number TEXT;
  v_student_name TEXT;
  v_course_title TEXT;
  v_provider_name TEXT;
  v_skills TEXT[];
  v_grade TEXT;
BEGIN
  -- Generate unique certificate number
  v_cert_number := 'EH-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(FLOOR(RANDOM() * 999999)::TEXT, 6, '0');
  
  -- Get student info
  SELECT full_name INTO v_student_name FROM profiles WHERE id = p_student_id;
  
  -- Get course info
  SELECT title, provider_name, skills_gained 
  INTO v_course_title, v_provider_name, v_skills
  FROM learning_courses WHERE id = p_course_id;
  
  -- Calculate grade
  v_grade := CASE
    WHEN p_final_score >= 90 THEN 'A+'
    WHEN p_final_score >= 80 THEN 'A'
    WHEN p_final_score >= 70 THEN 'B+'
    WHEN p_final_score >= 60 THEN 'B'
    ELSE 'C'
  END;
  
  -- Insert certificate
  INSERT INTO student_course_certificates (
    student_id, course_id, certificate_number, course_score, final_grade,
    provider_name, course_title, student_name, skills_acquired, is_verified
  ) VALUES (
    p_student_id, p_course_id, v_cert_number, p_final_score, v_grade,
    v_provider_name, v_course_title, v_student_name, v_skills, TRUE
  )
  ON CONFLICT (student_id, course_id) 
  DO UPDATE SET
    course_score = p_final_score,
    final_grade = v_grade,
    issued_at = NOW()
  RETURNING id INTO v_certificate_id;
  
  -- Update skill scores
  PERFORM update_student_skills_from_course(p_student_id, p_course_id, p_final_score);
  
  RETURN v_certificate_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- STEP 6: CREATE SKILL SCORING FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_student_skills_from_assessment(
  p_student_id UUID,
  p_assessment_id UUID,
  p_score NUMERIC
)
RETURNS VOID AS $$
DECLARE
  v_skill RECORD;
  v_current_score NUMERIC;
  v_new_score NUMERIC;
BEGIN
  -- Loop through all skills for this assessment
  FOR v_skill IN 
    SELECT skill_name, skill_category, weightage 
    FROM assessment_skill_mapping 
    WHERE assessment_id = p_assessment_id
  LOOP
    -- Get current skill score
    SELECT current_score INTO v_current_score
    FROM student_skill_scores
    WHERE student_id = p_student_id AND skill_name = v_skill.skill_name;
    
    -- Calculate new score (weighted average)
    IF v_current_score IS NULL THEN
      v_new_score := p_score * v_skill.weightage;
      
      INSERT INTO student_skill_scores (student_id, skill_name, skill_category, current_score, assessment_count)
      VALUES (p_student_id, v_skill.skill_name, v_skill.skill_category, v_new_score, 1);
    ELSE
      v_new_score := (v_current_score + (p_score * v_skill.weightage)) / 2;
      
      UPDATE student_skill_scores
      SET current_score = v_new_score, 
          assessment_count = assessment_count + 1,
          last_updated = NOW()
      WHERE student_id = p_student_id AND skill_name = v_skill.skill_name;
    END IF;
    
    -- Record history
    INSERT INTO student_skill_history (student_id, skill_name, score_change, new_score, source_type, source_id)
    VALUES (p_student_id, v_skill.skill_name, p_score - COALESCE(v_current_score, 0), v_new_score, 'assessment', p_assessment_id);
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION update_student_skills_from_course(
  p_student_id UUID,
  p_course_id UUID,
  p_final_score NUMERIC
)
RETURNS VOID AS $$
DECLARE
  v_skill RECORD;
BEGIN
  FOR v_skill IN 
    SELECT skill_name, skill_category, weightage 
    FROM course_skill_mapping 
    WHERE course_id = p_course_id
  LOOP
    INSERT INTO student_skill_scores (student_id, skill_name, skill_category, current_score, assessment_count, acquired_from_courses)
    VALUES (
      p_student_id, 
      v_skill.skill_name, 
      v_skill.skill_category, 
      p_final_score * v_skill.weightage,
      1,
      ARRAY[p_course_id::TEXT]
    )
    ON CONFLICT (student_id, skill_name) 
    DO UPDATE SET
      current_score = (student_skill_scores.current_score + (p_final_score * v_skill.weightage)) / 2,
      assessment_count = student_skill_scores.assessment_count + 1,
      acquired_from_courses = array_append(student_skill_scores.acquired_from_courses, p_course_id::TEXT),
      last_updated = NOW();
      
    -- Record history
    INSERT INTO student_skill_history (student_id, skill_name, score_change, new_score, source_type, source_id)
    VALUES (p_student_id, v_skill.skill_name, p_final_score, p_final_score, 'course_completion', p_course_id);
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- STEP 7: CREATE TRIGGERS
-- ============================================

-- Auto-update course completion when final exam is passed
CREATE OR REPLACE FUNCTION check_course_completion()
RETURNS TRIGGER AS $$
DECLARE
  v_is_final_exam BOOLEAN;
  v_course_id UUID;
  v_passing_score NUMERIC;
BEGIN
  -- Check if this is a final exam (assessment with 'Final Exam' in title)
  SELECT 
    a.title ILIKE '%final%exam%' OR a.title ILIKE '%final%assessment%',
    s.course_id
  INTO v_is_final_exam, v_course_id
  FROM learning_course_assessments a
  JOIN learning_course_sections s ON a.section_id = s.id
  WHERE a.id = NEW.assessment_id;
  
  IF v_is_final_exam AND NEW.is_passed THEN
    -- Mark course as completed
    UPDATE student_course_enrollments
    SET progress_percent = 100
    WHERE student_id = NEW.student_id AND course_id = v_course_id;
    
    -- Generate certificate
    PERFORM generate_course_certificate(NEW.student_id, v_course_id, NEW.score);
  END IF;
  
  -- Update skill scores
  IF NEW.score IS NOT NULL THEN
    PERFORM update_student_skills_from_assessment(NEW.student_id, NEW.assessment_id, NEW.score);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_assessment_submission
  AFTER INSERT OR UPDATE ON student_assessment_submissions
  FOR EACH ROW
  WHEN (NEW.score IS NOT NULL)
  EXECUTE FUNCTION check_course_completion();

-- ============================================
-- DONE!
-- ============================================
