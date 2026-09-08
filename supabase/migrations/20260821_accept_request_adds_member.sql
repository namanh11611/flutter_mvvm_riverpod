-- Atomically decide a join request. Accepting it grants access to the trip's
-- collaboration group by creating the corresponding trip membership.
create table if not exists public.matchmaking_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  trip_id uuid references public.matchmaking_trips(id) on delete cascade,
  title text not null,
  body text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists matchmaking_notifications_user_created_idx
  on public.matchmaking_notifications(user_id, created_at desc);

alter table public.matchmaking_notifications enable row level security;
drop policy if exists "users read their notifications"
  on public.matchmaking_notifications;
create policy "users read their notifications"
  on public.matchmaking_notifications for select to authenticated
  using (user_id = auth.uid());
drop policy if exists "users mark their notifications read"
  on public.matchmaking_notifications;
create policy "users mark their notifications read"
  on public.matchmaking_notifications for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
grant select, update (read_at) on public.matchmaking_notifications
  to authenticated;

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
  where id = p_request_id
  for update;

  if not found then
    raise exception 'Join request not found';
  end if;

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
    where trip_id = v_request.trip_id;

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
    insert into public.matchmaking_notifications (
      user_id, trip_id, title, body
    )
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

revoke all on function public.decide_matchmaking_join_request(
  uuid, public.join_request_status
) from public;
grant execute on function public.decide_matchmaking_join_request(
  uuid, public.join_request_status
) to authenticated;

-- Create a request only when the trip can still accept this applicant.
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
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if char_length(trim(p_message)) not between 1 and 500 then
    raise exception 'Request message must be between 1 and 500 characters';
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
  )
  select
    v_trip.owner_id,
    p_trip_id,
    'New join request',
    coalesce(p.display_name, 'A traveller') ||
      ' requested to join ' || v_trip.destination || '.'
  from (select 1) seed
  left join public.matchmaking_profiles p on p.id = auth.uid();

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

-- A direct owner removal also informs the removed member. Trip deletion does
-- not create notifications because the referenced trip no longer exists.
create or replace function public.notify_removed_trip_member()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_destination text;
begin
  if current_setting('gobuddy.request_decision', true) = '1' then
    return old;
  end if;
  if old.role <> 'member' then
    return old;
  end if;
  select destination into v_destination
  from public.matchmaking_trips
  where id = old.trip_id;
  if v_destination is not null then
    insert into public.matchmaking_notifications (
      user_id, trip_id, title, body
    ) values (
      old.user_id,
      old.trip_id,
      'Removed from collaboration group',
      'You were removed from the collaboration group for ' ||
        v_destination || '.'
    );
  end if;
  return old;
end;
$$;

drop trigger if exists on_matchmaking_member_removed
  on public.matchmaking_trip_members;
create trigger on_matchmaking_member_removed
  after delete on public.matchmaking_trip_members
  for each row execute function public.notify_removed_trip_member();

-- Each user may register multiple mobile devices. Registration is exposed only
-- through RPCs so a token can be safely reassigned after account switching.
create table if not exists public.push_device_tokens (
  token text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('android', 'ios')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists push_device_tokens_user_idx
  on public.push_device_tokens(user_id);
alter table public.push_device_tokens enable row level security;

create or replace function public.register_push_device(
  p_token text,
  p_platform text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_platform not in ('android', 'ios') then
    raise exception 'Unsupported push platform';
  end if;
  if char_length(p_token) < 20 then raise exception 'Invalid push token'; end if;

  insert into public.push_device_tokens (token, user_id, platform)
  values (p_token, auth.uid(), p_platform)
  on conflict (token) do update set
    user_id = excluded.user_id,
    platform = excluded.platform,
    updated_at = now();
end;
$$;

create or replace function public.unregister_push_device(p_token text)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.push_device_tokens
  where token = p_token and user_id = auth.uid();
$$;

revoke all on function public.register_push_device(text, text) from public;
revoke all on function public.unregister_push_device(text) from public;
grant execute on function public.register_push_device(text, text)
  to authenticated;
grant execute on function public.unregister_push_device(text)
  to authenticated;
