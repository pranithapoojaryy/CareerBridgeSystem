-- Allow Authenticated uploads to interview-videos bucket
insert into storage.buckets (id, name, public)
values ('interview-videos', 'interview-videos', false)
on conflict (id) do nothing;

create policy "Authenticated can upload videos"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'interview-videos' );

create policy "Authenticated can view their own videos"
on storage.objects for select
to authenticated
using ( bucket_id = 'interview-videos' );

create policy "Authenticated can update videos"
on storage.objects for update
to authenticated
using ( bucket_id = 'interview-videos' );

-- Ensure mock_attempts is updateable by the student who owns it
create policy "Students can update their own mock attempts"
on public.mock_attempts for update
to authenticated
using ( student_id = auth.uid() )
with check ( student_id = auth.uid() );
