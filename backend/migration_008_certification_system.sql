-- =====================================================
-- CERTIFICATION VALIDATION SYSTEM
-- =====================================================
-- Smart system to validate certificates and update skills

-- 1. Certification Providers Table
CREATE TABLE IF NOT EXISTS certification_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    short_code VARCHAR(50) NOT NULL UNIQUE,
    website_url TEXT,
    api_endpoint TEXT,
    validation_method VARCHAR(50) NOT NULL, -- 'api', 'ocr', 'manual', 'pattern'
    trust_score INTEGER DEFAULT 100, -- 0-100 trust rating
    logo_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Insert major certification providers
INSERT INTO certification_providers (name, short_code, website_url, validation_method, trust_score) VALUES
('NPTEL', 'NPTEL', 'https://nptel.ac.in', 'api', 95),
('SWAYAM', 'SWAYAM', 'https://swayam.gov.in', 'api', 95),
('Coursera', 'COURSERA', 'https://coursera.org', 'api', 90),
('Udemy', 'UDEMY', 'https://udemy.com', 'pattern', 85),
('edX', 'EDX', 'https://edx.org', 'api', 90),
('LinkedIn Learning', 'LINKEDIN', 'https://linkedin.com/learning', 'api', 85),
('Google Cloud', 'GCP', 'https://cloud.google.com', 'api', 95),
('AWS', 'AWS', 'https://aws.amazon.com', 'api', 95),
('Microsoft Azure', 'AZURE', 'https://azure.microsoft.com', 'api', 95),
('Cisco', 'CISCO', 'https://cisco.com', 'api', 90),
('Oracle', 'ORACLE', 'https://oracle.com', 'api', 90),
('IBM', 'IBM', 'https://ibm.com', 'api', 90),
('Salesforce', 'SALESFORCE', 'https://salesforce.com', 'api', 90),
('HackerRank', 'HACKERRANK', 'https://hackerrank.com', 'api', 80),
('Codecademy', 'CODECADEMY', 'https://codecademy.com', 'pattern', 75),
('FreeCodeCamp', 'FREECODECAMP', 'https://freecodecamp.org', 'pattern', 80);

