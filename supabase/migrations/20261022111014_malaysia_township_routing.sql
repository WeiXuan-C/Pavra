-- Malaysia township routing foundation
--
-- Boundary data is intentionally not seeded here. Import only reviewed GeoJSON
-- from a documented source, then create routing rules per local authority.

create extension if not exists postgis;
create schema if not exists private;
revoke all on schema private from public;

create table if not exists public.malaysia_states (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[A-Z]{2}$'),
  name_en text not null unique,
  name_ms text,
  created_at timestamptz not null default now()
);

-- National scope: 13 states plus the 3 federal territories. Local-authority
-- and township boundaries are intentionally imported separately after review.
insert into public.malaysia_states (code, name_en, name_ms) values
  ('JH', 'Johor', 'Johor'),
  ('KD', 'Kedah', 'Kedah'),
  ('KT', 'Kelantan', 'Kelantan'),
  ('MK', 'Melaka', 'Melaka'),
  ('NS', 'Negeri Sembilan', 'Negeri Sembilan'),
  ('PH', 'Pahang', 'Pahang'),
  ('PG', 'Pulau Pinang', 'Pulau Pinang'),
  ('PK', 'Perak', 'Perak'),
  ('PS', 'Perlis', 'Perlis'),
  ('SB', 'Sabah', 'Sabah'),
  ('SW', 'Sarawak', 'Sarawak'),
  ('SG', 'Selangor', 'Selangor'),
  ('TR', 'Terengganu', 'Terengganu'),
  ('KL', 'Kuala Lumpur', 'Wilayah Persekutuan Kuala Lumpur'),
  ('LB', 'Labuan', 'Wilayah Persekutuan Labuan'),
  ('PJ', 'Putrajaya', 'Wilayah Persekutuan Putrajaya')
on conflict (code) do update set
  name_en = excluded.name_en,
  name_ms = excluded.name_ms;

create table if not exists public.local_authorities (
  id uuid primary key default gen_random_uuid(),
  state_id uuid not null references public.malaysia_states(id) on delete restrict,
  name text not null,
  council_code text unique,
  authority_type text not null check (authority_type in (
    'city_council', 'municipal_council', 'district_council', 'special_authority'
  )),
  address text,
  contact_email text,
  contact_phone text,
  website_url text,
  directory_source_url text,
  directory_updated_at date,
  created_at timestamptz not null default now(),
  unique (state_id, name)
);

create table if not exists public.responsible_authorities (
  id uuid primary key default gen_random_uuid(),
  local_authority_id uuid references public.local_authorities(id) on delete set null,
  name text not null,
  short_name text,
  authority_type text not null check (authority_type in (
    'local_council', 'developer', 'management_body', 'utility', 'road_agency', 'other'
  )),
  contact_email text,
  contact_phone text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (local_authority_id, name)
);

create table if not exists public.townships (
  id uuid primary key default gen_random_uuid(),
  local_authority_id uuid not null references public.local_authorities(id) on delete restrict,
  name text not null,
  boundary geometry(multipolygon, 4326) not null,
  boundary_source_url text not null,
  boundary_source_name text not null,
  boundary_reviewed_at timestamptz,
  default_authority_id uuid references public.responsible_authorities(id) on delete set null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (local_authority_id, name),
  check (st_isvalid(boundary))
);

create index if not exists townships_boundary_gix on public.townships using gist (boundary);
create index if not exists local_authorities_state_idx on public.local_authorities(state_id);
create index if not exists responsible_authorities_local_authority_idx
  on public.responsible_authorities(local_authority_id);

-- Keep issue types configurable instead of hard-coding categories in Flutter.
alter table public.issue_types add column if not exists slug text;
alter table public.issue_types add column if not exists category text;
alter table public.issue_types add column if not exists is_active boolean not null default true;
alter table public.issue_types add column if not exists sort_order integer not null default 0;
create unique index if not exists issue_types_slug_unique
  on public.issue_types (slug) where slug is not null and is_deleted = false;

