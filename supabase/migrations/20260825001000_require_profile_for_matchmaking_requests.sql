-- A public account profile is required before a user can request to join a
-- trip. This also updates the renamed profile-table reference used when the
-- owner notification is created.

create or replace function public.send_matchmaking_join_request(
  p_trip_id uuid,
  p_message text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request_id uuid;
  v_trip public.matchmaking_trips%rowtype;
  v_member_count integer;
  v_display_name text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if char_length(trim(p_message)) not between 1 and 500 then
    raise exception 'Request message must be between 1 and 500 characters';
  end if;

  select display_name into v_display_name
  from public.user_accounts
  where id = auth.uid();
  if not found then
    raise exception 'Complete your profile before requesting to join a trip';
  end if;

  select * into v_trip
  from public.matchmaking_trips
  where id = p_trip_id
  for update;

  if not found or v_trip.status <> 'active' then
    raise exception 'This trip is not accepting requests';
  end if;
  if v_trip.owner_id = auth.uid() then
    raise exception 'You cannot request to join your own trip';
  end if;
  if exists (
    select 1 from public.matchmaking_trip_members
    where trip_id = p_trip_id and user_id = auth.uid()
  ) then
    raise exception 'You are already a member of this trip';
  end if;

  select count(*) into v_member_count
  from public.matchmaking_trip_members
  where trip_id = p_trip_id;
  if v_member_count >= v_trip.vacancies then
    raise exception 'This trip has no spots left';
  end if;

  insert into public.matchmaking_join_requests (trip_id, applicant_id, message)
  values (p_trip_id, auth.uid(), trim(p_message))
  returning id into v_request_id;

  insert into public.matchmaking_notifications (
    user_id, trip_id, title, body
  ) values (
    v_trip.owner_id,
    p_trip_id,
    'New join request',
    v_display_name || ' requested to join ' || v_trip.destination || '.'
  );

  return v_request_id;
exception
  when unique_violation then
    raise exception 'You have already requested to join this trip';
end;
$$;

revoke all on function public.send_matchmaking_join_request(uuid, text)
  from public;
grant execute on function public.send_matchmaking_join_request(uuid, text)
  to authenticated;

notify pgrst, 'reload schema';
