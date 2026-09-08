insert into public.user_accounts as destination (
  id, display_name, date_of_birth, gender, bio, profile_photo_path,
  verification_status, created_at, updated_at
)
select id, display_name, date_of_birth, gender, bio, profile_photo_path,
       verification_status, created_at, updated_at
from public.matchmaking_profiles
on conflict (id) do update
set display_name = excluded.display_name,
    date_of_birth = excluded.date_of_birth,
    gender = excluded.gender,
    bio = excluded.bio,
    profile_photo_path = excluded.profile_photo_path,
    verification_status = excluded.verification_status,
    created_at = least(destination.created_at, excluded.created_at),
    updated_at = excluded.updated_at
where excluded.updated_at > destination.updated_at;

alter table public.user_accounts
  rename constraint matchmaking_profiles_id_fkey to user_accounts_id_fkey;
alter index public.matchmaking_profiles_pkey rename to user_accounts_pkey;

drop policy if exists "authenticated users can read matchmaking profiles" on public.user_accounts;
drop policy if exists "users can insert their matchmaking profile" on public.user_accounts;
drop policy if exists "users can update their matchmaking profile" on public.user_accounts;

create policy "authenticated users can read user accounts"
on public.user_accounts for select to authenticated using (true);
create policy "users can insert their user account"
on public.user_accounts for insert to authenticated
with check (id = (select auth.uid()));
create policy "users can update their user account"
on public.user_accounts for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create or replace function public.handle_new_user_account()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.user_accounts (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(split_part(new.email, '@', 1), ''),
      'Traveller'
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_matchmaking on auth.users;
drop trigger if exists on_auth_user_created_account on auth.users;
create trigger on_auth_user_created_account
  after insert on auth.users
  for each row execute function public.handle_new_user_account();

drop function if exists public.handle_new_matchmaking_user();
drop table public.matchmaking_profiles;
notify pgrst, 'reload schema';;
