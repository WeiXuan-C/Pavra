
ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;

-- 删除旧的 policies（如果存在）
DROP POLICY IF EXISTS "Enable read access for all users" ON public.requests;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.requests;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.requests;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.requests;

-- Enable read access for all users
create policy "Enable read access for all users"
on "public"."requests"
as PERMISSIVE
for SELECT
to public
using (true);

-- Enable insert for authenticated users only
create policy "Enable insert for authenticated users only"
on "public"."requests"
as PERMISSIVE
for INSERT
to authenticated
with check (true);

-- Enable update for authenticated users
create policy "Enable update for authenticated users"
on "public"."requests"
as PERMISSIVE
for UPDATE
to authenticated
using (true)
with check (true);

-- Enable delete for authenticated users
create policy "Enable delete for authenticated users"
on "public"."requests"
as PERMISSIVE
for DELETE
to authenticated
using (true);