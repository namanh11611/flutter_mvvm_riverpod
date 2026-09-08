alter table public.trip_calls
  add column if not exists connected_at timestamptz,
  add column if not exists ended_at timestamptz,
  add column if not exists end_reason text,
  add column if not exists duration_seconds integer,
  add column if not exists had_video boolean not null default false,
  add column if not exists history_message_id uuid references public.trip_messages(id) on delete set null;

alter table public.trip_call_signals
  drop constraint if exists trip_call_signals_signal_type_check;
alter table public.trip_call_signals
  add constraint trip_call_signals_signal_type_check
  check (signal_type in ('ready', 'offer', 'answer', 'candidate', 'hangup', 'media_mode'));

update public.trip_calls
set had_video = true
where call_type = 'video' and not had_video;

alter table public.trip_calls
  drop constraint if exists trip_calls_end_reason_check;
alter table public.trip_calls
  add constraint trip_calls_end_reason_check
  check (end_reason is null or end_reason in ('completed', 'cancelled', 'missed'));

alter table public.trip_calls
  drop constraint if exists trip_calls_duration_seconds_check;
alter table public.trip_calls
  add constraint trip_calls_duration_seconds_check
  check (duration_seconds is null or duration_seconds >= 0);

create or replace function public.join_trip_call(p_call_id uuid)
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
  where id = p_call_id
  for update;

  if v_call.id is null or not public.is_trip_member(v_call.trip_id) then
    raise exception 'Call not found or access denied';
  end if;
  if v_call.status = 'ended' then
    raise exception 'This call has already ended';
  end if;

  update public.trip_calls
  set status = 'active', connected_at = coalesce(connected_at, now())
  where id = p_call_id;
end;
$$;

create or replace function public.mark_trip_call_video_used(p_call_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trip_id uuid;
begin
  select trip_id into v_trip_id
  from public.trip_calls
  where id = p_call_id and status <> 'ended';

  if v_trip_id is null or not public.is_trip_member(v_trip_id) then
    raise exception 'Call not found or access denied';
  end if;

  update public.trip_calls
  set had_video = true, call_type = 'video'
  where id = p_call_id and status <> 'ended';
end;
$$;

create or replace function public.finish_trip_call(
  p_call_id uuid,
  p_reason text default null,
  p_had_video boolean default false,
  p_duration_seconds integer default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_call public.trip_calls%rowtype;
  v_reason text;
  v_duration integer;
  v_had_video boolean;
  v_message_id uuid;
  v_body text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select * into v_call
  from public.trip_calls
  where id = p_call_id
  for update;

  if v_call.id is null or not public.is_trip_member(v_call.trip_id) then
    raise exception 'Call not found or access denied';
  end if;
  if v_call.status = 'ended' then
    return false;
  end if;

  v_had_video := v_call.had_video or p_had_video or v_call.call_type = 'video';
  if v_call.status = 'active' or coalesce(p_duration_seconds, 0) > 0 then
    v_reason := 'completed';
    v_duration := greatest(
      0,
      coalesce(
        p_duration_seconds,
        extract(epoch from (now() - coalesce(v_call.connected_at, v_call.created_at)))::integer
      )
    );
  elsif p_reason in ('missed', 'unanswered') then
    v_reason := 'missed';
    v_duration := 0;
  else
    v_reason := 'cancelled';
    v_duration := 0;
  end if;

  v_body := '[call_history]|' || v_reason || '|' ||
    case when v_had_video then 'video' else 'voice' end || '|' || v_duration::text;

  insert into public.trip_messages(trip_id, sender_id, body)
  values (v_call.trip_id, v_call.initiated_by, v_body)
  returning id into v_message_id;

  update public.trip_calls
  set status = 'ended',
      call_type = case when v_had_video then 'video' else 'voice' end,
      had_video = v_had_video,
      ended_at = now(),
      end_reason = v_reason,
      duration_seconds = v_duration,
      history_message_id = v_message_id
  where id = p_call_id;

  return true;
end;
$$;

revoke all on function public.join_trip_call(uuid) from public;
revoke all on function public.mark_trip_call_video_used(uuid) from public;
revoke all on function public.finish_trip_call(uuid, text, boolean, integer) from public;
grant execute on function public.join_trip_call(uuid) to authenticated;
grant execute on function public.mark_trip_call_video_used(uuid) to authenticated;
grant execute on function public.finish_trip_call(uuid, text, boolean, integer) to authenticated;
