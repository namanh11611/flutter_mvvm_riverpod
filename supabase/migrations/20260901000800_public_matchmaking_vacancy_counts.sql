-- Store a public, RLS-safe count of accepted travel companions. The owner is
-- a group member but does not consume one of the advertised vacancies.

alter table public.matchmaking_trips
  add column if not exists joined_count integer not null default 0
  check (joined_count >= 0);

create or replace function public.sync_matchmaking_trip_joined_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trip_id uuid := coalesce(new.trip_id, old.trip_id);
begin
  update public.matchmaking_trips
  set joined_count = (
    select count(*)::integer
    from public.matchmaking_trip_members member
    where member.trip_id = v_trip_id
      and member.role = 'member'
  ),
  updated_at = now()
  where id = v_trip_id;
  return coalesce(new, old);
end;
$$;

drop trigger if exists sync_matchmaking_joined_count
  on public.matchmaking_trip_members;
create trigger sync_matchmaking_joined_count
after insert or delete or update of role
on public.matchmaking_trip_members
for each row execute function public.sync_matchmaking_trip_joined_count();

update public.matchmaking_trips trip
set joined_count = (
  select count(*)::integer
  from public.matchmaking_trip_members member
  where member.trip_id = trip.id
    and member.role = 'member'
);

-- Capacity checks use companions only; the owner membership does not consume
-- an advertised vacancy.
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
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if char_length(trim(p_message)) not between 1 and 500 then
    raise exception 'Request message must be between 1 and 500 characters';
  end if;

  select display_name into v_display_name
  from public.user_accounts where id = auth.uid();
  if not found then
    raise exception 'Complete your profile before requesting to join a trip';
  end if;

  select * into v_trip
  from public.matchmaking_trips where id = p_trip_id for update;
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
  where trip_id = p_trip_id and role = 'member';
  if v_member_count >= v_trip.vacancies then
    raise exception 'This trip has no spots left';
  end if;

  insert into public.matchmaking_join_requests (trip_id, applicant_id, message)
  values (p_trip_id, auth.uid(), trim(p_message))
  returning id into v_request_id;

  insert into public.matchmaking_notifications (user_id, trip_id, title, body)
  values (
    v_trip.owner_id, p_trip_id, 'New join request',
    v_display_name || ' requested to join ' || v_trip.destination || '.'
  );
  return v_request_id;
exception
  when unique_violation then
    raise exception 'You have already requested to join this trip';
end;
$$;

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
begin
  if p_status not in ('accepted', 'held', 'declined') then
    raise exception 'Unsupported request decision';
  end if;

  select * into v_request
  from public.matchmaking_join_requests
  where id = p_request_id for update;
  if not found then raise exception 'Join request not found'; end if;

  select vacancies into v_vacancies
  from public.matchmaking_trips
  where id = v_request.trip_id and owner_id = auth.uid()
  for update;
  if not found then
    raise exception 'Only the trip owner can decide join requests';
  end if;

  if p_status = 'accepted' then
    select count(*) into v_member_count
    from public.matchmaking_trip_members
    where trip_id = v_request.trip_id and role = 'member';
    if v_request.status <> 'accepted' and v_member_count >= v_vacancies then
      raise exception 'This trip has no spots left';
    end if;
    insert into public.matchmaking_trip_members (trip_id, user_id, role)
    values (v_request.trip_id, v_request.applicant_id, 'member')
    on conflict (trip_id, user_id) do nothing;
  elsif v_request.status = 'accepted' then
    perform set_config('gobuddy.request_decision', '1', true);
    delete from public.matchmaking_trip_members
    where trip_id = v_request.trip_id
      and user_id = v_request.applicant_id
      and role = 'member';
  end if;

  update public.matchmaking_join_requests
  set status = p_status, updated_at = now()
  where id = p_request_id;

  if v_request.status <> p_status then
    insert into public.matchmaking_notifications (user_id, trip_id, title, body)
    select
      v_request.applicant_id,
      v_request.trip_id,
      case p_status
        when 'accepted' then 'Join request accepted'
        when 'declined' then 'Join request declined'
        else 'Join request updated'
      end,
      case p_status
        when 'accepted' then
          'You were added to the collaboration group for ' || t.destination || '.'
        when 'declined' then
          'Your request to join ' || t.destination || ' was declined.'
        else
          'Your request to join ' || t.destination || ' was placed on hold.'
      end
    from public.matchmaking_trips t
    where t.id = v_request.trip_id;
  end if;
end;
$$;

revoke all on function public.send_matchmaking_join_request(uuid, text)
  from public;
grant execute on function public.send_matchmaking_join_request(uuid, text)
  to authenticated;
revoke all on function public.decide_matchmaking_join_request(
  uuid, public.join_request_status
) from public;
grant execute on function public.decide_matchmaking_join_request(
  uuid, public.join_request_status
) to authenticated;

notify pgrst, 'reload schema';
