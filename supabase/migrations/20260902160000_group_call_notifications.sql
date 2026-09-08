-- Notify every other trip member when a group call starts. The existing
-- matchmaking_notifications webhook forwards these rows to registered FCM
-- devices, including when the Flutter application is backgrounded.

alter table public.matchmaking_notifications
  add column if not exists metadata jsonb not null default '{}'::jsonb;

create or replace function public.notify_trip_group_call()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trip_title text;
  v_caller_name text;
begin
  if new.status <> 'ringing' then
    return new;
  end if;

  select destination into v_trip_title
  from public.matchmaking_trips
  where id = new.trip_id;

  select coalesce(nullif(trim(display_name), ''), 'A trip member')
    into v_caller_name
  from public.user_accounts
  where id = new.initiated_by;

  insert into public.matchmaking_notifications (
    user_id,
    trip_id,
    title,
    body,
    metadata
  )
  select
    recipient.user_id,
    new.trip_id,
    'Incoming group ' || new.call_type || ' call',
    coalesce(v_caller_name, 'A trip member') || ' is calling ' ||
      coalesce(v_trip_title, 'your trip group') || '.',
    jsonb_build_object(
      'type', 'incoming_call',
      'call_id', new.id,
      'call_type', new.call_type,
      'caller_id', new.initiated_by
    )
  from (
    select owner_id as user_id
    from public.matchmaking_trips
    where id = new.trip_id
    union
    select user_id
    from public.matchmaking_trip_members
    where trip_id = new.trip_id
  ) recipient
  where recipient.user_id <> new.initiated_by;

  return new;
end;
$$;

drop trigger if exists on_trip_group_call_started on public.trip_calls;
create trigger on_trip_group_call_started
after insert on public.trip_calls
for each row execute function public.notify_trip_group_call();
