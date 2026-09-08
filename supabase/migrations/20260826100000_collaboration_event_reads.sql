-- Persistent, per-user read state for collaboration activity notifications.

create table if not exists public.trip_activity_event_reads (
  trip_id uuid not null
    references public.matchmaking_trips(id) on delete cascade,
  event_id uuid not null
    references public.trip_activity_events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

create index if not exists trip_activity_event_reads_user_trip_idx
  on public.trip_activity_event_reads(user_id, trip_id);

alter table public.trip_activity_event_reads enable row level security;

drop policy if exists "users read their collaboration event receipts"
  on public.trip_activity_event_reads;
create policy "users read their collaboration event receipts"
  on public.trip_activity_event_reads for select to authenticated
  using (user_id = auth.uid());

revoke all on public.trip_activity_event_reads from public, authenticated;
grant select on public.trip_activity_event_reads to authenticated;

create or replace function public.mark_trip_activity_events_read(
  p_trip_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if not public.is_trip_member(p_trip_id) then
    raise exception 'Only trip members can mark collaboration events read';
  end if;

  insert into public.trip_activity_event_reads (
    trip_id, event_id, user_id, read_at
  )
  select p_trip_id, event.id, auth.uid(), now()
  from public.trip_activity_events event
  where event.trip_id = p_trip_id
  on conflict (event_id, user_id) do update
  set read_at = excluded.read_at;
end;
$$;

revoke all on function public.mark_trip_activity_events_read(uuid)
  from public;
grant execute on function public.mark_trip_activity_events_read(uuid)
  to authenticated;

notify pgrst, 'reload schema';
