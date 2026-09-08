-- Keep joined-trip and Messages lists synchronized when membership changes.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'matchmaking_trip_members'
  ) then
    alter publication supabase_realtime
      add table public.matchmaking_trip_members;
  end if;
end;
$$;
