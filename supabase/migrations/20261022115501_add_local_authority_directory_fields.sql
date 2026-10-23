-- The initial routing migration may have been applied before the official
-- local-authority directory fields were added.  Keep this migration
-- idempotent so it is safe on both database versions.
alter table public.local_authorities
  add column if not exists address text,
  add column if not exists contact_email text,
  add column if not exists contact_phone text,
  add column if not exists website_url text,
  add column if not exists directory_source_url text,
  add column if not exists directory_updated_at date;
