-- Owner-managed public cover images for matchmaking trips.

insert into storage.buckets (id, name, public)
values ('trip-images', 'trip-images', true)
on conflict (id) do update set public = true;

drop policy if exists "users upload their trip covers" on storage.objects;
create policy "users upload their trip covers"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'trip-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "users update their trip covers" on storage.objects;
create policy "users update their trip covers"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'trip-images'
    and owner_id = auth.uid()::text
  )
  with check (
    bucket_id = 'trip-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "users read their trip cover objects" on storage.objects;
create policy "users read their trip cover objects"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'trip-images'
    and owner_id = auth.uid()::text
  );

drop policy if exists "users delete their trip covers" on storage.objects;
create policy "users delete their trip covers"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'trip-images'
    and owner_id = auth.uid()::text
  );
