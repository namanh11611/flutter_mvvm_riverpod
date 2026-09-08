-- GoBuddy collaboration engagement: RSVP, typing, read receipts, and reversible controls.
-- Run after 20260825_collaboration_polish.sql.

alter table public.trip_files
  add column if not exists file_size_bytes bigint;

create table if not exists public.trip_activity_rsvps (
  trip_id uuid not null references public.matchmaking_trips(id) on delete cascade,
  activity_id uuid not null references public.trip_activities(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('going', 'maybe', 'not_going')),
  updated_at timestamptz not null default now(),
  primary key (activity_id, user_id)
);

create table if not exists public.trip_typing_status (
  trip_id uuid not null references public.matchmaking_trips(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  updated_at timestamptz not null default now(),
  primary key (trip_id, user_id)
);

create table if not exists public.trip_message_reads (
  message_id uuid not null references public.trip_messages(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

create index if not exists trip_rsvps_trip_activity_idx
  on public.trip_activity_rsvps(trip_id, activity_id);
create index if not exists trip_typing_recent_idx
  on public.trip_typing_status(trip_id, updated_at desc);
create index if not exists trip_message_reads_message_idx
  on public.trip_message_reads(message_id);

alter table public.trip_activity_rsvps enable row level security;
alter table public.trip_typing_status enable row level security;
alter table public.trip_message_reads enable row level security;

drop policy if exists "members read activity rsvps" on public.trip_activity_rsvps;
create policy "members read activity rsvps" on public.trip_activity_rsvps
  for select using (public.is_trip_member(trip_id));
drop policy if exists "members set own activity rsvp" on public.trip_activity_rsvps;
create policy "members set own activity rsvp" on public.trip_activity_rsvps
  for insert with check (user_id = auth.uid() and public.is_trip_member(trip_id));
drop policy if exists "members update own activity rsvp" on public.trip_activity_rsvps;
create policy "members update own activity rsvp" on public.trip_activity_rsvps
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "members read typing status" on public.trip_typing_status;
create policy "members read typing status" on public.trip_typing_status
  for select using (public.is_trip_member(trip_id));
drop policy if exists "members set own typing status" on public.trip_typing_status;
create policy "members set own typing status" on public.trip_typing_status
  for insert with check (user_id = auth.uid() and public.is_trip_member(trip_id));
drop policy if exists "members update own typing status" on public.trip_typing_status;
create policy "members update own typing status" on public.trip_typing_status
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "members clear own typing status" on public.trip_typing_status;
create policy "members clear own typing status" on public.trip_typing_status
  for delete using (user_id = auth.uid());

drop policy if exists "members read message receipts" on public.trip_message_reads;
create policy "members read message receipts" on public.trip_message_reads
  for select using (
    exists (
      select 1 from public.trip_messages m
      where m.id = message_id and public.is_trip_member(m.trip_id)
    )
  );

create or replace function public.mark_trip_messages_read(p_trip_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_trip_member(p_trip_id) then
    raise exception 'Not permitted to read these messages';
  end if;
  insert into public.trip_message_reads (message_id, user_id, read_at)
  select id, auth.uid(), now()
  from public.trip_messages
  where trip_id = p_trip_id and sender_id <> auth.uid()
  on conflict (message_id, user_id) do update set read_at = excluded.read_at;
end;
$$;

grant select, insert, update, delete on public.trip_activity_rsvps to authenticated;
grant select, insert, update, delete on public.trip_typing_status to authenticated;
grant select on public.trip_message_reads to authenticated;
grant execute on function public.mark_trip_messages_read(uuid) to authenticated;

drop policy if exists "members update calls" on public.trip_calls;
create policy "members update calls" on public.trip_calls
  for update using (
    initiated_by = auth.uid() or public.is_trip_admin(trip_id)
  ) with check (
    initiated_by = auth.uid() or public.is_trip_admin(trip_id)
  );

drop policy if exists "uploaders or admins delete files" on public.trip_files;
create policy "uploaders or admins delete files" on public.trip_files
  for delete using (uploaded_by = auth.uid() or public.is_trip_admin(trip_id));

drop policy if exists "uploaders or admins delete trip documents" on storage.objects;
create policy "uploaders or admins delete trip documents" on storage.objects
  for delete to authenticated using (
    bucket_id = 'trip-documents' and exists (
      select 1 from public.trip_files f
      where f.storage_path = name
        and (f.uploaded_by = auth.uid() or public.is_trip_admin(f.trip_id))
    )
  );

alter table public.trip_activity_events
  drop constraint if exists trip_activity_events_event_type_check;
alter table public.trip_activity_events
  add constraint trip_activity_events_event_type_check check (
    event_type in (
      'activity_created', 'activity_edited', 'activity_pinned', 'vote_cast',
      'comment_added', 'member_muted', 'member_unmuted', 'member_removed',
      'admin_assigned', 'admin_removed', 'file_shared', 'file_deleted',
      'call_started', 'call_joined', 'call_ended', 'rsvp_updated'
    )
  );

do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'trip_activity_rsvps') then
    alter publication supabase_realtime add table public.trip_activity_rsvps;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'trip_typing_status') then
    alter publication supabase_realtime add table public.trip_typing_status;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'trip_message_reads') then
    alter publication supabase_realtime add table public.trip_message_reads;
  end if;
end;
$$;
