-- Keep each user's matchmaking notification list and unread badge live.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'matchmaking_notifications'
  ) then
    alter publication supabase_realtime
      add table public.matchmaking_notifications;
  end if;
end;
$$;
