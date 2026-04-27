-- Community home feed RPCs for citizen app.
-- Keeps table-level RLS strict while exposing approved aggregate/recent data.

begin;

create or replace function public.get_community_issue_stats()
returns table (
  submitted_count bigint,
  in_progress_count bigint,
  resolved_count bigint
)
language sql
security definer
set search_path = public
as $$
  select
    count(*) filter (where status = 'submitted'::public.issue_status) as submitted_count,
    count(*) filter (where status = 'in_progress'::public.issue_status) as in_progress_count,
    count(*) filter (where status = 'resolved'::public.issue_status) as resolved_count
  from public.issues;
$$;

grant execute on function public.get_community_issue_stats() to authenticated;

create or replace function public.get_community_recent_reports(limit_count integer default 3)
returns table (
  id text,
  category text,
  description text,
  status public.issue_status,
  address text,
  latitude double precision,
  longitude double precision,
  photo_url text,
  created_at timestamptz
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
  order by i.created_at desc
  limit greatest(coalesce(limit_count, 3), 0);
$$;

grant execute on function public.get_community_recent_reports(integer) to authenticated;

commit;
