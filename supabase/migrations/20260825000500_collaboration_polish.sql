-- GoBuddy collaboration polish: call history and complete activity history.
-- Run after 20260825_collaboration_enhancements.sql.

alter table public.trip_activity_events
  drop constraint if exists trip_activity_events_event_type_check;

alter table public.trip_activity_events
  add constraint trip_activity_events_event_type_check check (
    event_type in (
      'activity_created',
      'activity_edited',
      'activity_pinned',
      'vote_cast',
      'comment_added',
      'member_muted',
      'member_unmuted',
      'member_removed',
      'admin_assigned',
      'admin_removed',
      'file_shared',
      'file_deleted',
      'call_started',
      'call_joined',
      'call_ended',
      'rsvp_updated'
    )
  );

create index if not exists trip_calls_trip_created_idx
  on public.trip_calls(trip_id, created_at desc);

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'trip_calls'
  ) then
    alter publication supabase_realtime add table public.trip_calls;
  end if;
end;
$$;
