-- =====================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Report Issues System
-- =====================================

-- =====================================
-- REPORT_ISSUES TABLE POLICIES
-- =====================================

-- 启用 RLS
ALTER TABLE public.report_issues ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "Enable read access for all users" ON public.report_issues;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.report_issues;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.report_issues;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.report_issues;

-- Enable read access for all users
create policy "Enable read access for all users"
on "public"."report_issues"
as PERMISSIVE
for SELECT
to public
using (true);

-- Enable insert for authenticated users only
create policy "Enable insert for authenticated users only"
on "public"."report_issues"
as PERMISSIVE
for INSERT
to authenticated
with check (true);

-- Enable update for authenticated users
create policy "Enable update for authenticated users"
on "public"."report_issues"
as PERMISSIVE
for UPDATE
to authenticated
using (true)
with check (true);

-- Enable delete for authenticated users
create policy "Enable delete for authenticated users"
on "public"."report_issues"
as PERMISSIVE
for DELETE
to authenticated
using (true);

-- =====================================
-- ISSUE_PHOTOS TABLE POLICIES
-- =====================================

-- 启用 RLS
ALTER TABLE public.issue_photos ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "Enable read access for all users" ON public.issue_photos;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.issue_photos;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.issue_photos;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.issue_photos;

-- Enable read access for all users (public can view all photos)
create policy "Enable read access for all users"
on "public"."issue_photos"
as PERMISSIVE
for SELECT
to public
using (true);

-- Enable insert for authenticated users only
create policy "Enable insert for authenticated users only"
on "public"."issue_photos"
as PERMISSIVE
for INSERT
to authenticated
with check (true);

-- Enable update for authenticated users (only if they own the report)
create policy "Enable update for authenticated users"
on "public"."issue_photos"
as PERMISSIVE
for UPDATE
to authenticated
using (
  EXISTS (
    SELECT 1 FROM report_issues 
    WHERE report_issues.id = issue_photos.issue_id 
    AND report_issues.created_by = (SELECT auth.uid())
  )
)
with check (
  EXISTS (
    SELECT 1 FROM report_issues 
    WHERE report_issues.id = issue_photos.issue_id 
    AND report_issues.created_by = (SELECT auth.uid())
  )
);

-- Enable delete for authenticated users (only if they own the report)
create policy "Enable delete for authenticated users"
on "public"."issue_photos"
as PERMISSIVE
for DELETE
to authenticated
using (
  EXISTS (
    SELECT 1 FROM report_issues 
    WHERE report_issues.id = issue_photos.issue_id 
    AND report_issues.created_by = (SELECT auth.uid())
  )
);

-- =====================================
-- ISSUE_TYPES TABLE POLICIES
-- =====================================

-- 启用 RLS
ALTER TABLE public.issue_types ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "Enable read access for all users" ON public.issue_types;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.issue_types;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.issue_types;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.issue_types;

-- Enable read access for all users
create policy "Enable read access for all users"
on "public"."issue_types"
as PERMISSIVE
for SELECT
to public
using (true);

-- Enable insert for authenticated users only
create policy "Enable insert for authenticated users only"
on "public"."issue_types"
as PERMISSIVE
for INSERT
to authenticated
with check (true);

-- Enable update for authenticated users
create policy "Enable update for authenticated users"
on "public"."issue_types"
as PERMISSIVE
for UPDATE
to authenticated
using (true)
with check (true);

-- Enable delete for authenticated users
create policy "Enable delete for authenticated users"
on "public"."issue_types"
as PERMISSIVE
for DELETE
to authenticated
using (true);

-- =====================================
-- ISSUE_VOTES TABLE POLICIES
-- =====================================

-- 启用 RLS
ALTER TABLE public.issue_votes ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "Enable read access for all users" ON public.issue_votes;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.issue_votes;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.issue_votes;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.issue_votes;

-- Enable read access for all users
create policy "Enable read access for all users"
on "public"."issue_votes"
as PERMISSIVE
for SELECT
to public
using (true);

-- Enable insert for authenticated users only
create policy "Enable insert for authenticated users only"
on "public"."issue_votes"
as PERMISSIVE
for INSERT
to authenticated
with check (true);

-- Enable update for authenticated users
create policy "Enable update for authenticated users"
on "public"."issue_votes"
as PERMISSIVE
for UPDATE
to authenticated
using (true)
with check (true);

-- Enable delete for authenticated users
create policy "Enable delete for authenticated users"
on "public"."issue_votes"
as PERMISSIVE
for DELETE
to authenticated
using (true);

-- =====================================
-- AI_DETECTION TABLE POLICIES
-- =====================================

-- 启用 RLS
ALTER TABLE public.ai_detection ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "Enable read access for all users" ON public.ai_detection;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.ai_detection;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.ai_detection;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.ai_detection;

-- Enable read access for all users
create policy "Enable read access for all users"
on "public"."ai_detection"
as PERMISSIVE
for SELECT
to public
using (true);

-- Enable insert for authenticated users only
create policy "Enable insert for authenticated users only"
on "public"."ai_detection"
as PERMISSIVE
for INSERT
to authenticated
with check (true);

-- Enable update for authenticated users
create policy "Enable update for authenticated users"
on "public"."ai_detection"
as PERMISSIVE
for UPDATE
to authenticated
using (true)
with check (true);

-- Enable delete for authenticated users
create policy "Enable delete for authenticated users"
on "public"."ai_detection"
as PERMISSIVE
for DELETE
to authenticated
using (true);

-- =====================================
-- AI_DESCRIPTIONS TABLE POLICIES
-- =====================================

-- 启用 RLS
ALTER TABLE public.ai_descriptions ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "Enable read access for all users" ON public.ai_descriptions;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.ai_descriptions;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.ai_descriptions;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.ai_descriptions;

-- Enable read access for all users
create policy "Enable read access for all users"
on "public"."ai_descriptions"
as PERMISSIVE
for SELECT
to public
using (true);

-- Enable insert for authenticated users only
create policy "Enable insert for authenticated users only"
on "public"."ai_descriptions"
as PERMISSIVE
for INSERT
to authenticated
with check (true);

-- Enable update for authenticated users
create policy "Enable update for authenticated users"
on "public"."ai_descriptions"
as PERMISSIVE
for UPDATE
to authenticated
using (true)
with check (true);

-- Enable delete for authenticated users
create policy "Enable delete for authenticated users"
on "public"."ai_descriptions"
as PERMISSIVE
for DELETE
to authenticated
using (true);