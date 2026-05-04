-- Esegui nel SQL Editor del dashboard Supabase se vedi errore "Bucket not found"
-- in fase di salvataggio punto (upload immagini).
-- Idempotente: puoi rilanciare più volte.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'pointview-images',
  'pointview-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "pointview_images_select_public" on storage.objects;
create policy "pointview_images_select_public"
  on storage.objects for select
  to public
  using (bucket_id = 'pointview-images');

drop policy if exists "pointview_images_insert_own_folder" on storage.objects;
create policy "pointview_images_insert_own_folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'pointview-images'
    and split_part(name, '/', 1) = auth.uid()::text
  );

drop policy if exists "pointview_images_delete_own_folder" on storage.objects;
create policy "pointview_images_delete_own_folder"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'pointview-images'
    and split_part(name, '/', 1) = auth.uid()::text
  );
