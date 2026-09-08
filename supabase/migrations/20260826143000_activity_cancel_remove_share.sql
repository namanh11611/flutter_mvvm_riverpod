drop policy if exists "admins delete activities" on public.trip_activities;
drop policy if exists "members delete unlocked activities" on public.trip_activities;
create policy "members delete unlocked activities" on public.trip_activities
  for delete using (
    public.is_trip_member(trip_id)
    and (not is_locked or public.is_trip_creator(trip_id))
  );

grant delete on public.trip_activities to authenticated;

alter table public.trip_activity_events
  drop constraint if exists trip_activity_events_event_type_check;
alter table public.trip_activity_events
  add constraint trip_activity_events_event_type_check check (
    event_type in (
      'activity_created', 'activity_edited', 'activity_pinned',
      'activity_removed', 'activity_shared',
      'vote_cast', 'comment_added', 'member_muted', 'member_unmuted',
      'member_removed', 'admin_assigned', 'admin_removed', 'file_shared',
      'file_deleted', 'call_started', 'call_joined', 'call_ended',
      'rsvp_updated'
    )
  );
