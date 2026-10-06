-- Add allowed_emails_domain to organizations
ALTER TABLE public.organizations 
ADD COLUMN IF NOT EXISTS allowed_emails_domain text;

-- Index for faster lookup during signup
CREATE INDEX IF NOT EXISTS idx_organizations_domain ON public.organizations(allowed_emails_domain);

-- Ensure students table has organization_id (if exists, or usually profiles are strictly role-based tables)
-- Checking if public.students exists... if not, we assume profiles or metadata.
-- Let's add it to public.profiles if that's the main table, or create a specific linkage reference if needed.
-- Based on previous context, we might rely on `public.profiles` or specific role tables.
-- For now, let's assume we need to link NEW users.

-- If we have a profiles table:
-- ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES public.organizations(id);
