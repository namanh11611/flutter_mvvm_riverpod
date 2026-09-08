-- Travel-style edits affect discover cards and filters, so clients must be
-- notified when the style rows are replaced by save_matchmaking_trip.
do $$
begin
  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'matchmaking_trip_styles'
  ) then
    alter publication supabase_realtime
      add table public.matchmaking_trip_styles;
  end if;
end $$;
