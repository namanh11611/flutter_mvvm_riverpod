insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-images','profile-images',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
set public=excluded.public,file_size_limit=excluded.file_size_limit,
    allowed_mime_types=excluded.allowed_mime_types;

create policy "users upload their profile image"
on storage.objects for insert to authenticated
with check (
  bucket_id='profile-images'
  and (storage.foldername(name))[1]=(select auth.uid())::text
);
create policy "users update their profile image"
on storage.objects for update to authenticated
using (
  bucket_id='profile-images' and owner_id=(select auth.uid())::text
)
with check (
  bucket_id='profile-images'
  and (storage.foldername(name))[1]=(select auth.uid())::text
);
create policy "users delete their profile image"
on storage.objects for delete to authenticated
using (
  bucket_id='profile-images' and owner_id=(select auth.uid())::text
);;
