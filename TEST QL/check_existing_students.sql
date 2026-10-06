-- CHECK EXISTING USERS AND ROLES
-- The user says "There is 1 student already". Let's verify.
-- Count users in this organization by role.

SELECT 
    id, 
    full_name, 
    email, 
    role, 
    organization_id 
FROM profiles 
WHERE organization_id = 'eb302e28-12cf-4737-87f6-f69bff28f865';

-- Also check specifically for ANY active students
SELECT COUNT(*) as actual_student_count 
FROM profiles 
WHERE organization_id = 'eb302e28-12cf-4737-87f6-f69bff28f865' 
AND role = 'student';
