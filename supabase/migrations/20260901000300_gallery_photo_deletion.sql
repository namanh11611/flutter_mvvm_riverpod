grant delete on table public.user_gallery to authenticated;

drop policy if exists "users delete their gallery rows" on public.user_gallery;
create policy "users delete their gallery rows"
on public.user_gallery for delete to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "users delete their gallery images" on storage.objects;
create policy "users delete their gallery images"
on storage.objects for delete to authenticated
using (
  bucket_id = 'user-gallery'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
