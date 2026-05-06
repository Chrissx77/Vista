-- Vista: indice geografico semplice (non PostGIS) per query bbox sulla mappa.
create index if not exists point_views_geo_idx
  on public.point_views (latitude, longitude);