-- 2. Skills Database
CREATE TABLE IF NOT EXISTS skills_database (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL, -- 'programming', 'cloud', 'data', 'design', etc.
    subcategory VARCHAR(100),
    difficulty_level VARCHAR(20) DEFAULT 'beginner', -- 'beginner', 'intermediate', 'advanced', 'expert'
    market_demand INTEGER DEFAULT 50, -- 1-100 market demand score
    base_points INTEGER DEFAULT 10, -- Base points for this skill
    keywords TEXT[], -- Array of keywords for matching
    related_skills UUID[], -- Array of related skill IDs
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Insert common skills
INSERT INTO skills_database (name, category, subcategory, difficulty_level, market_demand, base_points, keywords) VALUES
-- Programming Languages
('Python', 'programming', 'languages', 'beginner', 95, 15, ARRAY['python', 'py', 'django', 'flask']),
('Java', 'programming', 'languages', 'intermediate', 90, 15, ARRAY['java', 'spring', 'springboot']),
('JavaScript', 'programming', 'languages', 'beginner', 95, 15, ARRAY['javascript', 'js', 'node', 'react', 'vue']),
('C++', 'programming', 'languages', 'intermediate', 80, 12, ARRAY['cpp', 'c++', 'c plus plus']),
('C', 'programming', 'languages', 'intermediate', 75, 12, ARRAY['c programming', 'c language']),
('Go', 'programming', 'languages', 'intermediate', 85, 18, ARRAY['golang', 'go lang']),
('Rust', 'programming', 'languages', 'advanced', 80, 20, ARRAY['rust lang', 'rust programming']),

-- Web Technologies
('React', 'web', 'frontend', 'intermediate', 95, 18, ARRAY['react', 'reactjs', 'react.js']),
('Angular', 'web', 'frontend', 'intermediate', 85, 18, ARRAY['angular', 'angularjs']),
('Vue.js', 'web', 'frontend', 'intermediate', 80, 16, ARRAY['vue', 'vuejs', 'vue.js']),
('Node.js', 'web', 'backend', 'intermediate', 90, 18, ARRAY['node', 'nodejs', 'node.js']),
('Express.js', 'web', 'backend', 'intermediate', 85, 15, ARRAY['express', 'expressjs']),

-- Cloud Platforms
('AWS', 'cloud', 'platform', 'intermediate', 95, 25, ARRAY['amazon web services', 'aws', 'ec2', 's3']),
('Google Cloud', 'cloud', 'platform', 'intermediate', 90, 25, ARRAY['gcp', 'google cloud platform']),
('Microsoft Azure', 'cloud', 'platform', 'intermediate', 90, 25, ARRAY['azure', 'microsoft azure']),
('Docker', 'cloud', 'containerization', 'intermediate', 90, 20, ARRAY['docker', 'containerization']),
('Kubernetes', 'cloud', 'orchestration', 'advanced', 95, 25, ARRAY['kubernetes', 'k8s']),

-- Data Science & AI
('Machine Learning', 'data', 'ml', 'intermediate', 95, 25, ARRAY['machine learning', 'ml', 'scikit-learn']),
('Deep Learning', 'data', 'ai', 'advanced', 90, 30, ARRAY['deep learning', 'neural networks', 'tensorflow', 'pytorch']),
('Data Analysis', 'data', 'analysis', 'beginner', 85, 15, ARRAY['data analysis', 'pandas', 'numpy']),
('SQL', 'data', 'database', 'beginner', 90, 12, ARRAY['sql', 'mysql', 'postgresql', 'database']),
('MongoDB', 'data', 'database', 'intermediate', 80, 15, ARRAY['mongodb', 'nosql']),

-- Design & UI/UX
('UI/UX Design', 'design', 'user_experience', 'intermediate', 85, 18, ARRAY['ui', 'ux', 'user interface', 'user experience']),
('Figma', 'design', 'tools', 'beginner', 80, 12, ARRAY['figma', 'design tool']),
('Adobe Photoshop', 'design', 'graphics', 'intermediate', 75, 15, ARRAY['photoshop', 'adobe photoshop']);

-- 3. Student Certifications Table
CREATE TABLE IF NOT EXISTS student_certifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES certification_providers(id),
    
    -- Certificate Details
    certificate_name VARCHAR(500) NOT NULL,
    certificate_id VARCHAR(255), -- Certificate ID from provider
    certificate_url TEXT, -- Verification URL
    issue_date DATE,
    expiry_date DATE,
    
    -- File Upload
    certificate_file_url TEXT, -- Uploaded certificate image/PDF
    
    -- Validation Status
    validation_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'validated', 'rejected', 'expired'
    validation_method VARCHAR(50), -- How it was validated
    validation_score INTEGER DEFAULT 0, -- 0-100 confidence score
    validation_details JSONB, -- Detailed validation results
    validated_at TIMESTAMP WITH TIME ZONE,
    validated_by UUID, -- Admin who validated (if manual)
    
    -- Skills Extracted
    extracted_skills JSONB, -- Skills identified from certificate
    skill_points_awarded INTEGER DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    UNIQUE(student_id, certificate_id, provider_id)
);

-- 4. Student Skills Table (Updated)
CREATE TABLE IF NOT EXISTS student_skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES skills_database(id),
    
    -- Skill Level & Points
    proficiency_level VARCHAR(20) DEFAULT 'beginner', -- 'beginner', 'intermediate', 'advanced', 'expert'
    total_points INTEGER DEFAULT 0,
    certification_points INTEGER DEFAULT 0, -- Points from certifications
    project_points INTEGER DEFAULT 0, -- Points from projects
    assessment_points INTEGER DEFAULT 0, -- Points from assessments
    
    -- Verification
    is_verified BOOLEAN DEFAULT false,
    verification_source VARCHAR(100), -- 'certification', 'assessment', 'project', 'manual'
    
    -- Metadata
    first_acquired DATE DEFAULT CURRENT_DATE,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    UNIQUE(student_id, skill_id)
);

