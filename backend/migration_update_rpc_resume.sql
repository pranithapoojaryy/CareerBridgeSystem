CREATE OR REPLACE FUNCTION get_college_students_v2(
  p_org_id UUID,
  p_search_query TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  full_name TEXT,
  email TEXT,
  phone TEXT,
  is_verified BOOLEAN,
  organization_id UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  student_profiles JSONB,
  program JSONB,
  department JSONB,
  batch JSONB,
  skills JSONB,
  organizations JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.full_name,
    p.email,
    COALESCE(sp.phone, p.phone) as phone,
    p.is_verified,
    p.organization_id,
    p.created_at,
    p.updated_at,
    jsonb_build_object(
      'usn', sp.usn,
      'phone', sp.phone,
      'cgpa', sp.cgpa,
      'placement_status', sp.placement_status,
      'resume_url', sp.resume_url
    ) as student_profiles,
    CASE WHEN cp.id IS NOT NULL THEN jsonb_build_object('name', cp.name) ELSE NULL END as program,
    CASE WHEN cd.id IS NOT NULL THEN jsonb_build_object('name', cd.name) ELSE NULL END as department,
    CASE WHEN cb.id IS NOT NULL THEN jsonb_build_object('start_year', cb.start_year, 'end_year', cb.end_year) ELSE NULL END as batch,
    COALESCE(
      (
        SELECT jsonb_agg(sd.name)
        FROM student_skills ss
        JOIN skills_database sd ON ss.skill_id = sd.id
        WHERE ss.student_id = p.id
      ),
      '[]'::jsonb
    ) as skills,
    jsonb_build_object(
      'id', o.id,
      'name', o.name,
      'short_code', o.short_code
    ) as organizations
  FROM public.profiles p
  LEFT JOIN public.student_profiles sp ON p.id = sp.id
  LEFT JOIN public.organizations o ON p.organization_id = o.id
  LEFT JOIN public.college_programs cp ON sp.program_id = cp.id
  LEFT JOIN public.college_departments cd ON sp.department_id = cd.id
  LEFT JOIN public.college_batches cb ON sp.batch_id = cb.id
  WHERE p.organization_id = p_org_id
  AND p.role = 'student'
  AND (
    p_search_query IS NULL OR
    p.full_name ILIKE '%' || p_search_query || '%' OR
    p.email ILIKE '%' || p_search_query || '%' OR
    sp.usn ILIKE '%' || p_search_query || '%'
  )
  ORDER BY p.created_at DESC;
END;
$$;
