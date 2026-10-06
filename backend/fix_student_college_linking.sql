-- =====================================================
-- FIX STUDENT COLLEGE LINKING
-- =====================================================
-- This script links students to their colleges based on email domain

-- First, let's see what students don't have organization_id set
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.organization_id,
    p.role
FROM profiles p 
WHERE p.role = 'student' 
AND p.organization_id IS NULL;

-- Update students to link them to colleges based on email domain
-- This will match students with colleges that have matching email domains

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

-- Show results after update
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.organization_id,
    o.name as college_name,
    o.allowed_emails_domain
FROM profiles p 
LEFT JOIN organizations o ON p.organization_id = o.id
WHERE p.role = 'student'
ORDER BY p.organization_id IS NULL DESC, p.email;

-- If no automatic matching worked, you can manually link students
-- Example: Link a specific student to a specific college
-- UPDATE profiles 
-- SET organization_id = 'your-college-id-here'
-- WHERE id = 'student-user-id-here';

SELECT 'Student college linking completed!' as status;