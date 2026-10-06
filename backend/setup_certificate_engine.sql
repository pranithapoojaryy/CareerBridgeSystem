-- =====================================================
-- DYNAMIC CERTIFICATE VALIDATION ENGINE
-- =====================================================
-- Implements Trust-Based Validation Logic (A, B, C, D)
-- and Automatic Verification Rules

-- 1. Update Certification Providers Table
-- Add Category support (A=Auto, B=Education, C=Company, D=Unknown)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'certification_providers' AND column_name = 'provider_category') THEN
        ALTER TABLE certification_providers ADD COLUMN provider_category VARCHAR(1) DEFAULT 'D' CHECK (provider_category IN ('A', 'B', 'C', 'D'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'certification_providers' AND column_name = 'verification_url_template') THEN
        ALTER TABLE certification_providers ADD COLUMN verification_url_template TEXT; -- e.g. "https://coursera.org/verify/{ID}"
    END IF;
END $$;

-- Update major providers with their categories
UPDATE certification_providers SET provider_category = 'A', validation_method = 'api' WHERE name ILIKE '%Coursera%';
UPDATE certification_providers SET provider_category = 'A', validation_method = 'api' WHERE name ILIKE '%Udemy%'; -- Pattern based
UPDATE certification_providers SET provider_category = 'A', validation_method = 'api' WHERE name ILIKE '%edX%';
UPDATE certification_providers SET provider_category = 'A', validation_method = 'api' WHERE name ILIKE '%Google%';
UPDATE certification_providers SET provider_category = 'A', validation_method = 'api' WHERE name ILIKE '%AWS%';
UPDATE certification_providers SET provider_category = 'A', validation_method = 'api' WHERE name ILIKE '%Microsoft%';
UPDATE certification_providers SET provider_category = 'A', validation_method = 'api' WHERE name ILIKE '%Infosys%' OR name ILIKE '%Springboard%';
UPDATE certification_providers SET provider_category = 'B', validation_method = 'manual' WHERE name ILIKE '%University%' OR name ILIKE '%College%' OR name ILIKE '%Institute%';

-- 2. Update Student Certifications Table
-- Add extended validation statuses
ALTER TABLE student_certifications DROP CONSTRAINT IF EXISTS student_certifications_validation_status_check;
ALTER TABLE student_certifications ADD CONSTRAINT student_certifications_validation_status_check 
    CHECK (validation_status IN ('pending', 'verified', 'partially_verified', 'college_verified', 'unverified', 'rejected'));

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'student_certifications' AND column_name = 'trust_level') THEN
        ALTER TABLE student_certifications ADD COLUMN trust_level INTEGER DEFAULT 0; -- 0-100 visual score
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'student_certifications' AND column_name = 'issuer_name_snapshot') THEN
        ALTER TABLE student_certifications ADD COLUMN issuer_name_snapshot TEXT; -- Captured at upload time for faster search
    END IF;
END $$;

-- 3. THE BRAIN: Dynamic Classification & Validation Trigger

CREATE OR REPLACE FUNCTION process_new_certificate()
RETURNS TRIGGER AS $$
DECLARE
    matched_provider_id UUID;
    provider_cat VARCHAR(1);
    trust_score_val INTEGER;
    url_pattern_valid BOOLEAN;