-- 5. Certification Validation Rules
CREATE TABLE IF NOT EXISTS validation_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID REFERENCES certification_providers(id),
    
    -- Pattern Matching Rules
    certificate_name_patterns TEXT[], -- Regex patterns for certificate names
    certificate_id_patterns TEXT[], -- Regex patterns for certificate IDs
    url_patterns TEXT[], -- URL patterns for validation
    
    -- OCR Rules
    required_text_elements TEXT[], -- Text that must be present
    forbidden_text_elements TEXT[], -- Text that indicates fake certificate
    
    -- Skill Mapping
    skill_keywords JSONB, -- Map keywords to skills
    default_points INTEGER DEFAULT 10,
    
    -- Validation Settings
    auto_approve_threshold INTEGER DEFAULT 80, -- Auto-approve if confidence > threshold
    manual_review_threshold INTEGER DEFAULT 50, -- Require manual review if confidence < threshold
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 6. Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_student_certifications_student_id ON student_certifications(student_id);
CREATE INDEX IF NOT EXISTS idx_student_certifications_status ON student_certifications(validation_status);
CREATE INDEX IF NOT EXISTS idx_student_skills_student_id ON student_skills(student_id);
CREATE INDEX IF NOT EXISTS idx_student_skills_skill_id ON student_skills(skill_id);
CREATE INDEX IF NOT EXISTS idx_skills_database_category ON skills_database(category);
CREATE INDEX IF NOT EXISTS idx_skills_database_keywords ON skills_database USING GIN(keywords);

-- 7. RLS Policies
ALTER TABLE student_certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_skills ENABLE ROW LEVEL SECURITY;

-- Students can only see their own certifications and skills
CREATE POLICY "Students can view own certifications" ON student_certifications
    FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Students can insert own certifications" ON student_certifications
    FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Students can update own certifications" ON student_certifications
    FOR UPDATE USING (auth.uid() = student_id);

CREATE POLICY "Students can view own skills" ON student_skills
    FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Students can manage own skills" ON student_skills
    FOR ALL USING (auth.uid() = student_id);

-- Colleges can view their students' certifications and skills
CREATE POLICY "Colleges can view student certifications" ON student_certifications
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles p 
            WHERE p.id = student_id 
            AND p.organization_id IN (
                SELECT o.id FROM organizations o 
                WHERE o.created_by = auth.uid()
            )
        )
    );

CREATE POLICY "Colleges can view student skills" ON student_skills
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles p 
            WHERE p.id = student_id 
            AND p.organization_id IN (
                SELECT o.id FROM organizations o 
                WHERE o.created_by = auth.uid()
            )
        )
    );

-- Public read access for reference tables
ALTER TABLE certification_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE skills_database ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read certification_providers" ON certification_providers FOR SELECT USING (true);
CREATE POLICY "Public read skills_database" ON skills_database FOR SELECT USING (true);
CREATE POLICY "Public read validation_rules" ON validation_rules FOR SELECT USING (true);

-- 8. Functions for Skill Point Calculation
CREATE OR REPLACE FUNCTION calculate_skill_points(
    skill_name TEXT,
    certificate_name TEXT,
    provider_trust_score INTEGER
) RETURNS INTEGER AS $$
DECLARE
    base_points INTEGER;
    multiplier DECIMAL;
    final_points INTEGER;
