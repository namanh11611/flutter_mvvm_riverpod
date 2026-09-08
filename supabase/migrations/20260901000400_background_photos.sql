alter table public.user_accounts
  add column if not exists background_photo_path text;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'background-images',
  'background-images',
  true,
  10485760,
  array['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "users upload their background image" on storage.objects;
drop policy if exists "users update their background image" on storage.objects;
drop policy if exists "users delete their background image" on storage.objects;

create policy "users upload their background image"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'background-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "users update their background image"
on storage.objects for update to authenticated
using (
  bucket_id = 'background-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'background-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "users delete their background image"
on storage.objects for delete to authenticated
using (
  bucket_id = 'background-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

notify pgrst, 'reload schema';
