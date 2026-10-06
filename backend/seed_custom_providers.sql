-- =====================================================
-- SEED CUSTOM PROVIDERS & SCHEMA UPDATE
-- =====================================================

-- 1. Ensure issuer_name_snapshot column exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'student_certifications' AND column_name = 'issuer_name_snapshot') THEN
        ALTER TABLE student_certifications ADD COLUMN issuer_name_snapshot TEXT;
    END IF;
END $$;

-- 2. Insert "CareerBridge" as a Trusted Provider (if not exists)
INSERT INTO certification_providers (name, short_code, website_url, validation_method, trust_score, provider_category, is_active)
SELECT 'CareerBridge', 'CareerBridge', 'https://CareerBridge.com', 'api', 100, 'A', true
WHERE NOT EXISTS (SELECT 1 FROM certification_providers WHERE short_code = 'CareerBridge');

-- 3. Insert "Other / Not Listed" Provider (if not exists)
-- We use a special short_code 'OTHER'
INSERT INTO certification_providers (name, short_code, website_url, validation_method, trust_score, provider_category, is_active)
SELECT 'Other / Not Listed', 'OTHER', NULL, 'manual', 10, 'D', true
WHERE NOT EXISTS (SELECT 1 FROM certification_providers WHERE short_code = 'OTHER');

SELECT '✅ Custom providers seeded successfully!' as result;