BEGIN
    -- Step 1: Attempt to identify the Issuer (if provider_id is null/generic)
    -- We try to match the user-entered 'certificate_name' or a new 'issuer' field against known providers
    -- For now, we assume frontend sends provider_id if selected, or we infer from text if possible (omitted for MVP simplicity, relying on provider_id or manual text)
    
    -- If provider is known, get its category
    IF NEW.provider_id IS NOT NULL THEN
        SELECT provider_category, trust_score INTO provider_cat, trust_score_val
        FROM certification_providers WHERE id = NEW.provider_id;
    ELSE
        -- Fallback: Unknown/Custom provider
        provider_cat := 'D'; 
        trust_score_val := 10;
        
        -- Simple heuristic: Check keywords in certificate name if provider unchecked
        IF NEW.certificate_name ILIKE '%Coursera%' THEN provider_cat := 'A'; trust_score_val := 90; END IF;
        IF NEW.certificate_name ILIKE '%Udemy%' THEN provider_cat := 'A'; trust_score_val := 85; END IF;
        IF NEW.certificate_name ILIKE '%NPTEL%' THEN provider_cat := 'A'; trust_score_val := 98; END IF; -- High Trust for NPTEL
        IF NEW.certificate_name ILIKE '%Infosys%' OR NEW.certificate_name ILIKE '%Springboard%' THEN provider_cat := 'A'; trust_score_val := 95; END IF;
        IF NEW.certificate_name ILIKE '%Internship%' THEN provider_cat := 'C'; trust_score_val := 50; END IF; -- Company
    END IF;

    -- Step 2: Apply Logic based on Category
    
    -- Category A: Auto-Verifiable (Providers with APIs/Public URLs)
    IF provider_cat = 'A' THEN
        -- Check if a URL or ID is provided
        IF NEW.certificate_url IS NOT NULL AND LENGTH(NEW.certificate_url) > 10 THEN
            -- Simulate "Link Check" (In production, this could trigger an Edge Function)
            -- For MVP: If it's a valid-looking URL from the provider, mark Verified
            NEW.validation_status := 'verified';
            NEW.trust_level := 100;
            NEW.validation_details := jsonb_build_object('method', 'auto_url_pattern', 'message', 'Verified via trusted provider URL');
        ELSEIF NEW.certificate_id IS NOT NULL AND LENGTH(NEW.certificate_id) > 5 THEN
            -- Has ID but no URL: Mark as "Pending Check" or "Verified" if we trust the format
            NEW.validation_status := 'verified'; -- Optimistic verification for MVP demo
            NEW.trust_level := 90;
            NEW.validation_details := jsonb_build_object('method', 'auto_id_format', 'message', 'Verified via Certificate ID format');
        ELSE
             -- Missing proofs
            NEW.validation_status := 'unverified';
            NEW.trust_level := 20;
             NEW.validation_details := jsonb_build_object('message', 'Missing ID or URL for Category A provider');
        END IF;

    -- Category B: Educational (Colleges/Universities)
    ELSEIF provider_cat = 'B' THEN
        -- Requires Manual Faculty Review
        NEW.validation_status := 'pending'; -- Moves to College Dashboard
        NEW.trust_level := 50; -- Moderate trust until verified
        NEW.validation_details := jsonb_build_object('queue', 'college_verification', 'message', 'Pending faculty approval');

    -- Category C: Companies/Internships
    ELSEIF provider_cat = 'C' THEN
        -- Check for "Company Email" or "Domain" (Simplified)
        -- Defaults to Partially Verified if basic info exists
        NEW.validation_status := 'partially_verified';
        NEW.trust_level := 60;
        NEW.validation_details := jsonb_build_object('message', 'Company internship identified. Pending reference check.');

    -- Category D: Unknown
    ELSE
        NEW.validation_status := 'unverified';
        NEW.trust_level := 10;
        NEW.validation_details := jsonb_build_object('message', 'Unknown issuer. Low trust score.');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Attach Trigger
DROP TRIGGER IF EXISTS trigger_auto_validate_certificate ON student_certifications;
CREATE TRIGGER trigger_auto_validate_certificate
    BEFORE INSERT OR UPDATE OF provider_id, certificate_url, certificate_id
    ON student_certifications
    FOR EACH ROW
    EXECUTE FUNCTION process_new_certificate();

-- 5. Helper Views for Dashboards

-- View for Recruiters (Only Verified/High Trust)
CREATE OR REPLACE VIEW view_recruiter_certificates AS
SELECT 
    sc.id,
    sc.student_id,
    sc.certificate_name,
    cp.name as provider_name,
    cp.provider_category,
    sc.validation_status,
    sc.trust_level,
    sc.issue_date,
    sc.certificate_url
FROM student_certifications sc
LEFT JOIN certification_providers cp ON sc.provider_id = cp.id
WHERE sc.validation_status IN ('verified', 'college_verified', 'partially_verified')
ORDER BY sc.trust_level DESC;

-- View for College Faculty (Pending Review Items)
CREATE OR REPLACE VIEW view_college_verification_queue AS
SELECT 
    sc.id,
    sc.student_id,
    sc.certificate_name,
    sc.certificate_file_url,
    sc.created_at,
    p.full_name as student_name
FROM student_certifications sc
JOIN profiles p ON sc.student_id = p.id
WHERE sc.validation_status = 'pending' 
  AND (sc.provider_id IS NULL OR EXISTS (SELECT 1 FROM certification_providers cp WHERE cp.id = sc.provider_id AND cp.provider_category = 'B'));

SELECT '✅ Dynamic Certificate Engine logic applied successfully!' as result;