BEGIN
    -- Get base points for skill
    SELECT s.base_points INTO base_points
    FROM skills_database s
    WHERE s.name ILIKE skill_name
    LIMIT 1;
    
    IF base_points IS NULL THEN
        base_points := 10; -- Default points
    END IF;
    
    -- Calculate multiplier based on provider trust and certificate type
    multiplier := (provider_trust_score / 100.0);
    
    -- Bonus for advanced/professional certificates
    IF certificate_name ILIKE '%advanced%' OR certificate_name ILIKE '%professional%' THEN
        multiplier := multiplier * 1.5;
    ELSIF certificate_name ILIKE '%intermediate%' THEN
        multiplier := multiplier * 1.2;
    END IF;
    
    final_points := ROUND(base_points * multiplier);
    
    RETURN GREATEST(final_points, 1); -- Minimum 1 point
END;
$$ LANGUAGE plpgsql;

-- 9. Trigger to Update Student Skills
CREATE OR REPLACE FUNCTION update_student_skills_from_certification()
RETURNS TRIGGER AS $$
DECLARE
    skill_record RECORD;
    points_to_add INTEGER;
BEGIN
    -- Only process validated certifications
    IF NEW.validation_status = 'validated' AND (OLD.validation_status IS NULL OR OLD.validation_status != 'validated') THEN
        
        -- Process each extracted skill
        FOR skill_record IN 
            SELECT key as skill_name, value::INTEGER as confidence
            FROM jsonb_each_text(NEW.extracted_skills)
        LOOP
            -- Calculate points for this skill
            SELECT calculate_skill_points(
                skill_record.skill_name,
                NEW.certificate_name,
                COALESCE((SELECT trust_score FROM certification_providers WHERE id = NEW.provider_id), 80)
            ) INTO points_to_add;
            
            -- Insert or update student skill
            INSERT INTO student_skills (
                student_id,
                skill_id,
                certification_points,
                total_points,
                is_verified,
                verification_source,
                proficiency_level
            )
            SELECT 
                NEW.student_id,
                s.id,
                points_to_add,
                points_to_add,
                true,
                'certification',
                CASE 
                    WHEN points_to_add >= 50 THEN 'advanced'
                    WHEN points_to_add >= 25 THEN 'intermediate'
                    ELSE 'beginner'
                END
            FROM skills_database s
            WHERE s.name ILIKE skill_record.skill_name
            LIMIT 1
            ON CONFLICT (student_id, skill_id) DO UPDATE SET
                certification_points = student_skills.certification_points + points_to_add,
                total_points = student_skills.total_points + points_to_add,
                is_verified = true,
                verification_source = 'certification',
                proficiency_level = CASE 
                    WHEN student_skills.total_points + points_to_add >= 100 THEN 'expert'
                    WHEN student_skills.total_points + points_to_add >= 50 THEN 'advanced'
                    WHEN student_skills.total_points + points_to_add >= 25 THEN 'intermediate'
                    ELSE 'beginner'
                END,
                last_updated = now();
        END LOOP;
        
        -- Update certification with points awarded
        UPDATE student_certifications 
        SET skill_points_awarded = (
            SELECT COALESCE(SUM(value::INTEGER), 0)
            FROM jsonb_each_text(NEW.extracted_skills)
        )
        WHERE id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_student_skills
    AFTER INSERT OR UPDATE ON student_certifications
    FOR EACH ROW
    EXECUTE FUNCTION update_student_skills_from_certification();

-- 10. Storage for Certificate Files
INSERT INTO storage.buckets (id, name, public) VALUES ('certificates', 'certificates', false);

-- RLS for certificate storage
CREATE POLICY "Students can upload certificates" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'certificates' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Students can view own certificates" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'certificates' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Colleges can view student certificates" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'certificates' AND
        EXISTS (
            SELECT 1 FROM profiles p 
            WHERE p.id::text = (storage.foldername(name))[1]
            AND p.organization_id IN (
                SELECT o.id FROM organizations o 
                WHERE o.created_by = auth.uid()
            )
        )
    );

SELECT '🎉 Certification validation system created successfully!' as result;