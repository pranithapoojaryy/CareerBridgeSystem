-- Fix inconsistent assignment types caused by frontend bug
-- where 'department' assignments were saved as 'batch' type but with null batch_id.

BEGIN;

UPDATE public.test_assignments
SET assignment_type = 'department'
WHERE assignment_type = 'batch'
  AND assigned_to_batch IS NULL
  AND assigned_to_department IS NOT NULL;

-- Also ensure 'all_students' type is consistent if any were saved incorrectly (though logic seemed to default to batch there too if not careful)
-- The previous bug had: _targetAudience == 'all' ? 'all_students' : 'batch'. Use logic: All -> All. But Department -> Batch. 
-- So 'All' should have been saved correctly as 'all_students'.
-- 'Department' was saved as 'batch'.

-- Verification
SELECT 
    id, 
    assignment_type, 
    assigned_to_batch, 
    assigned_to_department 
FROM public.test_assignments 
WHERE assignment_type = 'batch' AND assigned_to_batch IS NULL;

COMMIT;
