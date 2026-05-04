-- Consente a ogni utente autenticato di leggere le righe profiles altrui
-- (es. display_name del creatore di un punto). L'email resta solo in auth.users.
drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_select_authenticated" on public.profiles;
create policy "profiles_select_authenticated"
  on public.profiles for select
  to authenticated
  using (true);
