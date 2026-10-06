-- 1. Create a function that runs when a new user is created
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_org_id uuid;
  v_role text;
begin
  v_role := new.raw_user_meta_data ->> 'role';
  
  -- For recruiters, create an organization first
  if v_role = 'recruiter' then
    insert into public.organizations (
      name,
      short_code,
      type,
      industry,
      company_size,
      headquarters,
      website,
      description,
      created_by
    )
    values (
      new.raw_user_meta_data ->> 'company_name',
      UPPER(SUBSTRING(REPLACE(new.raw_user_meta_data ->> 'company_name', ' ', ''), 1, 6)),
      'company',
      new.raw_user_meta_data ->> 'industry',
      new.raw_user_meta_data ->> 'company_size',
      new.raw_user_meta_data ->> 'company_location',
      new.raw_user_meta_data ->> 'company_website',
      'Company profile for ' || (new.raw_user_meta_data ->> 'company_name'),
      new.id
    )
    returning id into v_org_id;
    
    -- Create profile with organization link
    insert into public.profiles (
      id, 
      email, 
      role, 
      full_name, 
      phone, 
      organization_id,
      job_title
    )
    values (
      new.id,
      new.email,
      v_role,
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'phone',
      v_org_id,
      new.raw_user_meta_data ->> 'designation'
    );
  else
    -- For non-recruiters, create profile normally
    insert into public.profiles (id, email, role, full_name)
    values (
      new.id,
      new.email,
      v_role,
      new.raw_user_meta_data ->> 'full_name'
    );
  end if;
  
  return new;
end;
$$;

-- 2. Create the trigger
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 3. (Optional) Fix RLS if needed (Allow public read for now to debug)
drop policy if exists "Public profiles are viewable by everyone." on profiles;
create policy "Public profiles are viewable by everyone." on profiles for select using (true);
