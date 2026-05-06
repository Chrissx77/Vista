-- Performance: avvolgere auth.uid() in (select ...) per evitare la rivalutazione
-- per ogni riga (cf. advisor 0003 auth_rls_initplan).

-- profiles
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- point_views
drop policy if exists "point_views_insert_own" on public.point_views;
create policy "point_views_insert_own"
  on public.point_views for insert
  to authenticated
  with check ((select auth.uid()) = created_by);

drop policy if exists "point_views_update_own" on public.point_views;
create policy "point_views_update_own"
  on public.point_views for update
  to authenticated
  using ((select auth.uid()) = created_by)
  with check ((select auth.uid()) = created_by);

drop policy if exists "point_views_delete_own" on public.point_views;
create policy "point_views_delete_own"
  on public.point_views for delete
  to authenticated
  using ((select auth.uid()) = created_by);

-- favorites
drop policy if exists "favorites_select_own" on public.favorites;
create policy "favorites_select_own"
  on public.favorites for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "favorites_insert_own" on public.favorites;
create policy "favorites_insert_own"
  on public.favorites for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "favorites_delete_own" on public.favorites;
create policy "favorites_delete_own"
  on public.favorites for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- reports
drop policy if exists "reports_insert_own" on public.reports;
create policy "reports_insert_own"
  on public.reports for insert
  to authenticated
  with check ((select auth.uid()) = reporter_id);

drop policy if exists "reports_select_own" on public.reports;
create policy "reports_select_own"
  on public.reports for select
  to authenticated
  using ((select auth.uid()) = reporter_id);

-- blocks
drop policy if exists "blocks_select_own" on public.blocks;
create policy "blocks_select_own"
  on public.blocks for select
  to authenticated
  using ((select auth.uid()) = blocker_id);

drop policy if exists "blocks_insert_own" on public.blocks;
create policy "blocks_insert_own"
  on public.blocks for insert
  to authenticated
  with check ((select auth.uid()) = blocker_id);

drop policy if exists "blocks_delete_own" on public.blocks;
create policy "blocks_delete_own"
  on public.blocks for delete
  to authenticated
  using ((select auth.uid()) = blocker_id);

-- Indici mancanti sui foreign key (advisor 0001).
create index if not exists point_views_created_by_idx
  on public.point_views (created_by);

create index if not exists blocks_blocked_idx
  on public.blocks (blocked_id);
