update storage.buckets
set allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
where id in ('profile-images', 'user-gallery');

grant select, insert, delete on table public.user_gallery to authenticated;

drop policy if exists "users upload their profile image" on storage.objects;
drop policy if exists "users update their profile image" on storage.objects;
drop policy if exists "users delete their profile image" on storage.objects;

create policy "users upload their profile image"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "users update their profile image"
on storage.objects for update to authenticated
using (
  bucket_id = 'profile-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'profile-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "users delete their profile image"
on storage.objects for delete to authenticated
using (
  bucket_id = 'profile-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
