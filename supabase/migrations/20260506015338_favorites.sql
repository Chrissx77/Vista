-- Vista: punti salvati ("preferiti") per utente.
-- RLS owner-only: ogni riga è scrivibile solo dal suo proprietario.

create table if not exists public.favorites (
  user_id uuid not null references auth.users (id) on delete cascade,
  point_view_id bigint not null references public.point_views (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, point_view_id)
);

comment on table public.favorites is 'Pointview salvati come preferiti, owner-only';

create index if not exists favorites_user_idx
  on public.favorites (user_id, created_at desc);

create index if not exists favorites_pointview_idx
  on public.favorites (point_view_id);

alter table public.favorites enable row level security;

drop policy if exists "favorites_select_own" on public.favorites;
create policy "favorites_select_own"
  on public.favorites for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "favorites_insert_own" on public.favorites;
create policy "favorites_insert_own"
  on public.favorites for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "favorites_delete_own" on public.favorites;
create policy "favorites_delete_own"
  on public.favorites for delete
  to authenticated
  using (auth.uid() = user_id);
