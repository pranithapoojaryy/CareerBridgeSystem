-- Check for 'selected' or 'hired' applications
SELECT 
    ja.id, 
    ja.status, 
    ja.created_at, 
    p.full_name, 
    p.organization_id 
FROM job_applications ja
JOIN profiles p ON ja.student_id = p.id
WHERE ja.status IN ('selected', 'hired')
ORDER BY ja.created_at DESC
LIMIT 10;

-- Check total count for a specific org (if known, otherwise list top orgs)
SELECT 
    p.organization_id, 
    COUNT(*) as selected_count 
FROM job_applications ja
JOIN profiles p ON ja.student_id = p.id
WHERE ja.status IN ('selected', 'hired')
GROUP BY p.organization_id;
