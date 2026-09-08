-- Follow-up migration: the initial removal migration may already have run.
-- Members may remove unlocked activities; only the creator may remove locked
-- activities. RLS still verifies that the caller belongs to the trip.
drop policy if exists "admins delete activities" on public.trip_activities;
drop policy if exists "members delete unlocked activities" on public.trip_activities;

create policy "members delete unlocked activities" on public.trip_activities
  for delete to authenticated using (
    public.is_trip_member(trip_id)
    and (not is_locked or public.is_trip_creator(trip_id))
  );

grant delete on public.trip_activities to authenticated;

