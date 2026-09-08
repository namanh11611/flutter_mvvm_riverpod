-- Foreground live-location sharing for active trip groups.
create table if not exists public.live_location_shares (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  trip_id uuid not null references public.matchmaking_trips(id) on delete cascade,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  accuracy double precision not null check (accuracy >= 0),
  recorded_at timestamptz not null,
  expires_at timestamptz not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (user_id, trip_id),
  check (expires_at > created_at)
);

create index if not exists live_location_shares_trip_idx
  on public.live_location_shares (trip_id, is_active, expires_at);

alter table public.live_location_shares enable row level security;

drop policy if exists "trip members read live locations"
  on public.live_location_shares;
create policy "trip members read live locations"
on public.live_location_shares for select to authenticated
using (
  public.is_trip_member(trip_id)
  and is_active
  and expires_at > now()
);

drop policy if exists "users start their own live location"
  on public.live_location_shares;
create policy "users start their own live location"
on public.live_location_shares for insert to authenticated
with check (user_id = auth.uid() and public.is_trip_member(trip_id));

drop policy if exists "users update their own live location"
  on public.live_location_shares;
create policy "users update their own live location"
on public.live_location_shares for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid() and public.is_trip_member(trip_id));

grant select, insert, update on public.live_location_shares to authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'live_location_shares'
  ) then
    alter publication supabase_realtime
      add table public.live_location_shares;
  end if;
end;
$$;
