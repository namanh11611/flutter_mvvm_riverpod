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
  if p_reason in ('missed', 'unanswered') and coalesce(p_duration_seconds, 0) = 0 then
    v_reason := 'missed';
    v_duration := 0;
  elsif p_reason = 'cancelled' and coalesce(p_duration_seconds, 0) = 0 then
    v_reason := 'cancelled';
    v_duration := 0;
  else
    v_reason := 'completed';
    v_duration := greatest(
      0,
      coalesce(
        p_duration_seconds,
        extract(epoch from (now() - coalesce(v_call.connected_at, v_call.created_at)))::integer
      )
    );
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

revoke all on function public.finish_trip_call(uuid, text, boolean, integer) from public;
grant execute on function public.finish_trip_call(uuid, text, boolean, integer) to authenticated;
