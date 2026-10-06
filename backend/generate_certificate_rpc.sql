-- Create a function to generate a certificate for a student
create or replace function public.generate_certificate_for_student(
  p_student_id uuid,
  p_course_id uuid
) returns boolean
language plpgsql
security definer
as $$
declare
  v_certificate_id uuid;
begin
  -- Check if certificate already exists
  select id into v_certificate_id
  from public.student_certifications
  where student_id = p_student_id
  and course_id = p_course_id;

  if v_certificate_id is not null then
    return true; -- Certificate already exists
  end if;

  -- Insert new certificate
  insert into public.student_certifications (
    student_id,
    course_id,
    issue_date,
    validation_status,
    certificate_url -- Potentially null initially or generated via another process
  ) values (
    p_student_id,
    p_course_id,
    now(),
    'verified', -- Auto-verified since triggered by system logic
    null
  );

  return true;
exception
  when others then
    return false;
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function public.generate_certificate_for_student(uuid, uuid) to authenticated;
