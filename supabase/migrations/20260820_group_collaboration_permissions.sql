-- Allow authenticated users to reach collaboration tables. Row-level security
-- policies below continue to decide which trip rows each user may access.
grant select, insert on public.trip_messages to authenticated;
grant select, insert, update on public.trip_activities to authenticated;
grant select, insert on public.trip_polls to authenticated;
grant select, insert on public.trip_poll_options to authenticated;
grant select on public.trip_poll_votes to authenticated;
grant select, insert on public.trip_files to authenticated;
grant select, insert on public.trip_calls to authenticated;
-- Poll creation needs insert policies in addition to the existing read rules.
drop policy if exists "members create polls" on public.trip_polls;
create policy "members create polls"
on public.trip_polls for insert to authenticated
with check (public.is_trip_member(trip_id));
drop policy if exists "members create poll options" on public.trip_poll_options;
create policy "members create poll options"
on public.trip_poll_options for insert to authenticated
with check (
  exists (
    select 1
    from public.trip_polls p
    where p.id = poll_id
      and public.is_trip_member(p.trip_id)
  )
);
grant execute on function public.cast_trip_poll_vote(uuid, uuid) to authenticated;
