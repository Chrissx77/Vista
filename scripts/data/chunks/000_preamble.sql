-- Seed generated automatically from Wikipedia GeoSearch + PageImages
-- It inserts only rows not already present by (name, lat, lon).
alter table public.point_views add column if not exists source text;
