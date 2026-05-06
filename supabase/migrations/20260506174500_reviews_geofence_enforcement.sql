-- Enforce review geofence on database side.
-- Client checks remain for UX, but this guarantees integrity.

alter table public.point_reviews
  add column if not exists reviewer_latitude double precision,
  add column if not exists reviewer_longitude double precision,
  add column if not exists reviewer_distance_meters integer;

create or replace function public.haversine_distance_meters(
  lat1 double precision,
  lon1 double precision,
  lat2 double precision,
  lon2 double precision
)
returns double precision
language sql
immutable
as $$
  select 2 * 6371000 * asin(
    sqrt(
      power(sin(radians((lat2 - lat1) / 2)), 2) +
      cos(radians(lat1)) * cos(radians(lat2)) *
      power(sin(radians((lon2 - lon1) / 2)), 2)
    )
  );
$$;

create or replace function public.enforce_review_geofence()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  pv_lat double precision;
  pv_lon double precision;
  distance_m double precision;
begin
  if new.reviewer_latitude is null or new.reviewer_longitude is null then
    raise exception 'Review location is required.';
  end if;

  select latitude, longitude
  into pv_lat, pv_lon
  from public.point_views
  where id = new.point_view_id;

  if pv_lat is null or pv_lon is null then
    raise exception 'Point coordinates are missing.';
  end if;

  distance_m := public.haversine_distance_meters(
    new.reviewer_latitude,
    new.reviewer_longitude,
    pv_lat,
    pv_lon
  );

  if distance_m > 100 then
    raise exception 'Review allowed only within 100 meters from point.';
  end if;

  new.reviewer_distance_meters := round(distance_m)::integer;
  return new;
end;
$$;

drop trigger if exists point_reviews_enforce_geofence on public.point_reviews;
create trigger point_reviews_enforce_geofence
before insert or update on public.point_reviews
for each row execute function public.enforce_review_geofence();
