-- Fix: ensure authenticated role has base table permissions and add a
-- security-definer RPC for fetching the current user's own reports.
-- All other citizen-facing queries already use security-definer RPCs;
-- getMyReports() was the only one hitting the table directly and therefore
-- depended on a GRANT that the earlier migration never added.

begin;

-- 1) Guarantee the authenticated role can read and insert its own rows.
--    (RLS policies already restrict what rows are visible; this just gives
--     the role the base-level privilege to even attempt the query.)
grant select, insert on public.issues to authenticated;

-- 2) Security-definer RPC so the citizen app can fetch its own reports
--    without relying on the direct-table GRANT being present.
create or replace function public.get_my_reports()
returns table (
  id          text,
  category    text,
  description text,
  status      public.issue_status,
  address     text,
  latitude    double precision,
  longitude   double precision,
  photo_url   text,
  created_at  timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    i.id,
    i.category,
    i.description,
    i.status,
    i.address,
    i.latitude,
    i.longitude,
    i.photo_url,
    i.created_at
  from public.issues i
  where i.reporter_id = auth.uid()
  order by i.created_at desc;
$$;

grant execute on function public.get_my_reports() to authenticated;

commit;
