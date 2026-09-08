create table if not exists public.trip_call_participants (
  call_id uuid not null references public.trip_calls(id) on delete cascade,
  trip_id uuid not null references public.matchmaking_trips(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null,
  mic_enabled boolean not null default true,
  camera_enabled boolean not null default false,
  status text not null default 'joined' check (status in ('joined', 'left')),
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  left_at timestamptz,
  primary key (call_id, user_id)
);

alter table public.trip_call_signals
  drop constraint if exists trip_call_signals_signal_type_check;
alter table public.trip_call_signals
  add constraint trip_call_signals_signal_type_check
  check (
    signal_type in (
      'ready', 'offer', 'answer', 'candidate', 'hangup',
      'media_mode', 'renegotiate'
    )
  );

create index if not exists trip_call_participants_active_idx
  on public.trip_call_participants(call_id, status, updated_at desc);

alter table public.trip_call_participants enable row level security;

drop policy if exists "trip members read call participants" on public.trip_call_participants;
create policy "trip members read call participants"
  on public.trip_call_participants for select to authenticated
  using (public.is_trip_member(trip_id));

drop policy if exists "members join calls as themselves" on public.trip_call_participants;
create policy "members join calls as themselves"
  on public.trip_call_participants for insert to authenticated
  with check (user_id = auth.uid() and public.is_trip_member(trip_id));

drop policy if exists "members update their call presence" on public.trip_call_participants;
create policy "members update their call presence"
  on public.trip_call_participants for update to authenticated
  using (user_id = auth.uid() and public.is_trip_member(trip_id))
  with check (user_id = auth.uid() and public.is_trip_member(trip_id));

grant select, insert, update on public.trip_call_participants to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'trip_call_participants'
  ) then
    alter publication supabase_realtime add table public.trip_call_participants;
  end if;
end
$$;

create or replace function public.upsert_trip_call_participant(
  p_call_id uuid,
  p_display_name text,
  p_mic_enabled boolean,
  p_camera_enabled boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_call public.trip_calls%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select * into v_call
  from public.trip_calls
  where id = p_call_id;

  if v_call.id is null or v_call.status = 'ended' or not public.is_trip_member(v_call.trip_id) then
    raise exception 'Call not found, ended, or access denied';
  end if;

  insert into public.trip_call_participants(
    call_id, trip_id, user_id, display_name, mic_enabled,
    camera_enabled, status, joined_at, updated_at, left_at
  ) values (
    p_call_id, v_call.trip_id, auth.uid(), left(trim(p_display_name), 120),
    p_mic_enabled, p_camera_enabled, 'joined', now(), now(), null
  )
  on conflict (call_id, user_id) do update
  set display_name = excluded.display_name,
      mic_enabled = excluded.mic_enabled,
      camera_enabled = excluded.camera_enabled,
      status = 'joined',
      joined_at = now(),
      updated_at = now(),
      left_at = null;
end;
$$;

create or replace function public.update_trip_call_participant_media(
  p_call_id uuid,
  p_mic_enabled boolean,
  p_camera_enabled boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.trip_call_participants
  set mic_enabled = p_mic_enabled,
      camera_enabled = p_camera_enabled,
      updated_at = now()
  where call_id = p_call_id
    and user_id = auth.uid()
    and status = 'joined';

  if not found then
    raise exception 'Active call participant not found';
  end if;
end;
$$;

create or replace function public.leave_trip_call(p_call_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_remaining integer;
  v_trip_id uuid;
begin
  select trip_id into v_trip_id
  from public.trip_calls
  where id = p_call_id;

  if v_trip_id is null or not public.is_trip_member(v_trip_id) then
    raise exception 'Call not found or access denied';
  end if;

  update public.trip_call_participants
  set status = 'left', left_at = now(), updated_at = now()
  where call_id = p_call_id and user_id = auth.uid();

  select count(*)::integer into v_remaining
  from public.trip_call_participants
  where call_id = p_call_id
    and status = 'joined'
    and updated_at > now() - interval '45 seconds';

  return v_remaining;
end;
$$;

create or replace function public.close_ended_trip_call_participants()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'ended' and old.status is distinct from new.status then
    update public.trip_call_participants
    set status = 'left', left_at = coalesce(left_at, now()), updated_at = now()
    where call_id = new.id and status = 'joined';
  end if;
  return new;
end;
$$;

drop trigger if exists close_ended_trip_call_participants on public.trip_calls;
create trigger close_ended_trip_call_participants
after update of status on public.trip_calls
for each row execute function public.close_ended_trip_call_participants();

revoke all on function public.upsert_trip_call_participant(uuid, text, boolean, boolean) from public;
revoke all on function public.update_trip_call_participant_media(uuid, boolean, boolean) from public;
revoke all on function public.leave_trip_call(uuid) from public;
grant execute on function public.upsert_trip_call_participant(uuid, text, boolean, boolean) to authenticated;
grant execute on function public.update_trip_call_participant_media(uuid, boolean, boolean) to authenticated;
grant execute on function public.leave_trip_call(uuid) to authenticated;
