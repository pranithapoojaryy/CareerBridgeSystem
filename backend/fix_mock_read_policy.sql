-- Allow any authenticated user (Faculty/Student) to READ mock_attempts
-- This is required for the College Analytics to see Student scores.

create policy "Authenticated can read all mock attempts"
on public.mock_attempts for select
to authenticated
using ( true );

-- Also ensure student_interviews are readable (usually they are, but just in case)
-- (Existing policies might already cover this, but this is a safe fallback for MVP)
create policy "Authenticated can read all student interviews"
on public.student_interviews for select
to authenticated
using ( true );
