-- Accepting the final available traveller closes the request queue atomically.
-- Remaining applicants are notified before their pending or held requests are
-- removed, so they do not retain a stale request for a full trip.

create or replace function public.decide_matchmaking_join_request(
  p_request_id uuid,
  p_status public.join_request_status
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request public.matchmaking_join_requests%rowtype;
  v_vacancies integer;
  v_member_count integer;
  v_destination text;
begin
  if p_status not in ('accepted', 'held', 'declined') then
    raise exception 'Unsupported request decision';
  end if;

  select * into v_request
  from public.matchmaking_join_requests
  where id = p_request_id
  for update;
  if not found then
    raise exception 'Join request not found';
  end if;

  -- Serialise every decision for this trip through the trip-row lock. This
  -- prevents two concurrent accept operations from exceeding capacity.
  select vacancies, destination
  into v_vacancies, v_destination
  from public.matchmaking_trips
  where id = v_request.trip_id
    and owner_id = auth.uid()
  for update;
  if not found then
    raise exception 'Only the trip owner can decide join requests';
  end if;

  if p_status = 'accepted' then
    select count(*) into v_member_count
    from public.matchmaking_trip_members
    where trip_id = v_request.trip_id
      and role = 'member';

    if v_request.status <> 'accepted' and v_member_count >= v_vacancies then
      raise exception 'This trip has no spots left';
    end if;

    insert into public.matchmaking_trip_members (trip_id, user_id, role)
    values (v_request.trip_id, v_request.applicant_id, 'member')
    on conflict (trip_id, user_id) do nothing;

    select count(*) into v_member_count
    from public.matchmaking_trip_members
    where trip_id = v_request.trip_id
      and role = 'member';

    if v_member_count >= v_vacancies then
      insert into public.matchmaking_notifications (
        user_id,
        trip_id,
        title,
        body
      )
      select
        request.applicant_id,
        request.trip_id,
        'Trip is full',
        'Your request to join ' || v_destination ||
          ' was removed because the trip is now full.'
      from public.matchmaking_join_requests request
      where request.trip_id = v_request.trip_id
        and request.id <> v_request.id
        and request.status in ('pending', 'held');

      delete from public.matchmaking_join_requests request
      where request.trip_id = v_request.trip_id
        and request.id <> v_request.id
        and request.status in ('pending', 'held');
    end if;
  elsif v_request.status = 'accepted' then
    perform set_config('gobuddy.request_decision', '1', true);
    delete from public.matchmaking_trip_members
    where trip_id = v_request.trip_id
      and user_id = v_request.applicant_id
      and role = 'member';
  end if;

  update public.matchmaking_join_requests
  set status = p_status,
      updated_at = now()
  where id = p_request_id;

  if v_request.status <> p_status then
    insert into public.matchmaking_notifications (user_id, trip_id, title, body)
    values (
      v_request.applicant_id,
      v_request.trip_id,
      case p_status
        when 'accepted' then 'Join request accepted'
        when 'declined' then 'Join request declined'
        else 'Join request updated'
      end,
      case p_status
        when 'accepted' then
          'You were added to the collaboration group for ' ||
            v_destination || '.'
        when 'declined' then
          'Your request to join ' || v_destination || ' was declined.'
        else
          'Your request to join ' || v_destination ||
            ' was placed on hold.'
      end
    );
  end if;
end;
$$;

revoke all on function public.decide_matchmaking_join_request(
  uuid,
  public.join_request_status
) from public;

grant execute on function public.decide_matchmaking_join_request(
  uuid,
  public.join_request_status
) to authenticated;

notify pgrst, 'reload schema';
