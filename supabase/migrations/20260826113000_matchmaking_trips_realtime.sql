-- Refresh Discovery and My Trips when trips are created, edited, finished,
-- or deleted by another authenticated user.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'matchmaking_trips'
  ) then
    alter publication supabase_realtime
      add table public.matchmaking_trips;
  end if;
end;
$$;
