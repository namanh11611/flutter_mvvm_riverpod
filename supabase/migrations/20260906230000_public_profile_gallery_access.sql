-- Gallery rows are profile content. Owners can always see their own photos;
-- verified users can see them when opening another traveller's profile.
alter table public.user_gallery enable row level security;
grant select on table public.user_gallery to authenticated;

drop policy if exists "authenticated users read gallery rows"
  on public.user_gallery;
create policy "authenticated users read gallery rows"
on public.user_gallery
for select
to authenticated
using (
  user_id = (select auth.uid())
  or exists (
    select 1
    from public.user_accounts
    where id = (select auth.uid())
      and verification_status = 'verified'
  )
);