create table if not exists public.authority_routing_rules (
  id uuid primary key default gen_random_uuid(),
  authority_id uuid not null references public.responsible_authorities(id) on delete cascade,
  township_id uuid references public.townships(id) on delete cascade,
  issue_type_id uuid references public.issue_types(id) on delete cascade,
  priority smallint not null default 100 check (priority between 1 and 1000),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- A null township and/or issue type is a deliberate fallback rule.
  unique nulls not distinct (authority_id, township_id, issue_type_id)
);

create index if not exists authority_routing_rules_lookup_idx
  on public.authority_routing_rules (township_id, issue_type_id, priority)
  where is_active = true;

create table if not exists public.authority_memberships (
  authority_id uuid not null references public.responsible_authorities(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  membership_role text not null check (membership_role in ('viewer', 'dispatcher', 'manager')),
  created_at timestamptz not null default now(),
  primary key (authority_id, user_id)
);

alter table public.report_issues
  add column if not exists township_id uuid references public.townships(id) on delete set null,
  add column if not exists responsible_authority_id uuid references public.responsible_authorities(id) on delete set null,
  add column if not exists assignment_source text check (assignment_source in ('automatic', 'manual')),
  add column if not exists assigned_at timestamptz,
  add column if not exists assignment_reason text;

create index if not exists report_issues_township_idx on public.report_issues(township_id);
create index if not exists report_issues_responsible_authority_idx
  on public.report_issues(responsible_authority_id) where is_deleted = false;

create table if not exists public.report_issue_assignments (
  id uuid primary key default gen_random_uuid(),
  report_issue_id uuid not null references public.report_issues(id) on delete cascade,
  authority_id uuid references public.responsible_authorities(id) on delete set null,
  township_id uuid references public.townships(id) on delete set null,
  assignment_source text not null check (assignment_source in ('automatic', 'manual')),
  reason text,
  assigned_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists report_issue_assignments_report_idx
  on public.report_issue_assignments(report_issue_id, created_at desc);

create or replace function public.is_platform_admin()
returns boolean
language sql
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'developer'
  );
$$;

-- This is intentionally private: only the database trigger invokes automatic
-- routing, so a client cannot forge assignment-history records.
create or replace function private.route_report_issue(p_report_issue_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_report public.report_issues%rowtype;
  v_township_id uuid;
  v_authority_id uuid;
  v_reason text;
begin
  select * into v_report from public.report_issues where id = p_report_issue_id;
  if not found or v_report.latitude is null or v_report.longitude is null then
    return null;
  end if;

  select t.id, coalesce(r.authority_id, t.default_authority_id),
         case when r.id is null then 'Township default authority' else 'Township and issue-type routing rule' end
    into v_township_id, v_authority_id, v_reason
  from public.townships t
  left join lateral (
    select rr.id, rr.authority_id
    from public.authority_routing_rules rr
    where rr.is_active
      and (rr.township_id is null or rr.township_id = t.id)
      and (rr.issue_type_id is null or rr.issue_type_id = any(v_report.issue_type_ids))
    order by (rr.township_id is not null) desc,
             (rr.issue_type_id is not null) desc,
             rr.priority asc
    limit 1
  ) r on true
  where t.is_active
    and st_covers(t.boundary, st_setsrid(st_makepoint(v_report.longitude, v_report.latitude), 4326))
  order by st_area(t.boundary) asc
  limit 1;

  update public.report_issues
  set township_id = v_township_id,
      responsible_authority_id = v_authority_id,
      assignment_source = case when v_authority_id is null then null else 'automatic' end,
      assigned_at = case when v_authority_id is null then null else now() end,
      assignment_reason = case when v_authority_id is null then 'No matching routing rule' else v_reason end,
      updated_at = now()
  where id = p_report_issue_id;

  if v_authority_id is not null then
    insert into public.report_issue_assignments (
      report_issue_id, authority_id, township_id, assignment_source, reason
    ) values (
      p_report_issue_id, v_authority_id, v_township_id, 'automatic', v_reason
    );
  end if;
  return v_authority_id;
end;
$$;

create or replace function public.route_report_issue_on_submission()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.status = 'submitted' and new.latitude is not null and new.longitude is not null
     and (tg_op = 'INSERT' or old.status is distinct from new.status
          or old.latitude is distinct from new.latitude
          or old.longitude is distinct from new.longitude
          or old.issue_type_ids is distinct from new.issue_type_ids) then
    perform private.route_report_issue(new.id);
  end if;
  return new;
end;
$$;

drop trigger if exists route_report_issue_on_submission on public.report_issues;
create trigger route_report_issue_on_submission
after insert or update of status, latitude, longitude, issue_type_ids on public.report_issues
for each row execute function public.route_report_issue_on_submission();

create or replace function public.manually_assign_report_issue(
  p_report_issue_id uuid,
  p_authority_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_township_id uuid;
  v_can_assign boolean;
begin
  select public.is_platform_admin() or exists (
    select 1 from public.authority_memberships am
    where am.authority_id = p_authority_id
      and am.user_id = (select auth.uid())
      and am.membership_role in ('dispatcher', 'manager')
  ) into v_can_assign;
  if not coalesce(v_can_assign, false) then
    raise exception 'Not authorised to manually assign reports';
  end if;

  select township_id into v_township_id from public.report_issues where id = p_report_issue_id;
  if not found then
    raise exception 'Report issue not found';
  end if;

  update public.report_issues
  set responsible_authority_id = p_authority_id,
      assignment_source = 'manual',
      assigned_at = now(),
      assignment_reason = p_reason,
      updated_at = now()
  where id = p_report_issue_id;

  insert into public.report_issue_assignments (
    report_issue_id, authority_id, township_id, assignment_source, reason, assigned_by
  ) values (
    p_report_issue_id, p_authority_id, v_township_id, 'manual', p_reason, (select auth.uid())
  );
end;
$$;

grant execute on function public.manually_assign_report_issue(uuid, uuid, text) to authenticated;
revoke all on function public.manually_assign_report_issue(uuid, uuid, text) from public;

-- Read-only geographic reference data is available to logged-in application users.
alter table public.malaysia_states enable row level security;
alter table public.local_authorities enable row level security;
alter table public.responsible_authorities enable row level security;
alter table public.townships enable row level security;
alter table public.authority_routing_rules enable row level security;
alter table public.authority_memberships enable row level security;
alter table public.report_issue_assignments enable row level security;

create policy "authenticated can read Malaysia states" on public.malaysia_states for select to authenticated using (true);
create policy "authenticated can read local authorities" on public.local_authorities for select to authenticated using (true);
create policy "authenticated can read responsible authorities" on public.responsible_authorities for select to authenticated using (true);
create policy "authenticated can read townships" on public.townships for select to authenticated using (true);
create policy "admins manage Malaysia reference data" on public.malaysia_states for all to authenticated using ((select public.is_platform_admin())) with check ((select public.is_platform_admin()));
create policy "admins manage local authorities" on public.local_authorities for all to authenticated using ((select public.is_platform_admin())) with check ((select public.is_platform_admin()));
create policy "admins manage responsible authorities" on public.responsible_authorities for all to authenticated using ((select public.is_platform_admin())) with check ((select public.is_platform_admin()));
create policy "admins manage townships" on public.townships for all to authenticated using ((select public.is_platform_admin())) with check ((select public.is_platform_admin()));
create policy "admins manage routing rules" on public.authority_routing_rules for all to authenticated using ((select public.is_platform_admin())) with check ((select public.is_platform_admin()));
create policy "admins manage memberships" on public.authority_memberships for all to authenticated using ((select public.is_platform_admin())) with check ((select public.is_platform_admin()));
create policy "users can read relevant assignment history" on public.report_issue_assignments for select to authenticated using (
  exists (select 1 from public.report_issues ri where ri.id = report_issue_id and ri.created_by = (select auth.uid()))
  or exists (select 1 from public.authority_memberships am where am.authority_id = report_issue_assignments.authority_id and am.user_id = (select auth.uid()))
  or (select public.is_platform_admin())
);
