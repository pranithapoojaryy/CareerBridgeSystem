-- Legacy Fix: Convert Name-based Reference to UUIDs in test_assignments
-- This fixes assessments that were hidden from students because RLS expects UUIDs.

BEGIN;

-- 1. Fix Departments: Update 'assigned_to_department' from Name to UUID
-- Matches against college_departments table
UPDATE public.test_assignments ta
SET assigned_to_department = cd.id::text
FROM public.college_departments cd
WHERE ta.assigned_to_department = cd.name
  AND ta.assigned_to_department IS NOT NULL
  -- Regex to check if it's NOT a UUID (simple check for lack of hyphens or length)
  AND length(ta.assigned_to_department) < 36; 

-- 2. Fix Batches: Update 'assigned_to_batch' from Name to UUID
-- Matches against college_batches table
UPDATE public.test_assignments ta
SET assigned_to_batch = cb.id::text
FROM public.college_batches cb
WHERE ta.assigned_to_batch = cb.name
  AND ta.assigned_to_batch IS NOT NULL
  AND length(ta.assigned_to_batch) < 36;

COMMIT;

-- Verification
SELECT id, assignment_type, assigned_to_department, assigned_to_batch 
FROM public.test_assignments 
WHERE created_at > now() - interval '1 day';
