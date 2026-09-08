-- Keep removal, discovery eligibility, collaboration access, and user
-- notification consistent in one server-side operation.

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

create or replace function public.remove_matchmaking_trip_member(
  p_trip_id uuid,
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_destination text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if not public.is_trip_admin(p_trip_id) then
    raise exception 'Only the trip creator or an admin can remove members';
  end if;
  if exists (
    select 1 from public.matchmaking_trips
    where id = p_trip_id and owner_id = p_user_id
  ) then
    raise exception 'The trip creator cannot be removed';
  end if;

  select destination into v_destination
  from public.matchmaking_trips
  where id = p_trip_id;

  -- A removed traveller may discover and request this trip again.
  update public.matchmaking_join_requests
  set status = 'declined', updated_at = now()
  where trip_id = p_trip_id
    and applicant_id = p_user_id
    and status = 'accepted';

  -- Suppress the legacy delete trigger's notification and create the same
  -- notification explicitly so this RPC remains self-contained.
  perform set_config('gobuddy.request_decision', '1', true);
  delete from public.matchmaking_trip_members
  where trip_id = p_trip_id and user_id = p_user_id;
  if not found then
    raise exception 'Trip member not found';
  end if;

  -- This is normally performed by the membership synchronization trigger;
  -- retaining it here makes the operation safe on partially migrated projects.
  delete from public.trip_members
  where trip_id = p_trip_id and user_id = p_user_id;
  delete from public.trip_member_roles
  where trip_id = p_trip_id and user_id = p_user_id;

  insert into public.matchmaking_notifications (
    user_id, trip_id, title, body
  ) values (
    p_user_id,
    p_trip_id,
    'Removed from collaboration group',
    'You were removed from the collaboration group for ' ||
      coalesce(v_destination, 'this trip') || '.'
  );
end;
$$;

revoke all on function public.remove_matchmaking_trip_member(uuid, uuid)
  from public;
grant execute on function public.remove_matchmaking_trip_member(uuid, uuid)
  to authenticated;

notify pgrst, 'reload schema';
