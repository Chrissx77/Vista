-- Esegui nel SQL Editor di Supabase se compare errore tipo:
-- "column image_urls does not exist" / colonna immagini mancante su point_views.
-- Idempotente (sicuro da rilanciare).

alter table public.point_views
  add column if not exists image_urls text[] not null default '{}';

comment on column public.point_views.image_urls is
  'URL pubblici Storage (max 3) per il carosello del punto';
