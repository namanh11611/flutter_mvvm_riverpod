create table if not exists public.trip_timeline_days (
  trip_id uuid not null references public.matchmaking_trips(id) on delete cascade,
  day_date date not null,
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  primary key (trip_id, day_date)
);

alter table public.trip_timeline_days enable row level security;

create policy "members read timeline days" on public.trip_timeline_days
  for select using (public.is_trip_member(trip_id));
create policy "members add timeline days" on public.trip_timeline_days
  for insert with check (
    created_by = auth.uid() and public.is_trip_member(trip_id)
  );

grant select, insert on public.trip_timeline_days to authenticated;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'trip_timeline_days',
    'matchmaking_trip_members',
    'trip_member_roles',
    'trip_poll_options'
  ] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = table_name
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I',
        table_name
      );
    end if;
  end loop;
end
$$;
