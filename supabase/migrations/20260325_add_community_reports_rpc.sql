-- Community list RPC for read-only tab in citizen app.

begin;

create or replace function public.get_community_reports(
  page_number integer default 1,
  page_size integer default 20
)
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
  with args as (
    select
      greatest(coalesce(page_number, 1), 1) as page_number,
      greatest(coalesce(page_size, 20), 1) as page_size
  ),
  bounds as (
    select
      ((page_number - 1) * page_size) + 1 as start_row,
      page_number * page_size as end_row
    from args
  ),
  ranked as (
    select
      i.id,
      i.category,
      i.description,
      i.status,
      i.address,
      i.latitude,
      i.longitude,
      i.photo_url,
      i.created_at,
      row_number() over (order by i.created_at desc) as rn
    from public.issues i
  )
  select
    r.id,
    r.category,
    r.description,
    r.status,
    r.address,
    r.latitude,
    r.longitude,
    r.photo_url,
    r.created_at
  from ranked r
  cross join bounds b
  where r.rn between b.start_row and b.end_row
  order by r.created_at desc;
$$;

grant execute on function public.get_community_reports(integer, integer) to authenticated;

commit;
