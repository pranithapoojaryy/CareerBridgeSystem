-- Create the storage bucket for organization assets (logos, banners)
insert into storage.buckets (id, name, public) 
values ('organization_assets', 'organization_assets', true)
ON CONFLICT (id) DO NOTHING;

-- Policy: Allow public read access to all files in this bucket
create policy "Public Access"
  on storage.objects for select
  using ( bucket_id = 'organization_assets' );

-- Policy: Allow authenticated users to upload files
-- In a real app, you might want to restrict this further to only allow users to upload to their own folder (e.g., folder name = user_id or org_id)
create policy "Authenticated Upload"
  on storage.objects for insert
  to authenticated
  with check ( bucket_id = 'organization_assets' );

-- Policy: Allow users to update/delete their own files (Implementation dependent on folder structure)
-- For now, we trust authenticated users for the demo, or we can enforce folder checking
create policy "Owner Update"
  on storage.objects for update
  to authenticated
  using ( bucket_id = 'organization_assets' );

create policy "Owner Delete"
  on storage.objects for delete
  to authenticated
  using ( bucket_id = 'organization_assets' );
