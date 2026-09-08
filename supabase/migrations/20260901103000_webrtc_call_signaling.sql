create table if not exists public.trip_call_signals (
  id uuid primary key default gen_random_uuid(),
  call_id uuid not null references public.trip_calls(id) on delete cascade,
  trip_id uuid not null references public.matchmaking_trips(id) on delete cascade,
  sender_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  target_id uuid references auth.users(id) on delete cascade,
  signal_type text not null check (
    signal_type in ('ready', 'offer', 'answer', 'candidate', 'hangup')
  ),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists trip_call_signals_call_created_idx
  on public.trip_call_signals(call_id, created_at);

alter table public.trip_call_signals enable row level security;

drop policy if exists "trip members read call signals" on public.trip_call_signals;
create policy "trip members read call signals"
  on public.trip_call_signals for select to authenticated
  using (
    public.is_trip_member(trip_id)
    and (target_id is null or target_id = auth.uid() or sender_id = auth.uid())
  );

drop policy if exists "trip members send call signals" on public.trip_call_signals;
create policy "trip members send call signals"
  on public.trip_call_signals for insert to authenticated
  with check (
    sender_id = auth.uid()
    and public.is_trip_member(trip_id)
    and exists (
      select 1 from public.trip_calls call
      where call.id = call_id
        and call.trip_id = trip_id
        and call.status <> 'ended'
    )
  );

grant select, insert on public.trip_call_signals to authenticated;

alter publication supabase_realtime add table public.trip_call_signals;

create or replace function public.clear_ended_trip_call_signals()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'ended' and old.status is distinct from new.status then
    delete from public.trip_call_signals where call_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists clear_ended_trip_call_signals on public.trip_calls;
create trigger clear_ended_trip_call_signals
after update of status on public.trip_calls
for each row execute function public.clear_ended_trip_call_signals();
