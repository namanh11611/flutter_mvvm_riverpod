-- Keep incoming and sent matchmaking requests synchronized across clients.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'matchmaking_join_requests'
  ) then
    alter publication supabase_realtime
      add table public.matchmaking_join_requests;
  end if;
end;
$$;
