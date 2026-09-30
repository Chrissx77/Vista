-- Impedisce di recensire i propri punti panoramici.

create or replace function public.enforce_no_self_review()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  owner_id uuid;
begin
  select created_by into owner_id
  from public.point_views
  where id = new.point_view_id;

  if owner_id is not null and owner_id = new.user_id then
    raise exception 'Cannot review your own point.';
  end if;

  return new;
end;
$$;

drop trigger if exists point_reviews_enforce_no_self on public.point_reviews;
create trigger point_reviews_enforce_no_self
before insert or update on public.point_reviews
for each row execute function public.enforce_no_self_review();
