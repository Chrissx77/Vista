-- Hardening dopo advisor di sicurezza (cf. Supabase database-linter).
-- Tutte le modifiche sono additive/idempotenti.

-- 1) Bucket pointview-images: rimuoviamo la SELECT pubblica su storage.objects.
--    Gli asset restano accessibili via URL diretto (bucket "public" = true),
--    ma evitiamo il listing degli oggetti e il fingerprinting del bucket.
drop policy if exists "pointview_images_select_public" on storage.objects;

-- 2) handle_new_user(): è chiamata SOLO dal trigger su auth.users.
--    Va resa NON callable via /rest/v1/rpc.
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- 3) Niente grant a anon sulle tabelle dell'app: il client autenticato usa
--    il ruolo 'authenticated'. Riduciamo l'esposizione GraphQL/REST per anon.
revoke select, insert, update, delete on table public.profiles      from anon;
revoke select, insert, update, delete on table public.point_views   from anon;
revoke select, insert, update, delete on table public.favorites     from anon;
revoke select, insert, update, delete on table public.reports       from anon;
revoke select, insert, update, delete on table public.blocks        from anon;

-- 4) blocks: l'utente non ha bisogno di "discoverability" via GraphQL,
--    ma deve poter scrivere/leggere i propri blocchi (RLS).
--    Manteniamo i grant minimi.
revoke select on table public.blocks from authenticated;
grant select, insert, delete on table public.blocks to authenticated;
