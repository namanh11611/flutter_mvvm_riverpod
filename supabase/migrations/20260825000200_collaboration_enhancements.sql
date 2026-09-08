-- GoBuddy collaboration enhancements: admins, comments and live notifications.
-- Run after 20260816_group_collaboration.sql.

create table if not exists public.trip_member_roles (
  trip_id uuid not null references public.matchmaking_trips(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('admin')),
  created_at timestamptz not null default now(),
  primary key (trip_id, user_id, role)
);

create table if not exists public.trip_activity_comments (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.matchmaking_trips(id) on delete cascade,
  activity_id uuid not null references public.trip_activities(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 1000),
  created_at timestamptz not null default now()
);

create table if not exists public.trip_activity_events (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.matchmaking_trips(id) on delete cascade,
  actor_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null check (event_type in ('activity_created', 'activity_edited', 'activity_pinned', 'vote_cast', 'comment_added', 'member_muted', 'member_removed')),
  summary text not null check (char_length(trim(summary)) between 1 and 280),
  created_at timestamptz not null default now()
);

create index if not exists trip_comments_activity_created_idx
  on public.trip_activity_comments(activity_id, created_at);
create index if not exists trip_events_trip_created_idx
  on public.trip_activity_events(trip_id, created_at desc);

create or replace function public.is_trip_admin(p_trip_id uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select public.is_trip_creator(p_trip_id)
    or exists (
      select 1 from public.trip_member_roles
      where trip_id = p_trip_id and user_id = auth.uid() and role = 'admin'
    );
$$;

alter table public.trip_member_roles enable row level security;
alter table public.trip_activity_comments enable row level security;
alter table public.trip_activity_events enable row level security;

drop policy if exists "members read trip roles" on public.trip_member_roles;
create policy "members read trip roles" on public.trip_member_roles
  for select using (public.is_trip_member(trip_id));
drop policy if exists "creator assigns trip admins" on public.trip_member_roles;
create policy "creator assigns trip admins" on public.trip_member_roles
  for all using (public.is_trip_creator(trip_id)) with check (public.is_trip_creator(trip_id));
drop policy if exists "members read activity comments" on public.trip_activity_comments;
create policy "members read activity comments" on public.trip_activity_comments
  for select using (public.is_trip_member(trip_id));
drop policy if exists "members add activity comments" on public.trip_activity_comments;
create policy "members add activity comments" on public.trip_activity_comments
  for insert with check (author_id = auth.uid() and public.is_trip_member(trip_id));
drop policy if exists "members read activity events" on public.trip_activity_events;
create policy "members read activity events" on public.trip_activity_events
  for select using (public.is_trip_member(trip_id));
drop policy if exists "members add activity events" on public.trip_activity_events;
create policy "members add activity events" on public.trip_activity_events
  for insert with check (actor_id = auth.uid() and public.is_trip_member(trip_id));

-- Admins, as well as the creator, can mute and remove members.
drop policy if exists "creator can manage membership" on public.trip_members;
drop policy if exists "admins can manage membership" on public.trip_members;
create policy "admins can manage membership" on public.trip_members
  for all using (public.is_trip_admin(trip_id)) with check (public.is_trip_admin(trip_id));

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'trip_activity_comments',
    'trip_activity_events',
    'trip_member_roles'
  ] loop
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = table_name
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I',
        table_name
      );
    end if;
  end loop;
end;
$$;
