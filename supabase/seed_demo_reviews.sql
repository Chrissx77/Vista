-- Seed demo: recensioni fittizie (solo utenti diversi dal creatore del punto).
-- Coordinate reviewer = coordinate del punto per superare il geofence 100m.
-- Eseguibile su DB remoto già popolato; idempotente via ON CONFLICT.

insert into public.point_reviews (
  point_view_id,
  user_id,
  rating,
  review_text,
  reviewer_latitude,
  reviewer_longitude
)
select
  v.point_view_id,
  v.user_id,
  v.rating,
  v.review_text,
  pv.latitude,
  pv.longitude
from (
  values
    (10, '875adfa9-1d0b-4c23-bde7-8f69e0ad37d6'::uuid, 5,
      'Vista spettacolare, merita assolutamente la visita.'),
    (6, '875adfa9-1d0b-4c23-bde7-8f69e0ad37d6'::uuid, 4,
      'Posto tranquillo, ottimo per una pausa.'),
    (5, '875adfa9-1d0b-4c23-bde7-8f69e0ad37d6'::uuid, 5,
      'Il simbolo di Catania: foto perfetta al tramonto.'),
    (9, 'acc795bb-4142-45a2-b36c-8e3d8c86a2ab'::uuid, 5,
      'Punto curato e facile da raggiungere.'),
    (8, 'acc795bb-4142-45a2-b36c-8e3d8c86a2ab'::uuid, 3,
      'Nella media, meglio al mattino.'),
    (7, 'acc795bb-4142-45a2-b36c-8e3d8c86a2ab'::uuid, 4,
      'Bel panorama, consigliato.')
) as v(point_view_id, user_id, rating, review_text)
join public.point_views pv on pv.id = v.point_view_id
where pv.created_by is distinct from v.user_id
  and pv.latitude is not null
  and pv.longitude is not null
on conflict (point_view_id, user_id) do update set
  rating = excluded.rating,
  review_text = excluded.review_text,
  reviewer_latitude = excluded.reviewer_latitude,
  reviewer_longitude = excluded.reviewer_longitude,
  updated_at = now();
