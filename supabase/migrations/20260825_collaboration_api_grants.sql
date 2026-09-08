-- Data API privileges for Flutter. Row Level Security policies still control
-- which rows each signed-in user can read or change.

grant select, insert, update, delete on public.trip_members to authenticated;
grant select, insert on public.trip_messages to authenticated;
grant select, insert, update on public.trip_activities to authenticated;
grant select, insert on public.trip_polls to authenticated;
grant select, insert on public.trip_poll_options to authenticated;
grant select on public.trip_poll_votes to authenticated;
grant select, insert on public.trip_files to authenticated;
grant select, insert, update on public.trip_calls to authenticated;
grant select, insert, update, delete on public.trip_member_roles to authenticated;
grant select, insert on public.trip_activity_comments to authenticated;
grant select, insert on public.trip_activity_events to authenticated;

-- These inserts are used by the Create Poll action in the Flutter workspace.
drop policy if exists "members add polls" on public.trip_polls;
create policy "members add polls" on public.trip_polls
  for insert with check (public.is_trip_member(trip_id));

drop policy if exists "members add poll options" on public.trip_poll_options;
create policy "members add poll options" on public.trip_poll_options
  for insert with check (
    exists (
      select 1 from public.trip_polls p
      where p.id = poll_id and public.is_trip_member(p.trip_id)
    )
  );
