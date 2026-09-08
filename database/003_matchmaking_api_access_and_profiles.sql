-- Public profile data and explicit Data API grants for matchmaking.
-- Run once after 001_matchmaking_schema.sql and 002_matchmaking_rls.sql.

create table public.user_accounts (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  date_of_birth date,
  gender text,
  bio text,
  profile_photo_url text,
  verification_status text not null default 'unverified',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint valid_profile_gender check (
    gender is null or gender in ('Female', 'Male', 'Other', 'Prefer not to say')
  ),
  constraint valid_verification_status check (
    verification_status in ('unverified', 'pending', 'verified')
  )
);

alter table public.user_accounts enable row level security;

create policy "authenticated users can read matchmaking profiles"
on public.user_accounts for select to authenticated
using (true);

create policy "users can insert their matchmaking profile"
on public.user_accounts for insert to authenticated
with check (id = (select auth.uid()));

create policy "users can update their matchmaking profile"
on public.user_accounts for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create or replace function public.handle_new_matchmaking_user()
returns trigger
language plpgsql
security definer set search_path = ''
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
create trigger on_auth_user_created_matchmaking
  after insert on auth.users
  for each row execute procedure public.handle_new_matchmaking_user();

-- Backfill users, including test users created before this migration.
insert into public.user_accounts (id, display_name)
select
  id,
  coalesce(
    nullif(raw_user_meta_data ->> 'full_name', ''),
    nullif(split_part(email, '@', 1), ''),
    'Traveller'
  )
from auth.users
on conflict (id) do nothing;

-- Data API privileges. RLS policies still determine which rows are accessible.
grant select, insert, update on public.user_accounts to authenticated;
grant select, insert, update, delete on public.matchmaking_trips to authenticated;
grant select, insert, delete on public.matchmaking_trip_styles to authenticated;
grant select, insert, update, delete on public.matchmaking_join_requests to authenticated;
grant select on public.matchmaking_trip_members to authenticated;
grant select, insert, update, delete on public.matchmaking_saved_trips to authenticated;

