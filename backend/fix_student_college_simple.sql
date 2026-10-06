-- =====================================================
-- SIMPLE STUDENT COLLEGE LINKING FIX
-- =====================================================
-- This script helps link students to colleges manually

-- 1. First, let's see what colleges exist
SELECT 
    id,
    name,
    email,
    allowed_emails_domain,
    type
FROM organizations 
WHERE type IN ('college', 'university', 'institute')
ORDER BY name;

-- 2. See what students need to be linked
SELECT 
    id,
    email,
    full_name,
    organization_id,
    role
FROM profiles 
WHERE role = 'student' 
AND organization_id IS NULL
ORDER BY email;

-- 3. Try automatic linking based on email domain (if colleges have domain set)
UPDATE profiles 
SET organization_id = (
    SELECT o.id 
    FROM organizations o 
    WHERE o.allowed_emails_domain IS NOT NULL 
    AND profiles.email LIKE '%@' || o.allowed_emails_domain
    LIMIT 1
)
WHERE role = 'student' 
AND organization_id IS NULL
AND EXISTS (
    SELECT 1 
    FROM organizations o 
    WHERE o.allowed_emails_domain IS NOT NULL 
    AND profiles.email LIKE '%@' || o.allowed_emails_domain
);

-- 4. Show results after automatic linking
SELECT 
    'After automatic linking:' as status,
    COUNT(*) as students_still_unlinked
FROM profiles 
WHERE role = 'student' AND organization_id IS NULL;

-- 5. Manual linking examples (uncomment and modify as needed)
-- Replace 'college-id-here' with actual college ID from step 1
-- Replace 'student-email-here' with actual student email from step 2

-- Example: Link student to a specific college
-- UPDATE profiles 
-- SET organization_id = 'college-id-here'
-- WHERE email = 'student-email-here' AND role = 'student';

-- Example: Link all students with specific email domain to a college
-- UPDATE profiles 
-- SET organization_id = 'college-id-here'
-- WHERE email LIKE '%@yourdomain.com' AND role = 'student' AND organization_id IS NULL;

-- 6. Final status check
SELECT 
    p.email,
    p.full_name,
    CASE 
        WHEN p.organization_id IS NOT NULL THEN o.name 
        ELSE 'NEEDS MANUAL LINKING' 
    END as college_status,
    p.organization_id
FROM profiles p 
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student'
ORDER BY p.organization_id IS NULL DESC, p.email;

SELECT 'Student college linking check completed!' as status;